#!/usr/bin/env bash
set -euo pipefail
export ISSUES_DEMO_REPO="${1:-${ISSUES_DEMO_REPO:-}}"
export ISSUES_DEMO_ISSUE="${2:-${ISSUES_DEMO_ISSUE:-}}"
if [[ -z "$ISSUES_DEMO_REPO" || -z "$ISSUES_DEMO_ISSUE" ]]; then
  echo "Usage: scripts/demo.sh OWNER/REPO ISSUE_NUMBER" >&2
  exit 2
fi
plugin_root="$(cd "$(dirname "$0")/.." && pwd)"
demo_dir="$(mktemp -d -t issues-nvim-demo)"
export ISSUES_PLUGIN_ROOT="$plugin_root"
export ISSUE_PROVIDER_CACHE_DIR="$demo_dir/cache"
export NVIM_LOG_FILE="$demo_dir/nvim.log"
mkdir "$demo_dir/repo"
cd "$demo_dir/repo"
git init -q -b main
printf 'return { timeout = 30 }\n' > sample.lua
git add sample.lua
git -c user.name="Local demo" -c user.email="demo@example.invalid" commit -qm "Demo baseline"
printf 'return { timeout = 60 }\n' > sample.lua
exec nvim -u "$plugin_root/scripts/demo.lua" -i NONE
