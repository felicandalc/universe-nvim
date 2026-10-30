return {
	{
		"Exafunction/windsurf.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
		},
		event = "BufEnter",
		config = function()
			require("codeium").setup({
				enable_chat = true,
				virtual_text = { enabled = true, map_keys = false },
			})
		end,
		keys = {
			{
				"<C-g>",
				function()
					local vt = require("codeium.virtual_text")
					return vt.get_current_completion_item() and vt.accept() or ""
				end,
				expr = true,
				silent = true,
				mode = "i",
				desc = "Accept Codeium suggestion",
			},
			{
				"<C-;>",
				function()
					require("codeium.virtual_text").cycle_completions(1)
					return ""
				end,
				expr = true,
				silent = true,
				mode = "i",
				desc = "Next Codeium suggestion",
			},
			{
				"<C-,>",
				function()
					require("codeium.virtual_text").cycle_completions(-1)
					return ""
				end,
				expr = true,
				silent = true,
				mode = "i",
				desc = "Previous Codeium suggestion",
			},
			{
				"<C-]>",
				function()
					return require("codeium.virtual_text").clear()
				end,
				expr = true,
				silent = true,
				mode = "i",
				desc = "Clear Codeium suggestion",
			},
		},
	},
}