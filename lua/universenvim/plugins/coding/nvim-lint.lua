return {
	{
		"mfussenegger/nvim-lint",
		event = "BufReadPost",
		opts = {
			events = { "BufWritePost", "BufReadPost", "InsertLeave" },
			linters_by_ft = {
				fish = { "fish" },
			},
			linters = {},
		},
		config = function(_, opts)
			local M = {}

			local lint = require("lint")
			for name, linter in pairs(opts.linters) do
				if type(linter) == "table" and type(lint.linters) == "table" then
					lint.linters[name] = vim.tbl_deep_extend("force", lint.linters[name], linter)
				end
			end
			lint.linters_by_ft = opts.linters_by_ft

			function M.debounce(ms, fn)
				local timer = vim.uv.new_timer()
				return function(...)
					local argv = { ... }
					if timer then
						timer:start(ms, 0, function()
							timer:stop()
							vim.schedule_wrap(fn)(unpack(argv))
						end)
					end
				end
			end

			function M.lint()
				local names = lint.linters_by_ft[vim.bo.filetype] or {}
				local ctx = { filename = vim.api.nvim_buf_get_name(0) }
				ctx.dirname = vim.fn.fnamemodify(ctx.filename, ":h")
				names = vim.tbl_filter(function(name)
					local linter = lint.linters[name]
					if type(linter) == "function" then
					return true
				end
				if not linter or (linter.condition and not linter.condition(ctx)) then
					return false
				end
				local cmd = type(linter.cmd) == "function" and linter.cmd() or linter.cmd
				return type(cmd) ~= "string" or vim.fn.executable(cmd) == 1
				end, names)

				if #names > 0 then
					lint.try_lint(names)
				end
			end

			vim.api.nvim_create_autocmd(opts.events, {
				group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
				callback = M.debounce(100, M.lint),
			})
		end,
	},
}
