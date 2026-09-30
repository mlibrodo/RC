# tmux-claude

Claude Code ↔ tmux integration. Everything Claude-specific in this repo lives
here, so the main `.tmux.conf` stays plain tmux.

## What you get

| Piece | What it does |
|---|---|
| Window auto-rename | On your first message, a window still named `bash`/`zsh`/an IP is renamed to the git repo (or directory) name. Windows you renamed yourself are left alone. |
| `!!!` marker | A red `!!!` appears on any non-active window whose Claude session is waiting on you, and clears when you reply. |
| `/my-session` skill | `/my-session start <topic>` labels the window, sets a one-line summary and opens the session checklist; `checklist` prints it; `end` marks the session done and prints the final checklist; `review [timeframe]` lists past sessions with status and open-item counts. |
| Interaction rules | `claude/interaction.md`, imported globally from `~/.claude/CLAUDE.md`: every ask for you starts with ❓ and comes last in the reply; every session keeps an owner-tagged (You / Me / others) checklist in `~/.claude/session-checklists/<session-id>.md`, ticked off as work gets done. |
| Session summaries in the window list | `Ctrl-a w` / `Ctrl-a "` show each window's `/my-session` summary next to its name. |

## Files

```
bin/
  tmux-auto-rename     UserPromptSubmit hook: renames default-named windows
  tmux-rename-window   renames the window unless you renamed it by hand (@claude_window_name)
  tmux-needs-answer    Stop/Notification hook sets @needs_answer, UserPromptSubmit clears it
claude/
  interaction.md       global rules: ❓ asks + session checklist (symlinked to ~/.claude/interaction.md)
skills/
  my-session/          the /my-session skill (SKILL.md + scripts)
tmux-claude.conf       tmux bindings/formats that read @session_summary and @needs_answer
install.sh             wires it all up (see below)
```

## Setting up a fresh laptop

1. Install Claude Code, tmux, git and jq (`brew install tmux jq`).
2. Clone the repo and run the top-level installer. It symlinks the dotfiles
   and then runs `tmux-claude/install.sh` for you:
   ```bash
   git clone https://github.com/mlibrodo/RC.git ~/RC
   cd ~/RC && ./install.sh
   ```
   To install only this piece: `~/RC/tmux-claude/install.sh`.
3. Restart Claude Code (or open `/hooks`) so it loads the hooks and the skill.
4. Check it worked:
   - `ls -l ~/.claude/skills/my-session` points into the repo.
   - In Claude Code, `/hooks` lists `tmux-auto-rename` and `tmux-needs-answer`.
   - `grep tmux-claude ~/.tmux.conf.local` shows the `source-file` line.
   - In tmux, type `/my-session start test` in Claude: the window gets relabelled.

### What `install.sh` changes

- **`~/.local/bin/`**: symlinks to each script in `bin/`. Make sure it's on your `$PATH`.
- **`~/.claude/skills/<name>`**: symlinks to each skill in `skills/`. An existing
  non-symlink directory is moved to `~/.claude/backups/skills/<name>.bak-<timestamp>` first.
- **`~/.claude/settings.json`**: adds these hooks. Hooks that are already there are skipped.
  | Event | Command |
  |---|---|
  | `UserPromptSubmit` | `~/.local/bin/tmux-auto-rename` |
  | `UserPromptSubmit` | `~/.local/bin/tmux-needs-answer clear` |
  | `Stop` | `~/.local/bin/tmux-needs-answer set` |
  | `Notification` | `~/.local/bin/tmux-needs-answer set` |
- **`~/.tmux.conf.local`**: adds `source-file <repo>/tmux-claude/tmux-claude.conf`.

It is safe to re-run. Because it uses symlinks, editing the files in the repo
takes effect straight away (after `Ctrl-a :source-file ~/.tmux.conf` for tmux changes).

## Uninstall

```bash
rm -f ~/.local/bin/tmux-auto-rename ~/.local/bin/tmux-rename-window ~/.local/bin/tmux-needs-answer
rm -f ~/.claude/skills/my-session
# then delete the tmux-claude source-file line from ~/.tmux.conf.local, and the
# four hooks above from ~/.claude/settings.json (or via /hooks in Claude Code)
```
