#!/usr/bin/env bash
# Points Claude Code's status line at ~/.claude/statusline.sh.
# Merges only the `statusLine` key: Claude Code owns the rest of settings.json,
# so the file itself is not managed by chezmoi.
set -euo pipefail

settings="$HOME/.claude/settings.json"

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found; skipping Claude status line setup (install it via the base profile)." >&2
  exit 0
fi

mkdir -p "$(dirname "$settings")"
[ -s "$settings" ] || echo '{}' > "$settings"

tmp="$(mktemp)"
jq '.statusLine = {"type": "command", "command": "~/.claude/statusline.sh", "padding": 0, "refreshInterval": 10}' \
  "$settings" > "$tmp" && mv "$tmp" "$settings"
echo "claude: status line -> ~/.claude/statusline.sh"
