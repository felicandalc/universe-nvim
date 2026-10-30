local Utils = require("universenvim.utils.core")

local function has(exe)
	return vim.fn.executable(exe) == 1
end

local function run(plugin, cmd)
	local result = vim.system(cmd, { cwd = plugin.dir, text = true }):wait()
	if result.code ~= 0 then
		error(table.concat(cmd, " ") .. " failed:\n" .. (result.stdout or "") .. (result.stderr or ""))
	end
end

-- the Makefile hardcodes gcc on Windows, so a zig-only toolchain has to override CC
local function fzf_build(plugin)
	if has("make") and (not Utils.is_windows() or has("gcc")) then
		return run(plugin, { "make" })
	end
	if has("make") and has("zig") then
		return run(plugin, { "make", "CC=zig cc" })
	end
	run(plugin, { "cmake", "-S.", "-Bbuild", "-DCMAKE_BUILD_TYPE=Release" })
	run(plugin, { "cmake", "--build", "build", "--config", "Release" })
	run(plugin, { "cmake", "--install", "build", "--config", "Release", "--prefix", "build" })
end

return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = fzf_build,
			},
			"nvim-tree/nvim-web-devicons",
		},
		config = function()
			local telescope_status_ok, telescope = pcall(require, "telescope")
			if not telescope_status_ok then
				Utils.error("Telescope could not be loaded!")
				return
			end

			pcall(telescope.load_extension, "media_files")

			local actions_status_ok, actions = pcall(require, "telescope.actions")
			if not actions_status_ok then
				Utils.error("Telescope actions could not be loaded!")
				return
			end

			telescope.setup({
				defaults = {
					prompt_prefix = " ",
					selection_caret = " ",
					path_display = { "smart" },

					mappings = {
						i = {
							["<C-n>"] = actions.cycle_history_next,
							["<C-p>"] = actions.cycle_history_prev,

							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,

							["<C-c>"] = actions.close,

							["<Down>"] = actions.move_selection_next,
							["<Up>"] = actions.move_selection_previous,

							["<CR>"] = actions.select_default,
							["<C-x>"] = actions.select_horizontal,
							["<C-v>"] = actions.select_vertical,
							["<C-t>"] = actions.select_tab,

							["<C-u>"] = actions.preview_scrolling_up,
							["<C-d>"] = actions.preview_scrolling_down,

							["<PageUp>"] = actions.results_scrolling_up,
							["<PageDown>"] = actions.results_scrolling_down,

							["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
							["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
							["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
							["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
							["<C-l>"] = actions.complete_tag,
							["<C-_>"] = actions.which_key, -- keys from pressing <C-/>
						},

						n = {
							["<esc>"] = actions.close,
							["<CR>"] = actions.select_default,
							["<C-x>"] = actions.select_horizontal,
							["<C-v>"] = actions.select_vertical,
							["<C-t>"] = actions.select_tab,

							["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
							["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
							["<C-q>"] = actions.send_to_qflist + actions.open_qflist,
							["<M-q>"] = actions.send_selected_to_qflist + actions.open_qflist,

							["j"] = actions.move_selection_next,
							["k"] = actions.move_selection_previous,
							["H"] = actions.move_to_top,
							["M"] = actions.move_to_middle,
							["L"] = actions.move_to_bottom,

							["<Down>"] = actions.move_selection_next,
							["<Up>"] = actions.move_selection_previous,
							["gg"] = actions.move_to_top,
							["G"] = actions.move_to_bottom,

							["<C-u>"] = actions.preview_scrolling_up,
							["<C-d>"] = actions.preview_scrolling_down,

							["<PageUp>"] = actions.results_scrolling_up,
							["<PageDown>"] = actions.results_scrolling_down,

							["?"] = actions.which_key,
						},
					},
				},
				pickers = {
					find_files = {
						hidden = true,
					},
					-- Default configuration for builtin pickers goes here:
					-- picker_name = {
					--   picker_config_key = value,
					--   ...
					-- }
					-- Now the picker_config_key will be applied every time you call this
					-- builtin picker
				},
				extensions = {
					media_files = {
						-- filetypes whitelist
						-- defaults to {"png", "jpg", "mp4", "webm", "pdf"}
						filetypes = { "png", "webp", "jpg", "jpeg" },
						find_cmd = vim.fn.executable("rg") == 1 and "rg" or "fd",
					},
					-- Your extension configuration goes here:
					-- extension_name = {
					--   extension_config_key = value,
					-- }
					-- please take a look at the readme of the extension you want to configure
				},
			})

			local fzf_ok, fzf_err = pcall(telescope.load_extension, "fzf")
			if not fzf_ok then
				vim.notify(
					"telescope-fzf-native failed to load, rebuild it with `:Lazy build telescope-fzf-native.nvim`\n" .. fzf_err,
					vim.log.levels.WARN
				)
			end

			local keymap = vim.keymap

			keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Fuzzy find files in cwd" })
			keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Fuzzy find recent files" })
			keymap.set("n", "<leader>fs", "<cmd>Telescope live_grep<cr>", { desc = "Find string in cwd" })
			keymap.set(
				"n",
				"<leader>fc",
				"<cmd>Telescope grep_string<cr>",
				{ desc = "Find string under cursor in cwd" }
			)
		end,
	},
	{ "nvim-telescope/telescope-media-files.nvim", enabled = not Utils.is_windows() },
}
