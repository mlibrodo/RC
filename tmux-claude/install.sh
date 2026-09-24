#!/usr/bin/env bash
# Installs the Claude Code <-> tmux integration. Re-runnable.
#   - symlinks bin/* into ~/.local/bin
#   - symlinks skills/* into ~/.claude/skills
#   - adds the hooks to ~/.claude/settings.json (skips any already present)
#   - makes ~/.tmux.conf.local source tmux-claude.conf
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing tmux-claude..."
command -v jq >/dev/null || { echo "  jq is required (brew install jq)" >&2; exit 1; }

# --- Scripts ---
mkdir -p ~/.local/bin
for f in "$SCRIPT_DIR"/bin/*; do
    ln -sfn "$f" ~/.local/bin/"$(basename "$f")"
    echo "  link  ~/.local/bin/$(basename "$f")"
done

# --- Skills ---
mkdir -p ~/.claude/skills
for d in "$SCRIPT_DIR"/skills/*/; do
    name=$(basename "$d")
    dst=~/.claude/skills/$name
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        # Back up outside ~/.claude/skills so Claude doesn't load it as a duplicate skill
        bak=~/.claude/backups/skills/$name.bak-$(date +%Y%m%d-%H%M%S)
        mkdir -p ~/.claude/backups/skills && mv "$dst" "$bak"
        echo "  backup existing $dst -> $bak"
    fi
    ln -sfn "${d%/}" "$dst"
    echo "  link  $dst"
done

# --- Hooks in ~/.claude/settings.json ---
SETTINGS="$HOME/.claude/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

add_hook() {  # add_hook <event> <command>
    local event="$1" cmd="$2" tmp
    if jq -e --arg e "$event" --arg c "$cmd" \
        '[.hooks[$e][]?.hooks[]?.command] | index($c)' "$SETTINGS" >/dev/null; then
        echo "  hook  $event: $cmd (already present)"
        return
    fi
    tmp=$(mktemp)
    jq --arg e "$event" --arg c "$cmd" \
        '.hooks[$e] = ((.hooks[$e] // []) + [{"hooks": [{"type": "command", "command": $c, "async": true}]}])' \
        "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    echo "  hook  $event: $cmd (added)"
}
add_hook UserPromptSubmit "~/.local/bin/tmux-auto-rename"
add_hook UserPromptSubmit "~/.local/bin/tmux-needs-answer clear"
add_hook Stop             "~/.local/bin/tmux-needs-answer set"
add_hook Notification     "~/.local/bin/tmux-needs-answer set"

# --- tmux config ---
LOCAL=~/.tmux.conf.local
LINE="source-file $SCRIPT_DIR/tmux-claude.conf"
touch "$LOCAL"
if grep -qF "$LINE" "$LOCAL"; then
    echo "  tmux  $LOCAL already sources tmux-claude.conf"
else
    printf '\n# Claude Code integration (added by tmux-claude/install.sh)\n%s\n' "$LINE" >> "$LOCAL"
    echo "  tmux  added source line to $LOCAL"
fi
[ -n "${TMUX:-}" ] && tmux source-file ~/.tmux.conf && echo "  tmux  reloaded"

echo ""
echo "Done. Restart Claude Code (or open /hooks) so it picks up the hooks and the skill."
