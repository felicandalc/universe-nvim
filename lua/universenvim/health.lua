local M = {}

local health = vim.health
local is_windows = vim.fn.has("win32") == 1
local is_linux = vim.fn.has("linux") == 1
local is_mac = vim.fn.has("mac") == 1

local MIN_NVIM = "0.12"
local MIN_NODE = "22.13"
local MIN_TREE_SITTER = "0.26.1"
local COMMAND_TIMEOUT_MS = 5000

local function first_executable(names)
	for _, name in ipairs(names) do
		if vim.fn.executable(name) == 1 then
			return name
		end
	end
end

local function version_of(cmd)
	local ok, proc = pcall(vim.system, cmd, { text = true, timeout = COMMAND_TIMEOUT_MS })
	if not ok then
		return nil
	end
	local result = proc:wait()
	if result.code ~= 0 then
		return nil
	end
	return (result.stdout or ""):match("(%d+%.%d+%.?%d*)")
end

local function at_least(found, minimum)
	return vim.version.ge(vim.version.parse(found), vim.version.parse(minimum))
end

local function required(name, why)
	if vim.fn.executable(name) == 1 then
		health.ok(name)
	else
		health.error(name .. " not found", why)
	end
end

local function optional(name, needed_for, advice)
	if vim.fn.executable(name) == 1 then
		health.ok(name)
	else
		health.warn(name .. " not found, needed for " .. needed_for, advice)
	end
end

local function check_neovim()
	health.start("Neovim")
	local v = vim.version()
	local text = ("%d.%d.%d"):format(v.major, v.minor, v.patch)
	if vim.fn.has("nvim-" .. MIN_NVIM) == 0 then
		health.error(("Neovim %s is older than %s"):format(text, MIN_NVIM), "Install the latest stable release")
		return
	end
	health.ok("Neovim " .. text)
	if v.minor >= 13 and v.prerelease then
		health.info("Nightly build: keep it current, plugins enable 0.13-only APIs on any 0.13-dev build")
	end
end

local function check_compiler()
	local names = is_windows and { "cc", "gcc", "clang", "cl", "zig" } or { "cc", "gcc", "clang" }
	local compiler = first_executable(names)
	if compiler then
		health.ok("C compiler: " .. compiler)
	else
		health.error("No C compiler found", "Install " .. table.concat(names, ", ") .. " (treesitter parsers, telescope-fzf-native)")
	end
	if vim.fn.executable("make") == 1 then
		health.ok("make")
	elseif is_windows and (vim.fn.executable("zig") == 1 or vim.fn.executable("cmake") == 1) then
		health.ok("make not found, zig/cmake builds telescope-fzf-native on Windows")
	else
		health.error("make not found", "Needed by telescope-fzf-native and LuaSnip jsregexp")
	end
end

local function check_tree_sitter()
	if vim.fn.executable("tree-sitter") == 0 then
		health.error("tree-sitter CLI not found", "Install it from your package manager or the GitHub release, not npm")
		return
	end
	local found = version_of({ "tree-sitter", "--version" })
	if not found then
		health.error("Could not read `tree-sitter --version`")
	elseif at_least(found, MIN_TREE_SITTER) then
		health.ok("tree-sitter " .. found)
	else
		health.error(("tree-sitter %s is older than %s"):format(found, MIN_TREE_SITTER), "nvim-treesitter (main) needs it")
	end
end

local function check_required()
	health.start("Required tools")
	for _, name in ipairs({ "git", "curl", "tar", "unzip", "gzip" }) do
		required(name, "lazy.nvim, Mason and parser downloads")
	end
	check_compiler()
	check_tree_sitter()
	required("rg", "Telescope live_grep (install ripgrep)")
	required("fd", "Telescope find_files (install fd; Debian ships it as fdfind)")
end

local function check_node()
	if vim.fn.executable("node") == 0 then
		health.warn(
			"node not found, needed for TypeScript, ESLint, Tailwind, JSON, YAML, Docker LSPs, prettier, markdownlint, markdown-preview",
			"Install Node.js " .. MIN_NODE .. "+"
		)
		return
	end
	local found = version_of({ "node", "--version" })
	if found and at_least(found, MIN_NODE) then
		health.ok("node " .. found)
	else
		health.warn(
			("node %s is older than %s, yaml-language-server will not start"):format(found or "?", MIN_NODE),
			"Install Node.js " .. MIN_NODE .. "+"
		)
	end
	optional("npm", "Mason packages installed through npm", "Install npm alongside Node.js")
end

local function check_python()
	local python = first_executable({ "python3", "python" })
	if not python then
		health.warn("python3 not found, needed for cmakelang and cmakelint", "Install Python 3 with the venv module")
		return
	end
	health.ok(python)
	local ok = vim.system({ python, "-c", "import venv" }, { timeout = COMMAND_TIMEOUT_MS }):wait().code == 0
	if ok then
		health.ok("python venv module")
	else
		health.warn("python venv module missing, Mason cannot install cmakelang and cmakelint", "Install python3-venv")
	end
end

local function check_clipboard()
	local tool = is_mac and "pbcopy" or is_linux and first_executable({ "wl-copy", "xclip", "xsel" })
	if is_windows or tool then
		health.ok("clipboard tool: " .. (tool or "built in"))
	else
		health.warn(
			"No clipboard tool found, Neovim falls back to OSC 52 when the terminal supports it",
			"Install wl-clipboard or xclip"
		)
	end
end

local function check_sqlite()
	if not is_linux then
		return
	end
	local found = #vim.fn.glob("/usr/lib*/libsqlite3.so*", false, true) > 0
		or #vim.fn.glob("/usr/lib/*/libsqlite3.so*", false, true) > 0
		or #vim.fn.glob("/lib/*/libsqlite3.so*", false, true) > 0
	if found then
		health.ok("libsqlite3")
	else
		health.warn("libsqlite3 not found, needed for yanky.nvim history", "Install libsqlite3-dev (sqlite-devel, sqlite)")
	end
end

local function check_optional()
	health.start("Optional tools")
	check_node()
	check_python()
	optional("go", "Go (gopls, goimports, gofumpt, gomodifytags, impl, delve)", "Install Go")
	if is_linux and vim.list_contains({ "aarch64", "arm64" }, vim.uv.os_uname().machine) then
		optional("clangd", "C/C++ on Linux arm64, where Mason has no build", "Install clangd from your package manager")
	end
	optional("gh", "octo.nvim", "Install the GitHub CLI")
	optional("lazygit", "the lazygit terminal", "Install lazygit")
	check_clipboard()
	check_sqlite()
end

function M.check()
	check_neovim()
	check_required()
	check_optional()
end

return M
