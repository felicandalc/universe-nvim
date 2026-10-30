local Utils = require("universenvim.utils.core")

return {
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				tailwindcss = {
					filetypes_exclude = { "markdown" },
					filetypes_include = {},
				},
			},
			setup = {
				tailwindcss = function(_, opts)
					local default_filetypes = vim.lsp.config.tailwindcss and vim.lsp.config.tailwindcss.filetypes
					if not default_filetypes then
						Utils.error("LSPConfig - TailwindCSS could not be loaded!")
						return
					end
					opts.filetypes = opts.filetypes or {}

					vim.list_extend(opts.filetypes, default_filetypes)

					opts.filetypes = vim.tbl_filter(function(ft)
						return not vim.tbl_contains(opts.filetypes_exclude or {}, ft)
					end, opts.filetypes)

					vim.list_extend(opts.filetypes, opts.filetypes_include or {})
				end,
			},
		},
	},
	{
		"hrsh7th/nvim-cmp",
		dependencies = {
			{ "roobert/tailwindcss-colorizer-cmp.nvim", config = true },
		},
		opts = function(_, opts)
			local format_kinds_icons = opts.formatting.format
			opts.formatting.format = function(entry, item)
				format_kinds_icons(entry, item)
				return require("tailwindcss-colorizer-cmp").formatter(entry, item)
			end
		end,
	},
}
