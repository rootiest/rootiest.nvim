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
		local json = vim.fn.json_encode({ colorscheme = M.config.colorscheme })
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
	local settings = vim.fn.json_decode(json_content)
	if settings.colorscheme then
		M.config.colorscheme = settings.colorscheme
	end
end

-- Save settings to the settings file
function M.save_settings()
	local json = vim.fn.json_encode({ colorscheme = M.config.colorscheme })
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

	local colortheme = M.config.colorscheme
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
		return false
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
	vim.api.nvim_create_user_command("SetColorscheme", function(opts)
		local value = opts.args
		M.config.colorscheme = value
		M.save_settings()
		vim.api.nvim_out_write("Colorscheme set to " .. value .. "\n")
	end, {
		nargs = 1,
		desc = "Set Colorscheme option",
	})

	vim.api.nvim_create_user_command("RestoreColorscheme", function()
		M.restore_colorscheme()
	end, { desc = "Restore colorscheme" })
end

-- Define user commands
function M.define_commands()
	vim.api.nvim_create_user_command("Q", function()
		vim.cmd.qall()
	end, { force = true, desc = "Close all buffers" })

	vim.api.nvim_create_user_command("YankLine", function()
		M.yank_line()
	end, { force = true, desc = "Yank line without leading whitespace" })

	M.define_setting_commands()
end

function M.define_autocommands()
	-- Autosave Colorscheme
	-- When the colorscheme changes, store the name in .colorscheme
	vim.api.nvim_create_autocmd("ColorScheme", {
		desc = "Store colorscheme name",
		callback = function()
			M.config.colorscheme = vim.g.colors_name
			M.save_settings()
		end,
	})
	-- Define cursor color/icon based on mode
	local autocmd = vim.api.nvim_create_autocmd
	autocmd({ "ModeChanged", "BufEnter" }, {
		callback = function()
			local current_mode = vim.fn.mode()
			if current_mode == "n" then
				vim.api.nvim_set_hl(0, "SmoothCursor", { fg = "#8aa8f3" })
				vim.fn.sign_define("smoothcursor", { text = "" })
			elseif current_mode == "v" then
				vim.api.nvim_set_hl(0, "SmoothCursor", { fg = "#d298eb" })
				vim.fn.sign_define("smoothcursor", { text = "" })
			elseif current_mode == "V" then
				vim.api.nvim_set_hl(0, "SmoothCursor", { fg = "#d298eb" })
				vim.fn.sign_define("smoothcursor", { text = "" })
			elseif current_mode == "�" then
				vim.api.nvim_set_hl(0, "SmoothCursor", { fg = "#bf616a" })
				vim.fn.sign_define("smoothcursor", { text = "" })
			elseif current_mode == "i" then
				vim.api.nvim_set_hl(0, "SmoothCursor", { fg = "#9bd482" })
				vim.fn.sign_define("smoothcursor", { text = "" })
			end
		end,
	})
end

---@class Config
---@field colorscheme string Default colorscheme
local config = {
	colorscheme = "default", -- Default colorscheme
}

---@type Config
M.config = config

-- Setup function to initialize the plugin
---@param args Config?
M.setup = function(args)
	M.config = vim.tbl_deep_extend("force", M.config, args or {})

	M.ensure_settings_file()
	M.init_settings()
	M.eval_dependencies()
	M.eval_neovide()
	M.define_commands()
	M.define_autocommands()
	M.define_autocorrections()
	M.restore_colorscheme()
	M.set_cursor_icons()
end

return M
