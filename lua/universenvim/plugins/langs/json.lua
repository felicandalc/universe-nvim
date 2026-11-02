return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				vim.list_extend(opts.ensure_installed, { "json", "json5" })
			end
		end,
	},
	{
		"b0o/SchemaStore.nvim",
		lazy = true,
		version = false,
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				jsonls = {
					before_init = function(_, config)
						config.settings.json.schemas = config.settings.json.schemas or {}
						vim.list_extend(config.settings.json.schemas, require("schemastore").json.schemas())
					end,
					settings = {
						json = {
							format = {
								enable = true,
							},
							validate = { enable = true },
						},
					},
				},
			},
		},
	},
}
