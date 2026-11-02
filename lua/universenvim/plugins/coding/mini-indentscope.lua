local Constants = require("universenvim.config.constants")

return {
	{
		"nvim-mini/mini.indentscope",
		version = false,
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			symbol = "│",
			options = { try_as_border = true },
		},
		init = function()
			vim.api.nvim_create_autocmd("FileType", {
				pattern = Constants.indent_filetype_exclude,
				callback = function()
					vim.b.miniindentscope_disable = true
				end,
			})
		end,
	},
}
