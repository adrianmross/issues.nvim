# issues.nvim

Optional, read-only issue context for Neovim 0.11+. Works independently of review-mode and oscm. Native Neovim pickers, Markdown previews and async executable requests; no Lua dependencies, bundled trackers, credential store or background polling.

## Install

    {
      "adrianmross/issues.nvim",
      dependencies = { "adrianmross/issue-providers" }, -- optional provider modules
      opts = {
        projects = {
          ["/path/to/project"] = {
            provider = "github",
            options = { repo = "owner/repository" },
          },
        },
      },
    }

The selected adapter loads only when invoked. Instead of installing provider modules, install a provider with oscm extension install; issues.nvim discovers its executable via oscm extension path NAME when no Lua adapter is available. Or configure command = { "/path/to/provider" } explicitly. No oscm dependency is required when using modules or command configuration.

Provider selection can also come from issues in repository .oci-scm.json (schema oci-scm.repo.v1). User configuration takes precedence. Repository configuration selects provider and data options only, never executable paths or credentials.

## Use

- :Issue [KEY]: show context; detect a branch key using a configured/provider Lua pattern, or prompt.
- :IssueSearch QUERY: search and pick an issue.
- :IssueOffline [KEY]: cached read without tracker network access.
- :IssueRefresh [KEY]: require a successful live read.
- :IssueHealth or :checkhealth issues: diagnose provider loading, executables and authentication prerequisites. The GitHub adapter verifies the selected host through gh auth status; Linear reports credential presence without exposing its value.

Views display status, assignee, source, fetched time and stale status. Press q to close. Search syntax belongs to the adapter: GitHub issue search, Jira JQL, Linear title text.

Authentication stays with existing tools: GitHub uses authenticated gh; Jira uses jira-queue and refresh-session; Linear uses an API key or access token in the process environment. Nothing logs in automatically. Expired sessions yield actionable errors; an offline or stale snapshot never proves current authorization.

## Integration and provider API

require("issues").register(name, provider) accepts a command argv array or a request(context, request, callback) function, with optional pattern, requirements, auth_hint and health(config) returning a safe boolean/message. Modules live in issues.providers.NAME. Providers implement the [versioned executable contract](https://github.com/adrianmross/issue-providers); that contract belongs to no particular editor or CLI.

view(key, opts) and search(query, opts) accept optional root and current (a callback returning whether the requesting view is still current), plus offline/refresh flags. request(root, operation, value, opts, callback) is available for consumers that provide their own UI.

review-mode is an optional consumer: its issue commands delegate here with the review root and session guard. Configure this plugin directly; review-mode does not own issue configuration, provider loading, authentication or previews.

## Existing alternatives

[Atlas.nvim](https://github.com/emrearmagan/atlas.nvim) is a broader review/issue application with built-in tracker configuration. Its documented interface does not provide this executable contract or jira-queue session/cache delegation. [Octo.nvim](https://github.com/pwntester/octo.nvim) is an existing GitHub UI. This plugin keeps only context lookup and native preview/picker behavior; it does not replace either application's full management UI.

## Validate

    bash scripts/check.sh

Tests require Neovim only and use fixtures, never live authentication.

## Try before approving

Run scripts/demo.sh in a terminal. For local provider modules set ISSUE_PROVIDERS_ROOT to their checkout; otherwise install the github oscm extension. To include the review bridge, set REVIEW_MODE_ROOT to a review-mode checkout.

The demo uses existing gh authentication to read and search public cli/cli issues. It runs with isolated editor configuration and cache. Keys gI/gO/gS/gH show live reads, offline reads, search and health checks; gR exercises the review bridge when supplied. No installed editor configuration changes.
