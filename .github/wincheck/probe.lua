local phase = os.getenv("PROBE_PHASE") or "report"
local out_dir = assert(os.getenv("OUT_DIR"), "OUT_DIR not set")
local samples_dir = assert(os.getenv("SAMPLES_DIR"), "SAMPLES_DIR not set")
local samples = { "sample.lua", "sample.ts", "sample.go", "sample.json", "sample.yaml" }

local function log(msg)
	io.stdout:write("[probe:" .. phase .. "] " .. msg .. "\n")
	io.stdout:flush()
end

local function write(name, lines)
	vim.fn.writefile(type(lines) == "table" and lines or vim.split(lines, "\n"), vim.fs.joinpath(out_dir, name))
end

local function mason_installing()
	local ok, registry = pcall(require, "mason-registry")
	if not ok then
		return {}
	end
	local busy = {}
	for _, pkg in ipairs(registry.get_all_packages()) do
		if pkg:is_installing() then
			busy[#busy + 1] = pkg.name
		end
	end
	return busy
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
		vim.wait(10000)
		local busy = mason_installing()
		local parsers = parser_count()
		log(("mason installing=%d [%s] parsers=%d"):format(#busy, table.concat(busy, ","), parsers))
		if #busy == 0 and parsers == last then
			stable = stable + 1
		else
			stable = 0
		end
		last = parsers
		if stable >= 4 then
			return true
		end
	end
	return false
end

local function install_phase()
	open_samples()
	-- re-open so FileType fires again after servers finished installing
	local idle = wait_idle(25 * 60 * 1000)
	log("idle=" .. tostring(idle))
	open_samples()
	idle = wait_idle(10 * 60 * 1000)
	log("idle(second pass)=" .. tostring(idle))

	local ok, registry = pcall(require, "mason-registry")
	local installed = ok and registry.get_installed_package_names() or {}
	table.sort(installed)
	write("mason-installed.txt", installed)
	local parsers = require("nvim-treesitter").get_installed()
	table.sort(parsers)
	write("parsers-installed.txt", parsers)
	log("mason installed: " .. table.concat(installed, ", "))
	log("parsers installed: " .. table.concat(parsers, ", "))
end

local function lsp_report()
	local lines = {}
	vim.cmd.cd(samples_dir)
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
		local hl = vim.treesitter.highlighter.active[buf] and "ts=on" or "ts=off"
		lines[#lines + 1] = ("%s ft=%s %s clients=[%s]"):format(file, vim.bo[buf].filetype, hl, table.concat(names, ","))
	end
	write("lsp-clients.txt", lines)
	for _, l in ipairs(lines) do
		log(l)
	end
end

local function term_roundtrip(cmd)
	vim.cmd("enew")
	local buf = vim.api.nvim_get_current_buf()
	local ok, job = pcall(vim.fn.jobstart, cmd, { term = true })
	local found = ok
		and vim.wait(30000, function()
			return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"):find("TT_OK_42") ~= nil
		end, 500)
	return ("cmd=%s job=%s found=%s"):format(vim.inspect(cmd), tostring(job), tostring(found)),
		vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

local function toggleterm_report()
	local lines = {}
	require("lazy").load({ plugins = { "toggleterm.nvim" } })
	local shell = require("toggleterm.config").get("shell")
	lines[#lines + 1] = "toggleterm shell=" .. vim.inspect(shell)
	lines[#lines + 1] = "vim.o.shell=" .. vim.o.shell
	local echo = [[ -NoProfile -Command "echo TT_OK_$((6*7)); Start-Sleep 5"]]
	for _, cmd in ipairs({
		{ "cmd.exe", "/c", "echo TT_OK_42 & ping -n 5 127.0.0.1 >NUL" },
		shell .. echo,
	}) do
		local summary, buf_lines = term_roundtrip(cmd)
		lines[#lines + 1] = summary
		vim.list_extend(lines, buf_lines)
	end

	local Terminal = require("toggleterm.terminal").Terminal
	local term = Terminal:new({ cmd = shell .. echo, hidden = true, close_on_exit = false })
	term:open()
	local found = vim.wait(30000, function()
		return term.bufnr
			and vim.api.nvim_buf_is_valid(term.bufnr)
			and table.concat(vim.api.nvim_buf_get_lines(term.bufnr, 0, -1, false), "\n"):find("TT_OK_42") ~= nil
	end, 500)
	lines[#lines + 1] = "toggleterm Terminal roundtrip=" .. tostring(found)
	write("toggleterm.txt", lines)
	log(table.concat(lines, " | "))
end

local function fzf_report()
	local plugin = require("lazy.core.config").plugins["telescope-fzf-native.nvim"]
	local dir = plugin and plugin.dir or "?"
	local dll = vim.fs.joinpath(dir, "build", "libfzf.dll")
	local exists = vim.uv.fs_stat(dll) ~= nil
	local load_ok, load_err = pcall(function()
		require("lazy").load({ plugins = { "telescope.nvim" } })
		require("telescope").load_extension("fzf")
	end)
	local build_dir = vim.fn.glob(vim.fs.joinpath(dir, "build", "**", "*"), false, true)
	local lines = {
		"dll=" .. dll,
		"exists=" .. tostring(exists),
		"load_extension ok=" .. tostring(load_ok) .. " " .. tostring(load_err or ""),
		"--- build dir ---",
	}
	vim.list_extend(lines, build_dir)
	write("fzf.txt", lines)
	log(table.concat(lines, " | ", 1, 3))
end

local function health_report()
	vim.cmd("checkhealth")
	vim.wait(5000)
	vim.cmd("silent! write! " .. vim.fn.fnameescape(vim.fs.joinpath(out_dir, "checkhealth.txt")))
	local messages = vim.api.nvim_exec2("messages", { output = true }).output
	write("messages.txt", messages)
end

local function report_phase()
	lsp_report()
	for name, fn in pairs({ toggleterm = toggleterm_report, fzf = fzf_report }) do
		local ok, err = xpcall(fn, debug.traceback)
		if not ok then
			log(name .. " FAILED: " .. tostring(err))
			write(name .. "-error.txt", tostring(err))
		end
	end
	health_report()
end

local ok, err = xpcall(phase == "install" and install_phase or report_phase, debug.traceback)
if not ok then
	log("FAILED: " .. tostring(err))
	write("probe-error-" .. phase .. ".txt", tostring(err))
end
vim.cmd("qa!")
