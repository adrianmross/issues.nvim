local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.rtp:prepend(root)
local issues = require("issues")
issues.setup({})
assert(not package.loaded["issues.providers.jira"])
local missing
issues.request(vim.uv.cwd(), "get", "EX-1", {}, function(_, err)
	missing = err
end)
assert(missing:find("No issue provider"))

local calls = {}
issues.register("fixture", {
	pattern = "%u+%-%d+",
	request = function(context, request, callback)
		calls[#calls + 1] = { context = context, request = request }
		callback({
			schema = "issue-provider.response.v1",
			issue = { key = request.key, title = "Issue context", body = "Acceptance criteria" },
			cache = { source = "cache", fetchedAt = 42, stale = true },
		})
	end,
})
issues.setup({
	provider = "fixture",
	options = { target = "one" },
	projects = { ["/project/two"] = { options = { target = "two" } } },
})
local result
issues.request("/project/two", "get", "EX-1", { offline = true }, function(value, err)
	assert(not err)
	result = value
end)
assert(result.issue.title == "Issue context" and result.cache.stale)
assert(calls[1].request.options.target == "two" and calls[1].request.offline)
assert(#issues.keys("EX-1 EX-1 EX-2", "%u+%-%d+") == 2)

local system = vim.system
vim.system = function(argv, opts, callback)
	assert(opts.cwd == "/project/command")
	assert(argv[1] == "fixture-provider" and argv[2] == "--request")
	local request = vim.json.decode(argv[3])
	assert(request.operation == "search" and request.query == "security")
	callback({
		code = 0,
		stdout = vim.json.encode({
			schema = "issue-provider.response.v1",
			items = { { key = "EX-2", title = "Search" } },
		}),
		stderr = "",
	})
	return {}
end
issues.setup({ provider = "command", command = { "fixture-provider" } })
local search
issues.request("/project/command", "search", "security", {}, function(value, err)
	assert(not err)
	search = value
end)
assert(vim.wait(1000, function()
	return search ~= nil
end))
assert(search.items[1].key == "EX-2")
vim.system = system

issues.register("invalid", {
	request = function(_, _, callback)
		callback({ schema = "wrong" })
	end,
})
issues.setup({ provider = "invalid" })
local invalid
issues.request(vim.uv.cwd(), "get", "EX-1", {}, function(_, err)
	invalid = err
end)
assert(invalid:find("Invalid issue provider response"))
local shared = vim.fn.tempname()
vim.fn.mkdir(shared, "p")
local shared_config = { schema = "oci-scm.repo.v1", issues = { provider = "fixture", options = { target = "shared" } } }
local encoded_config = vim.json.encode(shared_config)
vim.fn.writefile({ encoded_config }, shared .. "/.oci-scm.json")
issues.setup({})
local selected = assert(issues.resolve(shared))
assert(selected.provider == "fixture" and selected.options.target == "shared")
vim.fn.writefile({ "invalid json" }, shared .. "/.oci-scm.json")
local invalid_config, config_err = issues.resolve(shared)
assert(not invalid_config and config_err:find("Invalid repository"))
assert(vim.fn.filereadable(shared .. "/.oci-scm.json") == 1, "configuration was renamed or deleted")
vim.fn.delete(shared, "rf")
-- CLI-installed adapters can be reused without loading Neovim adapter modules.
local extension = vim.fn.tempname()
vim.fn.mkdir(extension, "p")
vim.fn.writefile({
	vim.json.encode({
		schema = "oci-scm.extension.v1",
		kind = "issue-provider",
		executable = "issue-provider",
	}),
}, extension .. "/oscm-extension.json")
local executable = vim.fn.executable
vim.fn.executable = function(name)
	return name == "oscm" and 1 or executable(name)
end
vim.system = function(argv)
	assert(argv[1] == "oscm" and argv[2] == "extension" and argv[3] == "path")
	return {
		wait = function()
			return { code = 0, stdout = extension .. "\n" }
		end,
	}
end
issues.setup({ provider = "extension-fixture" })
local extension_config, extension_provider = issues.resolve(shared)
assert(extension_config and extension_provider.command[1] == extension .. "/issue-provider")
vim.system = system
vim.fn.executable = executable
vim.fn.delete(extension, "rf")

-- Native preview includes provenance; obsolete consumers cannot open it.
local previews = {}
local preview = vim.lsp.util.open_floating_preview
vim.lsp.util.open_floating_preview = function(lines)
	previews[#previews + 1] = lines
	return vim.api.nvim_create_buf(false, true)
end
issues.setup({ provider = "fixture" })
issues.view("EX-1", { root = vim.uv.cwd(), offline = true })
assert(#previews == 1 and table.concat(previews[1], "\n"):find("stale snapshot"))
issues.view("EX-1", {
	root = vim.uv.cwd(),
	current = function()
		return false
	end,
})
assert(#previews == 1)
vim.lsp.util.open_floating_preview = preview

print(
	"issues fixture: optional loading, per-project selection, command contract, stale provenance and invalid responses passed"
)
vim.cmd("qa!")
