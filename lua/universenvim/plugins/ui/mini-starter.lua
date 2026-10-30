local Utils = require("universenvim.utils.core")

return {
	"nvim-mini/mini.starter",
	version = false,
	event = "VimEnter",
	opts = function()
		local status_ok, mini_starter = pcall(require, "mini.starter")
		if not status_ok then
			Utils.error("Mini starter could not be loaded!")
			return
		end

		local universeNvimLogo = table.concat({
			"░█░█░█▀█░▀█▀░█░█░█▀▀░█▀▄░█▀▀░█▀▀░█▀█░█░█░▀█▀░█▄█",
			"░█░█░█░█░░█░░▀▄▀░█▀▀░█▀▄░▀▀█░█▀▀░█░█░▀▄▀░░█░░█░█",
			"░▀▀▀░▀░▀░▀▀▀░░▀░░▀▀▀░▀░▀░▀▀▀░▀▀▀░▀░▀░░▀░░▀▀▀░▀░▀",
		}, "\n")

		local new_section = function(name, action, section)
			return { name = name, action = action, section = section }
		end

		local opts = {
			evaluate_single = true,
			header = universeNvimLogo,
			items = {
				new_section("Find file", "Telescope find_files", "Telescope"),
				new_section("Recent files", "Telescope oldfiles", "Telescope"),
				new_section("Grep text", "Telescope live_grep", "Telescope"),
				new_section("New file", "ene | startinsert", "Built-in"),
				new_section("Quit", "qa", "Built-in"),
				new_section("Session restore", [[lua require("persistence").load()]], "Session"),
			},
			content_hooks = {
				mini_starter.gen_hook.adding_bullet("░ ", false),
				mini_starter.gen_hook.aligning("center", "center"),
			},
			footer = "",
		}
		return opts
	end,
	config = function(_, opts)
		local status_ok, mini_starter = pcall(require, "mini.starter")
		if not status_ok then
			Utils.error("Mini starter could not be loaded!")
			return
		end

		mini_starter.setup(opts)
	end,
}
