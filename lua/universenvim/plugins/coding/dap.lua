local Utils = require("universenvim.utils.core")

local function get_args(config)
	local modified_config = vim.deepcopy(config)

	local initial_args = type(modified_config.args) == "function" and modified_config.args()
		or modified_config.args
		or {}

	modified_config._dynamic_args = function()
		local new_input = vim.fn.input("Run with args: ", table.concat(initial_args, " "))
		return vim.split(vim.fn.expand(new_input), " ")
	end

	modified_config.args = initial_args

	return setmetatable(modified_config, {
		__index = function(t, k)
			if k == "dynamic_args" then
				return rawget(t, "_dynamic_args")()
			end
			return rawget(t, k)
		end,
	})
end

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		{
			"rcarriga/nvim-dap-ui",
			dependencies = { "nvim-neotest/nvim-nio" },
			keys = {
				{
					"<leader>du",
					function()
						require("dapui").toggle({})
					end,
					desc = "Dap UI",
				},
				{
					"<leader>de",
					function()
						require("dapui").eval()
					end,
					desc = "Eval",
					mode = { "n", "v" },
				},
			},
			opts = {},
			config = function(_, opts)
				local dap = require("dap")
				local dapui = require("dapui")
				dapui.setup(opts)
				dap.listeners.after.event_initialized["dapui_config"] = function()
					dapui.open({})
				end
				dap.listeners.before.event_terminated["dapui_config"] = function()
					dapui.close({})
				end
				dap.listeners.before.event_exited["dapui_config"] = function()
					dapui.close({})
				end
			end,
		},
		{
			"theHamsta/nvim-dap-virtual-text",
			opts = {},
		},
		{
			"jay-babu/mason-nvim-dap.nvim",
			dependencies = "mason.nvim",
			cmd = { "DapInstall", "DapUninstall" },
			opts = {
				automatic_installation = true,
				handlers = {},
				ensure_installed = {},
			},
		},
		{
			"jbyuki/one-small-step-for-vimkind",
			config = function()
				local dap = require("dap")
				dap.adapters.nlua = function(callback, conf)
					local adapter = {
						type = "server",
						host = conf.host or "127.0.0.1",
						port = conf.port or 8086,
					}
					if conf.start_neovim then
						if not dap or type(dap.run) ~= "function" then
							Utils.error("DAP not properly initialized")
							return
						end

						local original_run
						if
							pcall(function()
								original_run = dap.run
							end) and type(original_run) == "function"
						then
							local function wrapped_run(c)
								if type(c) == "table" then
									adapter.port = c.port or adapter.port
									adapter.host = c.host or adapter.host
								else
									Utils.warn("DAP run called without configuration table")
								end

								local success, err = pcall(function()
									require("osv").run_this()
								end)

								dap.run = original_run

								if not success then
									Utils.error("OSV execution failed: " .. tostring(err))
									return nil, err
								end

								if original_run and type(original_run) == "function" then
									return original_run(c)
								end
							end

							local success, replace_err = pcall(function()
								dap.run = wrapped_run
							end)

							if not success then
								Utils.error("Failed to replace dap.run: " .. tostring(replace_err))
								dap.run = original_run
							end
						else
							Utils.error("Could not retrieve original dap.run implementation")
						end
					end
					callback(adapter)
				end
				dap.configurations.lua = {
					{
						type = "nlua",
						request = "attach",
						name = "Run this file",
						start_neovim = {},
					},
					{
						type = "nlua",
						request = "attach",
						name = "Attach to running Neovim instance (port = 8086)",
						port = 8086,
					},
				}
			end,
		},
	},
	keys = {
		{ "<leader>d", "", desc = "+debug", mode = { "n", "v" } },
		{
			"<leader>dB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Breakpoint Condition",
		},
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Toggle Breakpoint",
		},
		{
			"<leader>dc",
			function()
				require("dap").continue()
			end,
			desc = "Continue",
		},
		{
			"<leader>da",
			function()
				require("dap").continue({ before = get_args })
			end,
			desc = "Run with Args",
		},
		{
			"<leader>dC",
			function()
				require("dap").run_to_cursor()
			end,
			desc = "Run to Cursor",
		},
		{
			"<leader>dg",
			function()
				require("dap").goto_()
			end,
			desc = "Go to line (no execute)",
		},
		{
			"<leader>di",
			function()
				require("dap").step_into()
			end,
			desc = "Step Into",
		},
		{
			"<leader>dj",
			function()
				require("dap").down()
			end,
			desc = "Down",
		},
		{
			"<leader>dk",
			function()
				require("dap").up()
			end,
			desc = "Up",
		},
		{
			"<leader>dl",
			function()
				require("dap").run_last()
			end,
			desc = "Run Last",
		},
		{
			"<leader>do",
			function()
				require("dap").step_out()
			end,
			desc = "Step Out",
		},
		{
			"<leader>dO",
			function()
				require("dap").step_over()
			end,
			desc = "Step Over",
		},
		{
			"<leader>dp",
			function()
				require("dap").pause()
			end,
			desc = "Pause",
		},
		{
			"<leader>dr",
			function()
				require("dap").repl.toggle()
			end,
			desc = "Toggle REPL",
		},
		{
			"<leader>ds",
			function()
				require("dap").session()
			end,
			desc = "Session",
		},
		{
			"<leader>dt",
			function()
				require("dap").terminate()
			end,
			desc = "Terminate",
		},
		{
			"<leader>dw",
			function()
				require("dap.ui.widgets").hover()
			end,
			desc = "Widgets",
		},
	},
	config = function()
		local Config = require("universenvim.config")
		vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

		for name, sign in pairs(Config.icons.dap) do
			sign = type(sign) == "table" and sign or { sign }
			vim.fn.sign_define(
				"Dap" .. name,
				{ text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
			)
		end
	end,
}
