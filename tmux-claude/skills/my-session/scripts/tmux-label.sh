#!/usr/bin/env bash
# Label the tmux window running this Claude session.
# Usage: tmux-label.sh "<bar label: TICKET + 1-3 words>" "<summary sentence, <=20 words>"
#
#   bar label -> window name (status bar). Also sets @claude_window_name so
#                tmux-auto-rename / tmux-rename-window treat it as Claude-owned.
#   summary   -> @session_summary window option, shown in the Ctrl-a w / Ctrl-a " list.
#
# Targets $TMUX_PANE so it hits Claude's window even if you've switched away. No-op outside tmux.

[ -n "${TMUX_PANE:-}" ] || { echo "not in tmux; skipped"; exit 0; }

bar=$(printf '%s' "${1:-}" | tr -s '[:space:]' ' ' | awk '{ n = (NF > 4 ? 4 : NF); for (i = 1; i <= n; i++) printf "%s%s", $i, (i < n ? " " : "") }')
summary=$(printf '%s' "${2:-}" | tr -s '[:space:]' ' ' | awk '{ n = (NF > 20 ? 20 : NF); for (i = 1; i <= n; i++) printf "%s%s", $i, (i < n ? " " : "") }')

if [ -n "$bar" ]; then
    tmux set-option -w -t "$TMUX_PANE" automatic-rename off
    tmux rename-window -t "$TMUX_PANE" "$bar"
    tmux set-option -w -t "$TMUX_PANE" @claude_window_name "$bar"
fi
[ -n "$summary" ] && tmux set-option -w -t "$TMUX_PANE" @session_summary "$summary"

echo "bar: $bar"
echo "summary: $summary"
