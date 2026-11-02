local phase = os.getenv("HEALTH_PHASE") or "report"
local out_dir = assert(os.getenv("OUT_DIR"), "OUT_DIR not set")
local samples_dir = assert(os.getenv("SAMPLES_DIR"), "SAMPLES_DIR not set")
local samples = { "sample.lua", "sample.ts", "sample.go", "sample.json", "sample.yaml" }

local POLL_MS = 10000
local STABLE_POLLS = 4
local INSTALL_TIMEOUT_MS = 25 * 60 * 1000
local HEALTH_TIMEOUT_MS = 5 * 60 * 1000

local function log(msg)
	io.stdout:write(("[health:%s] %s\n"):format(phase, msg))
	io.stdout:flush()
end

local function write(name, lines)
	vim.fn.writefile(type(lines) == "table" and lines or vim.split(lines, "\n"), vim.fs.joinpath(out_dir, name))
end

local function load_all_plugins()
	local plugins = vim.tbl_keys(require("lazy.core.config").plugins)
	require("lazy").load({ plugins = plugins })
end

local function mason_installing()
	local ok, registry = pcall(require, "mason-registry")
	if not ok then
		return {}
	end
	return vim.iter(registry.get_all_packages())
		:filter(function(pkg)
			return pkg:is_installing()
		end)
		:map(function(pkg)
			return pkg.name
		end)
		:totable()
end

local function parser_count()
	local ok, ts = pcall(require, "nvim-treesitter")
	return ok and #ts.get_installed() or 0
end

local function open_samples()
	vim.cmd.cd(samples_dir)
	for _, file in ipairs(samples) do
		vim.cmd.edit(vim.fs.joinpath(samples_dir, file))
		vim.wait(3000)
	end
end

local function wait_idle(timeout_ms)
	local deadline = vim.uv.now() + timeout_ms
	local stable, last = 0, -1
	while vim.uv.now() < deadline do
		vim.wait(POLL_MS)
		local busy = mason_installing()
		local parsers = parser_count()
		log(("mason installing=%d [%s] parsers=%d"):format(#busy, table.concat(busy, ","), parsers))
		stable = (#busy == 0 and parsers == last) and stable + 1 or 0
		last = parsers
		if stable >= STABLE_POLLS then
			return true
		end
	end
	return false
end

local function install_phase()
	load_all_plugins()
	open_samples()
	log("idle=" .. tostring(wait_idle(INSTALL_TIMEOUT_MS)))
	open_samples()
	log("idle(second pass)=" .. tostring(wait_idle(INSTALL_TIMEOUT_MS)))

	local installed = require("mason-registry").get_installed_package_names()
	table.sort(installed)
	write("mason-installed.txt", installed)
	local parsers = require("nvim-treesitter").get_installed()
	table.sort(parsers)
	write("parsers-installed.txt", parsers)
end

local function lsp_report()
	local lines = {}
	for _, file in ipairs(samples) do
		vim.cmd.edit(vim.fs.joinpath(samples_dir, file))
		local buf = vim.api.nvim_get_current_buf()
		vim.wait(60000, function()
			return #vim.lsp.get_clients({ bufnr = buf }) > 0
		end, 500)
		vim.wait(5000)
		local names = vim.tbl_map(function(c)
			return c.name
		end, vim.lsp.get_clients({ bufnr = buf }))
		table.sort(names)
		local highlight = vim.treesitter.highlighter.active[buf] and "ts=on" or "ts=off"
		lines[#lines + 1] = ("%s ft=%s %s clients=[%s]"):format(file, vim.bo[buf].filetype, highlight, table.concat(names, ","))
	end
	write("lsp-clients.txt", lines)
	vim.iter(lines):each(log)
end

local function health_report()
	vim.cmd("checkhealth")
	local buf = vim.fn.bufnr("health://")
	local done = vim.wait(HEALTH_TIMEOUT_MS, function()
		return buf ~= -1 and vim.api.nvim_buf_is_valid(buf) and not vim.bo[buf].modifiable
	end, 500)
	if not done then
		error("checkhealth did not finish within " .. HEALTH_TIMEOUT_MS / 1000 .. "s")
	end
	write("checkhealth.txt", vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	write("messages.txt", vim.api.nvim_exec2("messages", { output = true }).output)
end

local function report_phase()
	load_all_plugins()
	vim.cmd.cd(samples_dir)
	lsp_report()
	health_report()
end

local ok, err = xpcall(phase == "install" and install_phase or report_phase, debug.traceback)
if not ok then
	log("FAILED: " .. tostring(err))
	write("error-" .. phase .. ".txt", tostring(err))
	vim.cmd("cquit 1")
end
vim.cmd("qa!")
