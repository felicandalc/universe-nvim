local Utils = require("universenvim.utils.core")

return {
	{
		"nvim-mini/mini.pairs",
		event = "VeryLazy",
		opts = {},
		keys = {
			{
				"<leader>up",
				function()
					vim.g.minipairs_disable = not vim.g.minipairs_disable
					if vim.g.minipairs_disable then
						Utils.warn("Disabled auto pairs", { title = "Option" })
					else
						Utils.info("Enabled auto pairs", { title = "Option" })
					end
				end,
				desc = "Toggle auto pairs",
			},
		},
	},
}
