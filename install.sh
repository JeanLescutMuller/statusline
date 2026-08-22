#!/bin/bash
# Installs this status line on the current machine:
#   - copies statusline-command.sh -> ~/.claude/statusline-command.sh
#   - merges the statusLine block into ~/.claude/settings.json (backed up first)
# Safe to re-run (idempotent): re-copies the script, and only writes to
# settings.json if the statusLine block is missing or points elsewhere.
set -euo pipefail

cd "$(dirname "$0")"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required (used by both this installer and the status line itself)." >&2
  exit 1
fi

if [ "$(uname -s)" != "Darwin" ]; then
  echo "warning: the memory segment (line 3, 💾) uses macOS-only 'top'/'sysctl' and will" >&2
  echo "         break on this OS. See 'Known quirks' in CLAUDE.md before relying on it." >&2
fi

mkdir -p "$HOME/.claude"
cp statusline-command.sh "$HOME/.claude/statusline-command.sh"
chmod +x "$HOME/.claude/statusline-command.sh"
echo "deployed statusline-command.sh -> $HOME/.claude/statusline-command.sh"

SETTINGS="$HOME/.claude/settings.json"
WANT_COMMAND='bash $HOME/.claude/statusline-command.sh'

if [ ! -f "$SETTINGS" ]; then
  echo '{}' > "$SETTINGS"
fi

CURRENT_COMMAND=$(jq -r '.statusLine.command // empty' "$SETTINGS")

if [ "$CURRENT_COMMAND" = "$WANT_COMMAND" ]; then
  echo "settings.json: statusLine already wired up, leaving as-is"
else
  cp "$SETTINGS" "$SETTINGS.bak"
  jq --arg cmd "$WANT_COMMAND" \
    '.statusLine = {"type": "command", "command": $cmd, "padding": 0, "refreshInterval": 10}' \
    "$SETTINGS" > "$SETTINGS.tmp"
  mv "$SETTINGS.tmp" "$SETTINGS"
  echo "settings.json: wired up statusLine (backup saved to $SETTINGS.bak)"
fi

echo "done — takes effect on the next status-line refresh, no restart needed"
