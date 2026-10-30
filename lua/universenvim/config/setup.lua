local M = {}
local init = require("universenvim.utils.setup").init
local Utils = require("universenvim.utils.core")

function M.setup()
	if vim.fn.has("nvim-0.12") == 0 then
		vim.api.nvim_echo({ { "UniverseNvim requires Neovim 0.12 or later", "ErrorMsg" } }, true, {})
		return
	end

	local lazypath = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lazy.nvim")
	if not vim.uv.fs_stat(lazypath) then
		vim.fn.system({
			"git",
			"clone",
			"--filter=blob:none",
			"https://github.com/folke/lazy.nvim.git",
			"--branch=stable",
			lazypath,
		})
	end
	vim.opt.rtp:prepend(lazypath)

	local status_ok, lazy = pcall(require, "lazy")
	if not status_ok then
		Utils.error("Lazy could not be loaded!")
		return
	end

	init()

	lazy.setup({
		{ import = "universenvim.plugins.core" },
		{ import = "universenvim.plugins.additionals" },
		{ import = "universenvim.plugins.coding" },
		{ import = "universenvim.plugins.editor" },
		{ import = "universenvim.plugins.langs" },
		{ import = "universenvim.plugins.ui" },
		{ import = "universenvim.plugins.ai" },
	}, {
		lockfile = vim.fs.joinpath(vim.fn.stdpath("config"), "lazy-lock.json"),
		defaults = {
			lazy = false,
			version = false,
		},
		install = {
			colorscheme = { "tokyonight" },
		},
		rocks = {
			enabled = false,
		},
		performance = {
			rtp = {
				disabled_plugins = {
					"2html_plugin",
					"tohtml",
					"getscript",
					"getscriptPlugin",
					"gzip",
					"logipat",
					"netrw",
					"netrwPlugin",
					"netrwSettings",
					"netrwFileHandlers",
					"matchit",
					"tar",
					"tarPlugin",
					"rrhelper",
					"spellfile_plugin",
					"vimball",
					"vimballPlugin",
					"zip",
					"zipPlugin",
					"tutor",
					"rplugin",
					"syntax",
					"synmenu",
					"optwin",
					"compiler",
					"bugreport",
					"ftplugin",
				},
			},
		},
	})
end

return M
