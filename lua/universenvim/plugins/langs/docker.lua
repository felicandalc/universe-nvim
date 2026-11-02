return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				vim.list_extend(opts.ensure_installed, { "dockerfile" })
			end
		end,
	},
	{
		"mason.nvim",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			vim.list_extend(opts.ensure_installed, { "hadolint" })
		end,
	},
	{
		"nvimtools/none-ls.nvim",
		optional = true,
		opts = function(_, opts)
			local nls = require("null-ls")
			opts.sources = vim.list_extend(opts.sources or {}, {
				nls.builtins.diagnostics.hadolint,
			})
		end,
	},
	{
		"mfussenegger/nvim-lint",
		optional = true,
		opts = {
			linters_by_ft = {
				dockerfile = { "hadolint" },
			},
		},
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				dockerls = {},
				-- Neovim detects compose files as plain yaml, never the "yaml.docker-compose" lspconfig expects
				docker_compose_language_service = {
					filetypes = { "yaml" },
					root_dir = function(bufnr, on_dir)
						local path = vim.api.nvim_buf_get_name(bufnr)
						local name = vim.fs.basename(path)
						if name:match("^docker%-compose.*%.ya?ml$") or name:match("^compose.*%.ya?ml$") then
							on_dir(vim.fs.dirname(path))
						end
					end,
				},
			},
		},
	},
}
