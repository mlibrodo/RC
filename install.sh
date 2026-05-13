#!/usr/bin/env bash
# Symlink the dotfiles in this repo into $HOME, with backups of anything displaced.
# Re-runnable: existing correct symlinks are left alone.
#
# Per-machine overrides go in ~/.bashrc.local, ~/.gitconfig.local,
# ~/.vimrc.local, ~/.tmux.conf.local — created as empty stubs if absent.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Prereq check ---
missing=()
for cmd in git vim tmux jq; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ "${#missing[@]}" -gt 0 ]; then
    echo "Missing prerequisites: ${missing[*]}" >&2
    echo "  macOS:         brew install ${missing[*]}" >&2
    echo "  Debian/Ubuntu: sudo apt-get install ${missing[*]}" >&2
    exit 1
fi

# --- Backup + symlink helper ---
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

link() {
    local src="$1" dst="$2"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  ok    $dst"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/"
        echo "  back  $dst  ->  $BACKUP_DIR/"
    fi
    ln -s "$src" "$dst"
    echo "  link  $dst  ->  $src"
}

echo "Linking dotfiles from $REPO_DIR into $HOME"
link "$REPO_DIR/bashrc"     "$HOME/.bashrc"
link "$REPO_DIR/.vimrc"     "$HOME/.vimrc"
link "$REPO_DIR/.vim"       "$HOME/.vim"
link "$REPO_DIR/.tmux.conf" "$HOME/.tmux.conf"
link "$REPO_DIR/.screenrc"  "$HOME/.screenrc"
link "$REPO_DIR/.gitconfig" "$HOME/.gitconfig"

# --- Empty .local override stubs ---
for f in .bashrc.local .gitconfig.local .vimrc.local .tmux.conf.local; do
    if [ ! -e "$HOME/$f" ]; then
        touch "$HOME/$f"
        echo "  stub  $HOME/$f (empty override file)"
    fi
done

# --- Vundle + plugins (cloned into ~/.vim/bundle/, which is gitignored) ---
echo "Installing Vundle and Vim plugins"
VUNDLE_DIR="$HOME/.vim/bundle/Vundle.vim"
if [ ! -d "$VUNDLE_DIR/.git" ]; then
    mkdir -p "$HOME/.vim/bundle"
    git clone --depth 1 https://github.com/VundleVim/Vundle.vim.git "$VUNDLE_DIR"
fi
vim -E -s -u "$HOME/.vimrc" +PluginInstall +qall </dev/null || true

# --- Claude Code tmux-auto-rename hook ---
echo "Installing Claude Code tmux-auto-rename hook"
bash "$REPO_DIR/tmux-claude-rename/install.sh"

echo
echo "Done."
[ -d "$BACKUP_DIR" ] && echo "Displaced files backed up to: $BACKUP_DIR"
echo "Open a new shell, or run:  source ~/.bashrc"
echo
echo "Put per-machine tweaks in:"
echo "  ~/.bashrc.local      ~/.gitconfig.local"
echo "  ~/.vimrc.local       ~/.tmux.conf.local"
