-- usage: nvim -l check.lua <checkhealth.txt> <allowlist.txt>
-- Prints every WARNING/ERROR in the report and exits 1 when one is not matched by the allowlist.
local report_path, allowlist_path = arg[1], arg[2]

local function read_lines(path)
	return vim.fn.readfile(path)
end

local function load_allowlist(path)
	return vim.iter(read_lines(path))
		:filter(function(line)
			return line:match("%S") and not line:match("^%s*#")
		end)
		:totable()
end

local function allowed(entry, patterns)
	return vim.iter(patterns):any(function(pattern)
		return entry:find(pattern) ~= nil
	end)
end

local function collect(lines)
	local findings, plugin = {}, ""
	for i, line in ipairs(lines) do
		local name = line:match("^([%w_.%-/]+):%s")
		if name and lines[i - 1] and lines[i - 1]:match("^=+$") then
			plugin = name
		end
		local level = line:match("^%s*%- [^%w]*(WARNING)") or line:match("^%s*%- [^%w]*(ERROR)")
		if level then
			findings[#findings + 1] = { level = level, entry = ("%s | %s"):format(plugin, (line:gsub("^%s*%- [^%w]*", ""))) }
		end
	end
	return findings
end

local patterns = load_allowlist(allowlist_path)
local findings = collect(read_lines(report_path))
local unexpected = 0
for _, finding in ipairs(findings) do
	local ok = allowed(finding.entry, patterns)
	unexpected = unexpected + (ok and 0 or 1)
	io.stdout:write(("%s %s\n"):format(ok and "allowed   " or "UNEXPECTED", finding.entry))
end
io.stdout:write(("%d finding(s), %d allowlisted, %d unexpected\n"):format(#findings, #findings - unexpected, unexpected))
os.exit(unexpected == 0 and 0 or 1)
