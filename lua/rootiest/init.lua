-- ~/.config/nvim/lua/rootiest/init.lua
local M = {}

local precog_first_time = true
local config_path = vim.fn.stdpath("config")

-- Ensure required settings files exist with default values
function M.eval_settings_files()
	local function ensure_file_exists(file_path, default_value, setup_func)
		if vim.fn.filereadable(file_path) ~= 1 then
			if setup_func then
				setup_func()
			else
				vim.fn.writefile({ default_value }, file_path)
			end
		end
	end

	local defaults = {
		[config_path .. "/.aitool"] = "codeium",
		[config_path .. "/.useimage"] = "true",
		[config_path .. "/.wakatime"] = "true",
		[config_path .. "/.hardtime"] = "false",
		[config_path .. "/.ignore-deps"] = "false",
		[config_path .. "/.leader"] = vim.g.mapleader,
	}

	local function setup_colorscheme()
		local color_file = config_path .. "/.colorscheme"
		if M.kitty_theme then
			vim.fn.writefile({ M.kitty_theme }, color_file)
		else
			vim.fn.writefile({ vim.g.colors_name }, color_file)
		end
	end

	for file_path, default_value in pairs(defaults) do
		ensure_file_exists(file_path, default_value)
	end

	ensure_file_exists(config_path .. "/.colorscheme", nil, setup_colorscheme)
	-- Load Stored Leader Key
	M.leader = vim.fn.readfile(config_path .. "/.leader")[1]
end

-- Restore colorscheme
function M.restore_colorscheme()
	vim.cmd.colorscheme(M.colortheme or "catppuccin-frappe" or "tokyonight")
	-- Load the kitty theme
	M.kitty_theme = os.getenv("KITTY_THEME")
	-- Load the stored colorscheme
	M.colortheme = vim.fn.readfile(config_path .. "/.colorscheme")[1]
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

-- Function to check if a given string matches the content of the .aitool file
function M.using_aitool(input)
	local aitool_file = config_path .. "/.aitool"

	-- Ensure the .aitool file exists
	if vim.fn.filereadable(aitool_file) ~= 1 then
		vim.fn.writefile({ "codeium" }, aitool_file)
	end

	-- Read the file and normalize its content
	local content = vim.fn.readfile(aitool_file)[1] or ""
	local normalized_content = content:lower():gsub("%s+", "")

	-- Normalize the input and compare
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
	vim.fn.sign_define("smoothcursor_�", { text = "" })
	vim.fn.sign_define("smoothcursor_R", { text = "󰊄" })
end

-- Evaluate dependencies and print warnings if needed
function M.eval_dependencies()
	local function should_suppress_warnings()
		local ignore_file = config_path .. "/.ignore-deps"
		local file = io.open(ignore_file, "r")
		if file then
			local content = file:read("*a")
			file:close()
			content = content:lower():gsub("%s+", "")
			local suppress_values = { ["true"] = true, ["1"] = true, ["yes"] = true }
			return suppress_values[content] or false
		end
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
end

-- Setup function to initialize the plugin
function M.setup()
	M.eval_settings_files()
	M.eval_dependencies()
	M.eval_neovide()
	M.define_commands()
	M.define_autocorrections()
	M.restore_colorscheme()
	M.set_cursor_icons()
	vim.g.mapleader = M.leader
end

-- Provide a function to be called by lazy.nvim
function M.config()
	M.setup()
end

return M
