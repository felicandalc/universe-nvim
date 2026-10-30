local Utils = require("universenvim.utils")

return {
	{
		"dmmulroy/ts-error-translator.nvim",
		ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
		opts = {},
	},
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			if type(opts.ensure_installed) == "table" then
				vim.list_extend(opts.ensure_installed, { "typescript", "tsx" })
			end
		end,
	},
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				tsserver = {
					enabled = false,
				},
				ts_ls = {
					enabled = false,
				},
				vtsls = {
					-- explicitly add default filetypes, so that we can extend
					-- them in related extras
					filetypes = {
						"javascript",
						"javascriptreact",
						"javascript.jsx",
						"typescript",
						"typescriptreact",
						"typescript.tsx",
					},
					settings = {
						complete_function_calls = true,
						vtsls = {
							enableMoveToFileCodeAction = true,
							autoUseWorkspaceTsdk = true,
							experimental = {
								completion = {
									enableServerSideFuzzyMatch = true,
								},
							},
						},
						typescript = {
							updateImportsOnFileMove = { enabled = "always" },
							suggest = {
								completeFunctionCalls = true,
							},
							inlayHints = {
								enumMemberValues = { enabled = true },
								functionLikeReturnTypes = { enabled = true },
								parameterNames = { enabled = "literals" },
								parameterTypes = { enabled = true },
								propertyDeclarationTypes = { enabled = true },
								variableTypes = { enabled = false },
							},
						},
					},
					keys = {
						{
							"gD",
							function()
								local client = Utils.lsp.get_clients({ name = "vtsls", bufnr = 0 })[1]
								local params = vim.lsp.util.make_position_params(0, client and client.offset_encoding or "utf-16")
								Utils.lsp.execute({
									command = "typescript.goToSourceDefinition",
									arguments = { params.textDocument.uri, params.position },
									open = true,
								})
							end,
							desc = "Goto Source Definition",
						},
						{
							"gR",
							function()
								Utils.lsp.execute({
									command = "typescript.findAllFileReferences",
									arguments = { vim.uri_from_bufnr(0) },
									open = true,
								})
							end,
							desc = "File References",
						},
						{
							"<leader>co",
							Utils.lsp.action["source.organizeImports"],
							desc = "Organize Imports",
						},
						{
							"<leader>cM",
							Utils.lsp.action["source.addMissingImports.ts"],
							desc = "Add missing imports",
						},
						{
							"<leader>cu",
							Utils.lsp.action["source.removeUnused.ts"],
							desc = "Remove unused imports",
						},
						{
							"<leader>cD",
							Utils.lsp.action["source.fixAll.ts"],
							desc = "Fix all diagnostics",
						},
						{
							"<leader>cV",
							function()
								Utils.lsp.execute({ command = "typescript.selectTypeScriptVersion" })
							end,
							desc = "Select TS workspace version",
						},
					},
				},
			},
			setup = {
				tsserver = function()
					-- disable tsserver
					return true
				end,
				ts_ls = function()
					-- disable ts_ls
					return true
				end,
				vtsls = function(_, opts)
					Utils.lsp.on_attach(function(client)
						client.commands["_typescript.moveToFileRefactoring"] = function(command)
							---@type string, string, lsp.Range
							local action, uri, range = unpack(command.arguments)

							local function move(newf)
								client:request("workspace/executeCommand", {
									command = command.command,
									arguments = { action, uri, range, newf },
								})
							end

							local fname = vim.uri_to_fname(uri)
							client:request("workspace/executeCommand", {
								command = "typescript.tsserverRequest",
								arguments = {
									"getMoveToRefactoringFileSuggestions",
									{
										file = fname,
										startLine = range.start.line + 1,
										startOffset = range.start.character + 1,
										endLine = range["end"].line + 1,
										endOffset = range["end"].character + 1,
									},
								},
							}, function(_, result)
								---@type string[]
								local files = result.body.files
								table.insert(files, 1, "Enter new path...")
								vim.ui.select(files, {
									prompt = "Select move destination:",
									format_item = function(f)
										return vim.fn.fnamemodify(f, ":~:.")
									end,
								}, function(f)
									if f and f:find("^Enter new path") then
										vim.ui.input({
											prompt = "Enter move destination:",
											default = vim.fn.fnamemodify(fname, ":h") .. "/",
											completion = "file",
										}, function(newf)
											return newf and move(newf)
										end)
									elseif f then
										move(f)
									end
								end)
							end)
						end
					end, "vtsls")
					-- copy typescript settings to javascript
					opts.settings.javascript =
						vim.tbl_deep_extend("force", {}, opts.settings.typescript, opts.settings.javascript or {})
				end,
			},
		},
	},
	{
		"mfussenegger/nvim-dap",
		optional = true,
		dependencies = {
			{
				"mason-org/mason.nvim",
				opts = function(_, opts)
					opts.ensure_installed = opts.ensure_installed or {}
					table.insert(opts.ensure_installed, "js-debug-adapter")
				end,
			},
		},
		opts = function()
			local dap = require("dap")
			if not dap.adapters["pwa-node"] then
				require("dap").adapters["pwa-node"] = {
					type = "server",
					host = "localhost",
					port = "${port}",
					executable = {
						command = vim.fn.exepath("js-debug-adapter") ~= "" and vim.fn.exepath("js-debug-adapter") or "js-debug-adapter",
						args = { "${port}" },
					},
				}
			end
			for _, language in ipairs({ "typescript", "javascript", "typescriptreact", "javascriptreact" }) do
				if not dap.configurations[language] then
					dap.configurations[language] = {
						{
							type = "pwa-node",
							request = "launch",
							name = "Launch file",
							program = "${file}",
							cwd = "${workspaceFolder}",
						},
						{
							type = "pwa-node",
							request = "attach",
							name = "Attach",
							processId = require("dap.utils").pick_process,
							cwd = "${workspaceFolder}",
						},
					}
				end
			end
		end,
	},
}
