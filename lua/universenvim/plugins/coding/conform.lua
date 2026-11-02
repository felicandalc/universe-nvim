local Core = require("universenvim.utils.core")
local Format = require("universenvim.utils.formatter").format

local M = {}

function M.setup(_, opts)
	for _, formatter in pairs(opts.formatters or {}) do
		if type(formatter) == "table" then
			if formatter.extra_args then
				formatter.prepend_args = formatter.extra_args
			end
		end
	end

	for _, key in ipairs({ "format_on_save", "format_after_save" }) do
		if opts[key] then
			opts[key] = nil
		end
	end

	local conform_status_ok, conform = pcall(require, "conform")
	if not conform_status_ok then
		Core.error("Conform could not be loaded!")
		return
	end

	conform.setup(opts)
end

return {
	{
		"stevearc/conform.nvim",
		dependencies = { "mason.nvim" },
		lazy = true,
		cmd = "ConformInfo",
		keys = {
			{
				"<leader>cF",
				function()
					require("conform").format({ formatters = { "injected" } })
				end,
				mode = { "n", "v" },
				desc = "Format Injected Langs",
			},
		},
		init = function()
			Core.on_very_lazy(function()
				Format.register({
					name = "conform.nvim",
					priority = 100,
					primary = true,
					format = function(buf)
						local plugin = require("lazy.core.config").plugins["conform.nvim"]
						local Plugin = require("lazy.core.plugin")
						local opts = Plugin.values(plugin, "opts", false)
						require("conform").format(Core.merge(opts.format, { bufnr = buf }))
					end,
					sources = function(buf)
						local ret = require("conform").list_formatters(buf)
						return vim.tbl_map(function(v)
							return v.name
						end, ret)
					end,
				})
			end)
		end,
		opts = function()
			local opts = {
				format = {
					timeout_ms = 3000,
					async = false,
					quiet = false,
				},
				formatters_by_ft = {
					lua = { "stylua" },
					fish = vim.fn.executable("fish_indent") == 1 and { "fish_indent" } or nil,
					sh = { "shfmt" },
				},
				formatters = {
					injected = { options = { ignore_errors = true } },
				},
			}
			return opts
		end,
		config = M.setup,
	},
}
