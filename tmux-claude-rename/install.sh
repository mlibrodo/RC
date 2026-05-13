#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing tmux-claude-rename..."

# Copy scripts
mkdir -p ~/.local/bin
cp "$SCRIPT_DIR/bin/tmux-rename-window" ~/.local/bin/tmux-rename-window
cp "$SCRIPT_DIR/bin/tmux-auto-rename" ~/.local/bin/tmux-auto-rename
chmod +x ~/.local/bin/tmux-rename-window ~/.local/bin/tmux-auto-rename
echo "  Scripts installed to ~/.local/bin/"

# Add hook to ~/.claude/settings.json
SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS" ]; then
    echo '{}' > "$SETTINGS"
fi

# Check if hook already exists
if jq -e '.hooks.UserPromptSubmit' "$SETTINGS" > /dev/null 2>&1; then
    echo "  Hook already present in $SETTINGS — skipping (edit manually if needed)"
else
    TMP=$(mktemp)
    jq '.hooks.UserPromptSubmit = [{"hooks": [{"type": "command", "command": "~/.local/bin/tmux-auto-rename", "async": true}]}]' "$SETTINGS" > "$TMP"
    mv "$TMP" "$SETTINGS"
    echo "  Hook added to $SETTINGS"
fi

echo ""
echo "Done. Open /hooks in Claude Code (or restart) to activate the hook."
echo ""
echo "Usage:"
echo "  Auto:   start Claude in any tmux window named 'bash'/'zsh' or an IP — it renames on first message"
echo "  Manual: ask Claude to 'rename this window to <name>' and it runs tmux-rename-window"
