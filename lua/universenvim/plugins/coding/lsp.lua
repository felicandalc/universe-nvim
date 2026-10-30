local Utils = require("universenvim.utils")
local Config = require("universenvim.config")
local Keymaps = Utils.lsp.keymaps

local function inlay_hints(buf, value)
	local ih = vim.lsp.buf.inlay_hint or vim.lsp.inlay_hint
	if type(ih) == "function" then
		ih(buf, value)
	elseif type(ih) == "table" and ih.enable then
		if value == nil then
			value = not ih.is_enabled(buf)
		end
		ih.enable(buf, value)
	end
end

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "folke/neoconf.nvim", cmd = "Neoconf", config = false, dependencies = { "neovim/nvim-lspconfig" } },
			{ "folke/lazydev.nvim", ft = "lua", opts = {} },
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
					active = {
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
					source = "always",
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
					local function get_client(buf)
						return Utils.lsp.get_clients({ name = "eslint", bufnr = buf })[1]
					end

					local formatter = Utils.lsp.formatter({
						name = "eslint: lsp",
						primary = false,
						priority = 200,
						filter = "eslint",
					})

					if not pcall(require, "vim.lsp._dynamic") then
						formatter.name = "eslint: EslintFixAll"
						formatter.sources = function(buf)
							local client = get_client(buf)
							return client and { "eslint" } or {}
						end
						formatter.format = function(buf)
							local client = get_client(buf)
							if client then
								local diag =
									vim.diagnostic.get(buf, { namespace = vim.lsp.diagnostic.get_namespace(client.id) })
								if #diag > 0 then
									vim.cmd("EslintFixAll")
								end
							end
						end
					end

					Utils.format.register(formatter)
				end,
			},
		},
		config = function(_, opts)
			if Utils.is_available("neoconf.nvim") then
				local plugin = require("lazy.core.config").spec.plugins["neoconf.nvim"]
				require("neoconf").setup(require("lazy.core.plugin").values(plugin, "opts", false))
			end

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
				local client_id = ctx.client_id
				local client = vim.lsp.get_client_by_id(client_id)
				local buffer = vim.api.nvim_get_current_buf()
				Keymaps.on_attach(client, buffer)
				return ret
			end

			for name, icon in pairs(Config.icons.diagnostics) do
				name = "DiagnosticSign" .. name
				vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
			end

			if opts.inlay_hints.enabled then
				Utils.lsp.on_attach(function(client, buffer)
					if client:supports_method("textDocument/inlayHint") then
						inlay_hints(buffer, true)
					end
				end)
			end

			if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
				opts.diagnostics.virtual_text.prefix = vim.fn.has("nvim-0.10.0") == 0 and "●"
					or function(diagnostic)
						local icons = Config.icons.diagnostics
						for d, icon in pairs(icons) do
							if diagnostic.severity == vim.diagnostic.severity[d:upper()] then
								return icon
							end
						end
					end
			end

			vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

			local servers = opts.servers
			local has_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				has_cmp and cmp_nvim_lsp.default_capabilities() or {},
				opts.capabilities or {}
			)

			local have_mason, mlsp = pcall(require, "mason-lspconfig")
			local all_mslp_servers = have_mason
				and vim.tbl_keys(require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package)
				or {}
			local mason_exclude = {}

			---@return boolean? use_mason
			local function configure(server)
				local server_opts = vim.tbl_deep_extend("force", {
					capabilities = vim.deepcopy(capabilities),
				}, servers[server] or {})

				local use_mason = server_opts.mason ~= false and vim.tbl_contains(all_mslp_servers, server)
				local setup = opts.setup[server] or opts.setup["*"]

				if setup and setup(server, server_opts) then
					mason_exclude[#mason_exclude + 1] = server
				else
					vim.lsp.config(server, server_opts)
					if not use_mason then
						vim.lsp.enable(server)
					end
				end
				return use_mason
			end

			local ensure_installed = vim.tbl_filter(configure, vim.tbl_keys(servers))

			if have_mason then
				mlsp.setup({
					ensure_installed = ensure_installed,
					automatic_enable = { exclude = mason_exclude },
				})
			end
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
			automatic_installation = true,
		},
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require("mason-registry")
			mr:on("package:install:success", function()
				vim.defer_fn(function()
					require("lazy.core.handler.event").trigger({
						event = "FileType",
						buf = vim.api.nvim_get_current_buf(),
					})
				end, 100)
			end)
			local function ensure_installed()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then
						p:install()
					end
				end
			end
			if mr.refresh then
				mr.refresh(ensure_installed)
			else
				ensure_installed()
			end
		end,
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
			-- wires up the diagnostics sources contributed by per-language specs
			null_ls.setup(opts)
		end,
	},
}
