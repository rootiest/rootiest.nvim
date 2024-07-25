local M = {}

local precog_first_time = true
local data_path = vim.fn.stdpath("data") .. "/lazy/rootiest.nvim"
local settings_file = data_path .. "/settings.json"

-- Ensure the settings file exists with default values
function M.ensure_settings_file()
	if vim.fn.isdirectory(data_path) ~= 1 then
		vim.fn.mkdir(data_path, "p")
	end

	if vim.fn.filereadable(settings_file) ~= 1 then
		local default_settings = {
			aitool = "codeium",
			useimage = true,
			wakatime = true,
			hardtime = false,
			ignore_deps = false,
			colorscheme = vim.g.colors_name or "default",
		}
		local json = vim.fn.json_encode(default_settings)
		vim.fn.writefile({ json }, settings_file)
	end
end

-- Load settings from the settings file
function M.load_settings()
	local json_content = vim.fn.readfile(settings_file)[1]
	if not json_content then
		M.ensure_settings_file()
		json_content = vim.fn.readfile(settings_file)[1]
	end
	M.settings = vim.fn.json_decode(json_content)
end

-- Save settings to the settings file
function M.save_settings()
	local json = vim.fn.json_encode(M.settings)
	vim.fn.writefile({ json }, settings_file)
end

-- Initialize settings
function M.init_settings()
	M.load_settings()
end

-- Restore colorscheme
function M.restore_colorscheme()
	local function is_colorscheme_available(name)
		local ok, _ = pcall(function()
			vim.cmd("colorscheme " .. name)
		end)
		return ok
	end

	local colortheme = M.settings.colorscheme
	local fallback_themes = { "catppuccin-frappe", "tokyonight", "default" }

	if colortheme and is_colorscheme_available(colortheme) then
		vim.cmd.colorscheme(colortheme)
	else
		for _, theme in ipairs(fallback_themes) do
			if is_colorscheme_available(theme) then
				vim.cmd.colorscheme(theme)
				break
			end
		end
	end
	-- Load the kitty theme
	M.kitty_theme = os.getenv("KITTY_THEME")
end

-- Yank line without leading/trailing whitespace
function M.yank_line()
	vim.api.nvim_feedkeys("_v$hy$", "n", true)
end

-- Check if the terminal is Kitty
function M.using_kitty()
	local term = os.getenv("TERM") or ""
	return term:find("kitty") ~= nil
end

-- Toggle the precognition plugin
function M.toggle_precognition()
	if pcall(require, "precognition") then
		local precognition = require("precognition")
		if precog_first_time then
			precognition.toggle()
			precognition.toggle() -- Call toggle twice
			precog_first_time = false
		else
			precognition.toggle() -- Call toggle once
		end
	else
		vim.api.nvim_err_writeln("precognition plugin is not installed")
	end
end

-- Toggle Hardtime and Precognition
function M.toggle_hardmode()
	if pcall(require, "hardtime") then
		local hardtime = require("hardtime")
		hardtime.toggle()
		M.toggle_precognition()
	else
		vim.api.nvim_err_writeln("hardtime plugin is not installed")
	end
end

-- Toggle LazyGit terminal
function M.toggle_lazygit_term()
	if pcall(require, "toggleterm.terminal") then
		local Terminal = require("toggleterm.terminal").Terminal
		local lazygit = Terminal:new({ cmd = "lazygit", hidden = true })
		lazygit:toggle()
	else
		vim.api.nvim_err_writeln("toggleterm plugin is not installed")
	end
end

-- Function to check if a given string matches the content of the aitool setting
function M.using_aitool(input)
	local normalized_content = M.settings.aitool:lower():gsub("%s+", "")
	local normalized_input = input:lower():gsub("%s+", "")
	return normalized_input == normalized_content
end

