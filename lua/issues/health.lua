local M = {}

function M.check()
	vim.health.start("Optional issue provider")
	local root = vim.fs.root(vim.uv.cwd(), ".git") or vim.uv.cwd()
	local config, provider = require("issues").resolve(root)
	if not config then
		vim.health.warn(provider)
		return
	end
	vim.health.ok("Selected provider: " .. config.provider)
	for _, command in ipairs(provider.requirements or {}) do
		if vim.fn.executable(command) == 1 then
			vim.health.ok("Available: " .. command)
		else
			vim.health.error("Missing executable: " .. command)
		end
	end
	if provider.command then
		local command = (config.command or provider.command)[1]
		if vim.fn.executable(command) == 1 then
			vim.health.ok("Provider executable is available")
		else
			vim.health.error("Provider executable is missing or not executable")
		end
	end
	if provider.health then
		local checked, available, message = pcall(provider.health, config)
		if checked and available then
			vim.health.ok(message)
		elseif checked then
			vim.health.warn(message)
		else
			vim.health.warn("Provider authentication check unavailable; verify its executable and use :IssueRefresh")
		end
	end
	if provider.auth_hint then
		vim.health.info("Authentication remains owned by the provider: " .. provider.auth_hint)
	end
	vim.health.info("Use :IssueRefresh KEY to verify a live read. Offline snapshots do not prove authentication.")
end

return M
