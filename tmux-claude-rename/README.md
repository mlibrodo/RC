# tmux-claude-rename

Auto-renames tmux windows based on context when using Claude Code, while respecting manual renames.

## How it works

- When you open Claude Code in a tmux window with a default name (`bash`, `zsh`, `2.1.128`, etc.), the window is automatically renamed to the current git repo name (or directory name) on your first message.
- You can ask Claude to rename the window at any time: *"rename this window to hotfix"*
- If you manually rename the window yourself (`tmux rename-window` or `Prefix + ,`), Claude will not override it.

### Manual-rename protection

The script stores the last Claude-set name in a tmux window variable (`@claude_window_name`). Before renaming, it compares the current name against that variable. If they differ, you renamed it manually and the call is skipped.

## Files

```
bin/
  tmux-rename-window   — renames the current window; tracks @claude_window_name to detect manual renames
  tmux-auto-rename     — called by the Claude Code hook; only acts on default-looking window names
install.sh             — copies scripts and patches ~/.claude/settings.json
```

## Installation

```bash
chmod +x install.sh
./install.sh
```

Then open `/hooks` inside Claude Code (or restart it) to activate the hook.

### Manual installation

1. Copy both scripts to `~/.local/bin/` and make them executable:
   ```bash
   cp bin/* ~/.local/bin/
   chmod +x ~/.local/bin/tmux-rename-window ~/.local/bin/tmux-auto-rename
   ```

2. Add this to the `hooks` section of `~/.claude/settings.json`:
   ```json
   "hooks": {
     "UserPromptSubmit": [
       {
         "hooks": [
           {
             "type": "command",
             "command": "~/.local/bin/tmux-auto-rename",
             "async": true
           }
         ]
       }
     ]
   }
   ```

## Requirements

- tmux
- Claude Code CLI
- `jq` (for the install script only)
