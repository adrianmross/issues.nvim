-- Isolated live demo: uses existing gh auth and a public GitHub repository.
vim.opt.rtp:prepend(vim.env.ISSUES_PLUGIN_ROOT)
if vim.env.ISSUE_PROVIDERS_ROOT then
	vim.opt.rtp:prepend(vim.env.ISSUE_PROVIDERS_ROOT)
end
vim.o.termguicolors = true
vim.o.background = "dark"
vim.o.number = false
vim.o.swapfile = false
vim.o.title = true
vim.o.titlestring = "issues.nvim live demo"
require("issues").setup({ provider = "github", options = { repo = "cli/cli" } })
local lines = {
	"issues.nvim — isolated live demo",
	"",
	"Read-only public GitHub issue; authentication is owned by your existing gh.",
	"This session uses separate configuration and cache, preserving your editor.",
	"",
	"gI  live issue read           gO  offline cached read",
	"gS  search and select         gH  loading/auth prerequisites",
	"gR  issue beside review-mode  q   close the issue preview",
	"",
	"Every preview displays source, fetched time and stale status.",
	"Nothing is merged, published, assigned or transitioned.",
}
vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
vim.bo.buftype = "nofile"
vim.bo.bufhidden = "hide"
vim.bo.modifiable = false
vim.keymap.set("n", "gI", "<cmd>IssueRefresh #14598<cr>")
vim.keymap.set("n", "gO", "<cmd>IssueOffline #14598<cr>")
vim.keymap.set("n", "gS", "<cmd>IssueSearch is:open label:bug<cr>")
vim.keymap.set("n", "gH", "<cmd>IssueHealth<cr>")
if vim.env.REVIEW_MODE_ROOT then
	vim.opt.rtp:prepend(vim.env.REVIEW_MODE_ROOT)
	require("review_mode").setup({})
	vim.keymap.set("n", "gR", function()
		vim.cmd("edit sample.lua")
		require("review_mode").review_local({})
		vim.defer_fn(function()
			vim.cmd("ReviewModeIssueOffline #14598")
		end, 1000)
	end)
end
vim.schedule(function()
	vim.cmd("IssueRefresh #14598")
end)
