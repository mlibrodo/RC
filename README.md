# RC — personal dotfiles

Personal dotfiles for bash, vim, tmux, screen, and git, plus a Claude Code
hook that auto-renames tmux windows to the current repo/dir name.

Installed via symlinks: the files in `$HOME` point back into this repo, so
editing `~/.vimrc` edits the version in git. Per-machine overrides live in
untracked `.local` files (see below) so personal identity and host-specific
tweaks never end up in the public repo.

## What it installs

| Repo file              | Symlinked to            | What it does                                            |
| ---------------------- | ----------------------- | ------------------------------------------------------- |
| `bashrc`               | `~/.bashrc`             | Bash prompt with git-branch in `PS1`                    |
| `.vimrc`               | `~/.vimrc`              | Vundle, plugins, indent, status line, etc.              |
| `.vim/`                | `~/.vim/`               | Python ftplugin + syntax, plugin bundle dir             |
| `.tmux.conf`           | `~/.tmux.conf`          | `Ctrl-a` prefix, screen-compatible bindings, mouse, etc.|
| `.screenrc`            | `~/.screenrc`           | GNU screen config                                       |
| `.gitconfig`           | `~/.gitconfig`          | Aliases (`co`, `br`, `ci`, `st`, `lg`, `pub`, `pushup`) |
| `tmux-claude-rename/`  | `~/.local/bin/tmux-*`   | Auto-renames tmux windows from a Claude Code hook       |

The Vim plugins declared in `.vimrc` (vim-scala, NERDTree, ctrlp.vim) are
fetched into `~/.vim/bundle/` by Vundle. That directory is gitignored.

## Prerequisites

- `git`
- `vim`
- `tmux`
- `jq` (used by the tmux-rename installer to patch `~/.claude/settings.json`)

Install:

```bash
# macOS (Homebrew)
brew install git vim tmux jq

# Debian / Ubuntu
sudo apt-get install git vim tmux jq
```

## Install with Claude Code

Paste this into Claude Code:

> Clone `https://github.com/mlibrodo/RC` to `~/RC` and run `./install.sh`.
> It symlinks the dotfiles into my home directory, installs Vundle plus the
> Vim plugins, and sets up the Claude Code tmux-auto-rename hook. Back up
> anything it replaces.

Claude will handle prereq checks, backups, and the post-install steps
(running `:PluginInstall`, patching `~/.claude/settings.json`).

## Manual install

```bash
git clone https://github.com/mlibrodo/RC.git ~/RC
cd ~/RC && ./install.sh
```

`install.sh` is re-runnable: existing correct symlinks are left alone, and
anything it replaces is moved to `~/.dotfiles-backup-<timestamp>/`.

After it finishes, open a new shell or `source ~/.bashrc`.

## Machine-specific overrides

The base configs in this repo are portable; anything machine-specific (your
git identity, extra `$PATH` entries, host-specific tmux tweaks) lives in one
of these `.local` files, which `install.sh` creates as empty stubs:

| File                  | Sourced by    | Typical contents                                    |
| --------------------- | ------------- | --------------------------------------------------- |
| `~/.bashrc.local`     | `~/.bashrc`   | Extra `export PATH=…`, work-only aliases, secrets   |
| `~/.gitconfig.local`  | `~/.gitconfig` via `[include]` | `[user] name/email`, credential helper, signing key |
| `~/.vimrc.local`      | `~/.vimrc`    | Per-host colorscheme, font, additional plugins      |
| `~/.tmux.conf.local`  | `~/.tmux.conf` | Per-host status-bar tweaks                          |

The `.local` files are never tracked in git. Example `~/.gitconfig.local`:

```ini
[user]
    name  = Your Name
    email = you@example.com
[credential]
    helper = osxkeychain
```

After editing it, verify:

```bash
git config --get user.email   # should print what you set
```

## Claude Code tmux hook

The `tmux-claude-rename/` subdir contains a hook that auto-renames the
current tmux window to the active git repo (or directory) name on your
first message in a Claude Code session. See
[`tmux-claude-rename/README.md`](tmux-claude-rename/README.md) for details.
`install.sh` runs it for you; it copies two scripts to `~/.local/bin/` and
adds a `UserPromptSubmit` hook to `~/.claude/settings.json`. Manual renames
are respected — Claude never overrides a window name you set yourself.

## Uninstall

```bash
# Remove the symlinks
rm ~/.bashrc ~/.vimrc ~/.vim ~/.tmux.conf ~/.screenrc ~/.gitconfig

# Restore originals (most-recent backup)
cp -R ~/.dotfiles-backup-*/. ~/

# Remove the tmux-rename hook from Claude Code settings
jq 'del(.hooks.UserPromptSubmit)' ~/.claude/settings.json \
    > ~/.claude/settings.json.tmp && mv ~/.claude/settings.json{.tmp,}

# Remove the helper scripts
rm -f ~/.local/bin/tmux-rename-window ~/.local/bin/tmux-auto-rename
```
