local M = { mason = {} }
local root = M.mason

-- Mason builds these package types with a language toolchain; github/generic ones are prebuilt binaries.
local toolchains = {
	npm = { "npm" },
	pypi = { "python3", "python" },
	golang = { "go" },
	cargo = { "cargo" },
	gem = { "gem" },
	composer = { "composer" },
	luarocks = { "luarocks" },
	nuget = { "dotnet" },
	opam = { "opam" },
}

function root.missing_toolchain(pkg)
	local purl_type = pkg.spec.source.id:match("^pkg:([^/]+)/")
	local required = toolchains[purl_type]
	if not required then
		return nil
	end
	for _, exe in ipairs(required) do
		if vim.fn.executable(exe) == 1 then
			return nil
		end
	end
	return required[1]
end

local function install(registry, name)
	if not registry.has_package(name) then
		return
	end
	local pkg = registry.get_package(name)
	if pkg:is_installed() or pkg:is_installing() or not pkg:is_installable() or root.missing_toolchain(pkg) then
		return
	end
	pkg:install()
end

function root.ensure_installed(tools)
	local registry = require("mason-registry")
	registry.refresh(vim.schedule_wrap(function()
		for _, name in ipairs(tools) do
			install(registry, name)
		end
	end))
end

local function on_path(server)
	local cmd = vim.lsp.config[server] and vim.lsp.config[server].cmd
	return type(cmd) == "table" and vim.fn.executable(cmd[1]) == 1
end

-- Installs the Mason package behind each server (mason-lspconfig enables it once installed).
-- Servers Mason does not package, has no build for this platform (clangd on Linux arm64) or cannot
-- build here are enabled when already on PATH.
function root.ensure_servers(servers)
	local registry = require("mason-registry")
	registry.refresh(vim.schedule_wrap(function()
		local to_package = require("mason-lspconfig.mappings").get_mason_map().lspconfig_to_package
		for _, server in ipairs(servers) do
			local package_name = to_package[server]
			local pkg = package_name and registry.has_package(package_name) and registry.get_package(package_name)
			if pkg and pkg:is_installable() and not root.missing_toolchain(pkg) then
				install(registry, package_name)
			elseif not (pkg and pkg:is_installed()) and on_path(server) then
				vim.lsp.enable(server)
			end
		end
	end))
end

return M