-- Load remote-nvim plugin
function M.load_remote()
	if pcall(require, "remote-nvim") then
		---@diagnostic disable-next-line: missing-parameter
		require("remote-nvim").setup()
		vim.cmd("RemoteStart")
	else
		vim.api.nvim_err_writeln("remote-nvim plugin is not installed")
	end
end

-- Set cursor icons
function M.set_cursor_icons()
	vim.fn.sign_define("smoothcursor_n", { text = "" })
	vim.fn.sign_define("smoothcursor_v", { text = "" })
	vim.fn.sign_define("smoothcursor_V", { text = "" })
	vim.fn.sign_define("smoothcursor_i", { text = "" })
	vim.fn.sign_define("smoothcursor_c", { text = "" })
	vim.fn.sign_define("smoothcursor_R", { text = "󰊄" })
end

-- Evaluate dependencies and print warnings if needed
function M.eval_dependencies()
	local function should_suppress_warnings()
		return M.settings.ignore_deps
	end

	local function check_executable(executable)
		if vim.fn.executable(executable) ~= 1 then
			vim.api.nvim_notify(executable .. " is not installed!", vim.log.levels.WARN, {})
		end
	end

	if not should_suppress_warnings() then
		local executables = { "lazygit", "gh", "rg", "fzf", "fd", "git", "luarocks" }
		for _, executable in ipairs(executables) do
			check_executable(executable)
		end
	end
end

-- Evaluate Neovide settings
function M.eval_neovide()
	if vim.g.neovide then
		require("rootiest.neovide")
	end
end

-- Define autocorrections
function M.define_autocorrections()
	require("rootiest.autospell")
end

-- Define user commands to change settings
function M.define_setting_commands()
	vim.api.nvim_create_user_command("SetAITool", function(opts)
		local value = opts.args:lower()
		local valid_values = { codeium = true, copilot = true, tabnine = true, minuet = true, none = true }
		if valid_values[value] then
			M.settings.aitool = value
			M.save_settings()
			vim.api.nvim_out_write("AITool set to " .. value .. "\n")
		else
			vim.api.nvim_err_writeln(
				"Invalid value for AITool. Valid options are: codeium, copilot, tabnine, minuet, none"
			)
		end
	end, {
		nargs = 1,
		complete = function(_, _, _)
			return { "codeium", "copilot", "tabnine", "minuet", "none" }
		end,
		desc = "Set AITool option",
	})

	local function create_toggle_command(setting)
		vim.api.nvim_create_user_command("Toggle" .. setting:gsub("^%l", string.upper), function()
			M.settings[setting] = not M.settings[setting]
			M.save_settings()
			vim.api.nvim_out_write(setting .. " set to " .. tostring(M.settings[setting]) .. "\n")
		end, { desc = "Toggle " .. setting })
	end

	local toggle_settings = { "useimage", "wakatime", "hardtime", "ignore_deps" }
	for _, setting in ipairs(toggle_settings) do
		create_toggle_command(setting)
	end
end

-- Define user commands
function M.define_commands()
	vim.api.nvim_create_user_command("Q", function()
		vim.cmd.qall()
	end, { force = true, desc = "Close all buffers" })

	vim.api.nvim_create_user_command("YankLine", function()
		M.yank_line()
	end, { force = true, desc = "Yank line without leading whitespace" })

	vim.api.nvim_create_user_command("RestoreColorscheme", function()
		M.restore_colorscheme()
	end, { desc = "Restore colorscheme" })

	vim.api.nvim_create_user_command("LoadRemote", function()
		M.load_remote()
	end, { force = true, desc = "Load/start Remote" })

	M.define_setting_commands()
end

-- Setup function to initialize the plugin
function M.setup()
	M.ensure_settings_file()
	M.init_settings()
	M.eval_dependencies()
	M.eval_neovide()
	M.define_commands()
	M.define_autocorrections()
	M.restore_colorscheme()
	M.set_cursor_icons()
end

-- Provide a function to be called by lazy.nvim
function M.config()
	M.setup()
end

return M
