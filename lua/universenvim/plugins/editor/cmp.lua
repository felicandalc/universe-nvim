local Utils = require("universenvim.utils")

return {
	{
		"hrsh7th/nvim-cmp",
		version = false,
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-emoji",
		},
		opts = function()
			vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
			local cmp = require("cmp")
			local types = require("cmp.types")
			local defaults = require("cmp.config.default")()
			local kind_icons = {
				Array = " ",
				Boolean = "󰨙 ",
				Class = " ",
				Color = " ",
				Control = " ",
				Collapsed = " ",
				Constant = "󰏿 ",
				Constructor = " ",
				Enum = " ",
				EnumMember = " ",
				Event = " ",
				Field = " ",
				File = " ",
				Folder = " ",
				Function = "󰊕 ",
				Interface = " ",
				Key = " ",
				Keyword = " ",
				Method = "󰊕 ",
				Module = " ",
				Namespace = "󰦮 ",
				Null = " ",
				Number = "󰎠 ",
				Object = " ",
				Operator = " ",
				Package = " ",
				Property = " ",
				Reference = " ",
				Snippet = " ",
				String = " ",
				Struct = "󰆼 ",
				Text = " ",
				TypeParameter = " ",
				Unit = " ",
				Value = " ",
				Variable = "󰀫 ",
			}

			local compare = require("cmp.config.compare")
			
			local function has_auto_import(entry)
				local completion_item = entry.completion_item
				return completion_item and completion_item.additionalTextEdits and #completion_item.additionalTextEdits > 0
			end

			local function source_priority(entry1, entry2)
				local source1 = entry1.source.name
				local source2 = entry2.source.name
				
				-- Priority 1: Auto imports (LSP with additionalTextEdits)
				local auto_import1 = source1 == "nvim_lsp" and has_auto_import(entry1)
				local auto_import2 = source2 == "nvim_lsp" and has_auto_import(entry2)
				
				if auto_import1 and not auto_import2 then
					return true
				elseif auto_import2 and not auto_import1 then
					return false
				end
				
				-- Priority 2: Regular LSP
				if source1 == "nvim_lsp" and source2 ~= "nvim_lsp" then
					return true
				elseif source2 == "nvim_lsp" and source1 ~= "nvim_lsp" then
					return false
				end
				
				return nil
			end
			
			local function deprioritize_snippet(entry1, entry2)
				local kind1 = entry1:get_kind()
				local kind2 = entry2:get_kind()
				
				if kind1 == types.lsp.CompletionItemKind.Snippet and kind2 ~= types.lsp.CompletionItemKind.Snippet then
					return false
				elseif kind2 == types.lsp.CompletionItemKind.Snippet and kind1 ~= types.lsp.CompletionItemKind.Snippet then
					return true
				end
				return nil
			end

			local comparators = {
				compare.offset,
				compare.exact,
				source_priority,
				compare.score,
				deprioritize_snippet,
				compare.recently_used,
				compare.locality,
				compare.kind,
				compare.sort_text,
				compare.length,
				compare.order,
			}

			return {
				completion = {
					completeopt = "menu,menuone",
				},
				mapping = cmp.mapping.preset.insert({
					["<C-k>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-j>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping({
						i = cmp.mapping.abort(),
						c = cmp.mapping.close(),
					}),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
					["<S-CR>"] = cmp.mapping.confirm({
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}),
					["<C-CR>"] = function(fallback)
						cmp.abort()
						fallback()
					end,
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif require("luasnip").expand_or_jumpable() then
							vim.fn.feedkeys(
								vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true),
								""
							)
						else
							fallback()
						end
					end, {
						"i",
						"s",
					}),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif require("luasnip").jumpable(-1) then
							vim.fn.feedkeys(
								vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true),
								""
							)
						else
							fallback()
						end
					end, {
						"i",
						"s",
					}),
				}),
				sources = cmp.config.sources({
					{ name = "lazydev", group_index = 0 },
					{ name = "nvim_lsp" },
					{ name = "path" },
				}, {
					{ name = "buffer" },
					{ name = "emoji" },
				}),
				formatting = {
					format = function(_, item)
						if kind_icons[item.kind] then
							item.kind = kind_icons[item.kind] .. item.kind
						end
						return item
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = {
						border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
					},
				},
				experimental = {
					ghost_text = {
						hl_group = "CmpGhostText",
					},
				},
				sorting = {
					priority_weight = 2,
					comparators = comparators,
				},
			}
		end,
		config = function(_, opts)
			for _, source in ipairs(opts.sources) do
				source.group_index = source.group_index or 1
			end
			require("cmp").setup(opts)
		end,
	},
	{
		"L3MON4D3/LuaSnip",
		build = (not Utils.is_windows()) and "make install_jsregexp" or nil,
		dependencies = {
			{
				"rafamadriz/friendly-snippets",
				config = function()
					require("luasnip.loaders.from_vscode").lazy_load()
				end,
			},
			{
				"nvim-cmp",
				dependencies = {
					"saadparwaiz1/cmp_luasnip",
				},
				opts = function(_, opts)
					opts.snippet = {
						expand = function(args)
							require("luasnip").lsp_expand(args.body)
						end,
					}
					table.insert(opts.sources, { name = "luasnip" })
				end,
			},
		},
		opts = {
			history = true,
			delete_check_events = "TextChanged",
		},
		keys = {
			{
				"<tab>",
				function()
					return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
				end,
				expr = true,
				silent = true,
				mode = "i",
			},
			{
				"<tab>",
				function()
					require("luasnip").jump(1)
				end,
				mode = "s",
			},
			{
				"<s-tab>",
				function()
					require("luasnip").jump(-1)
				end,
				mode = { "i", "s" },
			},
		},
	},
}
