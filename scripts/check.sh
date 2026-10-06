#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
nvim --headless -u NONE -i NONE -l scripts/fixture.lua
