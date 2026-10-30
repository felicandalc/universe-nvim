local Utils = require("universenvim.utils")
local Config = require("universenvim.config")
local Keymaps = Utils.lsp.keymaps

local local_keys = { "keys", "mason", "enabled", "filetypes_exclude", "filetypes_include" }

local function without_local_keys(server_opts)
	local config = vim.deepcopy(server_opts)
	for _, key in ipairs(local_keys) do
		config[key] = nil
	end
	return config
end

-- nvim-lspconfig lists filetypes Neovim never sets (e.g. "typescript.tsx", "yaml.gitlab"); :checkhealth
-- vim.lsp flags every filetype without runtime files, so keep only the ones Neovim knows.
local function drop_unknown_filetypes(server)
	local filetypes = vim.lsp.config[server] and vim.lsp.config[server].filetypes
	if not filetypes then
		return
	end
	local known = vim.fn.getcompletion("", "filetype")
	vim.lsp.config(server, {
		filetypes = vim.tbl_filter(function(ft)
			return vim.list_contains(known, ft)
		end, filetypes),
	})
end

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
			{ "antosha417/nvim-lsp-file-operations", config = true },
		},
		opts = {
			diagnostics = {
				underline = true,
				update_in_insert = true,
				virtual_text = false,
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = Config.icons.diagnostics.Error,
						[vim.diagnostic.severity.WARN] = Config.icons.diagnostics.Warn,
						[vim.diagnostic.severity.HINT] = Config.icons.diagnostics.Hint,
						[vim.diagnostic.severity.INFO] = Config.icons.diagnostics.Info,
					},
				},
				float = {
					focusable = false,
					style = "minimal",
					border = "rounded",
					source = true,
					header = "",
					prefix = "",
				},
			},
			inlay_hints = {
				enabled = false,
			},
			capabilities = {},
			format = {
				formatting_options = nil,
				timeout_ms = 10000,
			},
			servers = {
				lua_ls = {
					settings = {
						Lua = {
							workspace = {
								checkThirdParty = false,
							},
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				},
				eslint = {
					settings = {
						workingDirectories = { mode = "auto" },
					},
				},
			},
			setup = {
				eslint = function()
					Utils.format.register(Utils.lsp.formatter({
						name = "eslint: lsp",
						primary = false,
						priority = 200,
						filter = "eslint",
					}))
				end,
			},
		},
		config = function(_, opts)
			Utils.format.register(Utils.lsp.formatter())

			if opts.autoformat ~= nil then
				vim.g.autoformat = opts.autoformat
			end

			Utils.lsp.on_attach(function(client, buffer)
				Keymaps.on_attach(client, buffer)
			end)

			local register_capability = vim.lsp.handlers["client/registerCapability"]

			vim.lsp.handlers["client/registerCapability"] = function(err, res, ctx)
				local ret = register_capability(err, res, ctx)
				local client = vim.lsp.get_client_by_id(ctx.client_id)
				if client then
					Keymaps.on_attach(client, vim.api.nvim_get_current_buf())
				end
				return ret
			end

			if opts.inlay_hints.enabled then
				Utils.lsp.on_attach(function(client, buffer)
					if client:supports_method("textDocument/inlayHint") then
						vim.lsp.inlay_hint.enable(true, { bufnr = buffer })
					end
				end)
			end

			if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
				opts.diagnostics.virtual_text.prefix = function(diagnostic)
					local icons = Config.icons.diagnostics
					for d, icon in pairs(icons) do
						if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
							return icon
						end
					end
				end
			end

			vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

			local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
			vim.lsp.config("*", {
				capabilities = vim.tbl_deep_extend(
					"force",
					{},
					vim.lsp.protocol.make_client_capabilities(),
					has_cmp and cmp_nvim_lsp.default_capabilities() or {},
					opts.capabilities or {}
				),
			})

			local mason_servers = {}
			for server, server_opts in pairs(opts.servers) do
				server_opts = server_opts == true and {} or server_opts
				if server_opts and server_opts.enabled ~= false then
					local hook = opts.setup[server] or opts.setup["*"]
					if not (hook and hook(server, server_opts)) then
						vim.lsp.config(server, without_local_keys(server_opts))
						drop_unknown_filetypes(server)
						if server_opts.mason == false then
							vim.lsp.enable(server)
						else
							mason_servers[#mason_servers + 1] = server
						end
					end
				end
				return use_mason
			end

			Utils.mason.ensure_servers(mason_servers)
			require("mason-lspconfig").setup({ automatic_enable = mason_servers })
		end,
	},
	{
		"mason-org/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts = {
			ensure_installed = {
				"stylua",
				"shfmt",
				"prettier",
			},
		},
		config = function(_, opts)
			local mason_opts = vim.deepcopy(opts)
			mason_opts.ensure_installed = nil
			require("mason").setup(mason_opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)
			Utils.mason.ensure_installed(opts.ensure_installed)
		end,
	},
	{
		"folke/lazydev.nvim",
		ft = "lua",
		opts = {
			library = {
				{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
			},
		},
	},
	{
		"nvimtools/none-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "mason-org/mason.nvim" },
		opts = function(_, opts)
			return opts or {}
		end,
		config = function(_, opts)
			-- none-ls plugin is internally structured as null-ls
			local ok, null_ls = pcall(require, "null-ls")
			if not ok then
				vim.notify("none-ls.nvim failed to load", vim.log.levels.ERROR)
				return
			end

			-- stylua/prettier formatting is handled by conform.nvim; this only
			-- wires up the diagnostics sources contributed by per-language specs.
			-- A source whose tool is missing (no toolchain, Mason still installing) errors on every run.
			null_ls.setup(vim.tbl_extend("force", opts, {
				sources = vim.tbl_filter(function(source)
					local command = source.generator and source.generator.opts and source.generator.opts.command
					return type(command) ~= "string" or vim.fn.executable(command) == 1
				end, opts.sources or {}),
			}))
		end,
	},
}
