#!/usr/bin/env bash
# List or reorder the windows of a tmux session. Used by /my-session tmux-reorder.
#
# Usage:
#   tmux-windows.sh list  [session]          one line per window, tab-separated:
#                                             index  window_id  name  summary  command  path  active
#   tmux-windows.sh apply [session] <@id>…   reorder: the given window ids take the session's existing
#                                             index slots in that order. Windows you leave out keep
#                                             their relative order after the listed ones.
#
# The session defaults to the one running this pane ($TMUX_PANE), so it works even if you've switched away.
# Reordering swaps windows into place (no new index numbers, no gaps), and keeps every pane running.

set -euo pipefail

[ -n "${TMUX:-}${TMUX_PANE:-}" ] || { echo "not in tmux" >&2; exit 1; }

cmd=${1:-}; shift || true

session=""
if [ $# -gt 0 ] && [ "${1#@}" = "$1" ]; then session=$1; shift; fi
if [ -z "$session" ]; then
    session=$(tmux display-message -p ${TMUX_PANE:+-t "$TMUX_PANE"} '#{session_name}')
fi

case "$cmd" in
list)
    tmux list-windows -t "$session" -F \
        $'#{window_index}\t#{window_id}\t#{window_name}\t#{@session_summary}\t#{pane_current_command}\t#{pane_current_path}\t#{?window_active,active,}' \
        | sed "s|$HOME|~|g"
    ;;
apply)
    [ $# -gt 0 ] || { echo "apply: give window ids (@N) in the order you want" >&2; exit 1; }

    slots=(); current=()
    while IFS=$'\t' read -r idx id; do slots+=("$idx"); current+=("$id"); done \
        < <(tmux list-windows -t "$session" -F $'#{window_index}\t#{window_id}')

    # Wanted order: the given ids that still exist, then any window not mentioned.
    want=()
    for id in "$@"; do
        if printf '%s\n' "${current[@]}" | grep -qxF "$id"; then
            want+=("$id")
        else
            echo "skipping $id: no such window in $session" >&2
        fi
    done
    for id in "${current[@]}"; do
        printf '%s\n' "${want[@]}" | grep -qxF "$id" || want+=("$id")
    done

    # Selection sort with swap-window: put want[k] into slot k. -d keeps the current window focused.
    for k in "${!want[@]}"; do
        at=$(tmux display-message -p -t "${want[$k]}" '#{window_index}')
        [ "$at" = "${slots[$k]}" ] || tmux swap-window -d -s "${want[$k]}" -t "$session:${slots[$k]}"
    done

    tmux list-windows -t "$session" -F '#{window_index} #{window_name}'
    ;;
*)
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
    ;;
esac
