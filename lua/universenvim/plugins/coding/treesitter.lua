local Utils = require("universenvim.utils.core")

local move_keys = {
	goto_next_start = { ["]f"] = "@function.outer", ["]c"] = "@class.outer" },
	goto_next_end = { ["]F"] = "@function.outer", ["]C"] = "@class.outer" },
	goto_previous_start = { ["[f"] = "@function.outer", ["[c"] = "@class.outer" },
	goto_previous_end = { ["[F"] = "@function.outer", ["[C"] = "@class.outer" },
}

local function setup_textobjects()
	require("nvim-treesitter-textobjects").setup({ move = { set_jumps = true } })
	local move = require("nvim-treesitter-textobjects.move")
	for method, keys in pairs(move_keys) do
		for key, query in pairs(keys) do
			vim.keymap.set({ "n", "x", "o" }, key, function()
				-- keep ]c/[c as diff hunk navigation in diff mode
				if vim.wo.diff and key:find("[%]%[][cC]") then
					return vim.cmd("normal! " .. key)
				end
				move[method](query, "textobjects")
			end, { desc = method:gsub("_", " ") .. " " .. query })
		end
	end
end

local function start_treesitter(buf, lang)
	if not vim.api.nvim_buf_is_valid(buf) or not pcall(vim.treesitter.start, buf, lang) then
		return
	end
	if vim.treesitter.query.get(lang, "indents") then
		vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
	end
end

local function can_install()
	return vim.fn.executable("tree-sitter") == 1
end

return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "main",
		version = false,
		lazy = false,
		build = function(plugin)
			-- parsers compiled by the pre-rewrite master branch live in the plugin dir and shadow the current ones
			for _, dir in ipairs({ "parser", "parser-info" }) do
				vim.fn.delete(vim.fs.joinpath(plugin.dir, dir), "rf")
			end
			vim.cmd("TSUpdate")
		end,
		cmd = { "TSUpdate", "TSInstall", "TSUninstall", "TSLog" },
		opts = {
			ensure_installed = { "lua", "vim", "vimdoc", "query" },
		},
		config = function(_, opts)
			local ts = require("nvim-treesitter")
			ts.setup()

			local installed = {}
			for _, lang in ipairs(ts.get_installed()) do
				installed[lang] = true
			end
			local available = {}
			for _, lang in ipairs(ts.get_available()) do
				available[lang] = true
			end

			if not can_install() then
				Utils.warn(
					"`tree-sitter` CLI not found, parsers cannot be installed. See the README prerequisites.",
					{ title = "nvim-treesitter", once = true }
				)
			else
				local missing = {}
				for _, lang in ipairs(opts.ensure_installed or {}) do
					if not installed[lang] and not vim.tbl_contains(missing, lang) then
						missing[#missing + 1] = lang
					end
				end
				if #missing > 0 then
					ts.install(missing)
				end
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("universenvim_treesitter", { clear = true }),
				callback = function(event)
					local buf, lang = event.buf, vim.treesitter.language.get_lang(event.match)
					if not lang then
						return
					end
					if installed[lang] or not available[lang] or not can_install() then
						return start_treesitter(buf, lang)
					end
					ts.install(lang):await(function(err)
						if not err then
							installed[lang] = true
							vim.schedule(function()
								start_treesitter(buf, lang)
							end)
						end
					end)
				end,
			})
		end,
	},
	{
		"nvim-treesitter/nvim-treesitter-textobjects",
		branch = "main",
		event = "VeryLazy",
		config = setup_textobjects,
	},
	{
		"windwp/nvim-ts-autotag",
		event = { "BufReadPre", "BufNewFile" },
		opts = {},
	},
	{
		"HiPhish/rainbow-delimiters.nvim",
		event = { "BufReadPost", "BufNewFile" },
	},
	{
		"nvim-treesitter/nvim-treesitter-context",
		event = "VeryLazy",
		enabled = true,
		opts = { mode = "cursor", max_lines = 3 },
		keys = {
			{
				"<leader>ut",
				function()
					local tsc = require("treesitter-context")
					tsc.toggle()
				end,
				desc = "Toggle Treesitter Context",
			},
		},
	},
}
