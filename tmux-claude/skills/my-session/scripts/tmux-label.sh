#!/usr/bin/env bash
# Label the tmux window running this Claude session.
# Usage: tmux-label.sh "<bar label: KEY + 1-3 words>" "<summary sentence, <=20 words>" [session-id]
#
#   With a session-id, the labels are also saved to ~/.claude/session-labels/<session-id>
#   (line 1 = bar, line 2 = summary) so tmux-session-relabel can restore them on resume.
#
#   bar label -> window name (status bar). Also sets @claude_window_name so
#                tmux-auto-rename / tmux-rename-window treat it as Claude-owned.
#   summary   -> @session_summary window option, shown in the Ctrl-a w / Ctrl-a " list.
#
# Targets $TMUX_PANE so it hits Claude's window even if you've switched away. No-op outside tmux.

bar=$(printf '%s' "${1:-}" | tr -s '[:space:]' ' ' | awk '{ n = (NF > 4 ? 4 : NF); for (i = 1; i <= n; i++) printf "%s%s", $i, (i < n ? " " : "") }')
summary=$(printf '%s' "${2:-}" | tr -s '[:space:]' ' ' | awk '{ n = (NF > 20 ? 20 : NF); for (i = 1; i <= n; i++) printf "%s%s", $i, (i < n ? " " : "") }')

if [ -n "${3:-}" ] && { [ -n "$bar" ] || [ -n "$summary" ]; }; then
    mkdir -p ~/.claude/session-labels
    printf '%s\n%s\n' "$bar" "$summary" > ~/.claude/session-labels/"$3"
fi

[ -n "${TMUX_PANE:-}" ] || { echo "not in tmux; labels saved only"; exit 0; }

if [ -n "$bar" ]; then
    tmux set-option -w -t "$TMUX_PANE" automatic-rename off
    tmux rename-window -t "$TMUX_PANE" "$bar"
    tmux set-option -w -t "$TMUX_PANE" @claude_window_name "$bar"
fi
[ -n "$summary" ] && tmux set-option -w -t "$TMUX_PANE" @session_summary "$summary"

echo "bar: $bar"
echo "summary: $summary"
