#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

cd "$REPO_DIR"

printf '\n===== OMARCHY BACKUP =====\n'
printf 'Repository: %s\n' "$REPO_DIR"
printf 'Started:    %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"

printf '\n===== COPYING CONFIG =====\n'

copy_file() {
    local src="$1"
    local dst="$2"

    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dst")"
        cp -f "$src" "$dst"
        printf 'OK   %s\n' "$src"
    else
        printf 'SKIP %s (not present)\n' "$src"
    fi
}

copy_dir() {
    local src="$1"
    local dst="$2"

    if [[ -d "$src" ]]; then
        mkdir -p "$dst"
        rsync -a \
            --exclude='*.bak' \
            --exclude='*.omasettings.bak' \
            --exclude='themes/current.theme' \
            --exclude='lua/plugins/theme.lua' \
            "$src/" "$dst/"
        printf 'OK   %s/\n' "$src"
    else
        printf 'SKIP %s/ (not present)\n' "$src"
    fi
}

copy_file "$HOME_DIR/.bashrc" "$REPO_DIR/home/.bashrc"
copy_file "$HOME_DIR/.XCompose" "$REPO_DIR/home/.XCompose"

copy_file "$HOME_DIR/.config/chromium-flags.conf" "$REPO_DIR/config/chromium-flags.conf"
copy_file "$HOME_DIR/.config/mimeapps.list" "$REPO_DIR/config/mimeapps.list"
copy_file "$HOME_DIR/.config/starship.toml" "$REPO_DIR/config/starship.toml"

copy_file "$HOME_DIR/.config/alacritty/alacritty.toml" "$REPO_DIR/config/alacritty/alacritty.toml"
copy_file "$HOME_DIR/.config/btop/btop.conf" "$REPO_DIR/config/btop/btop.conf"
copy_file "$HOME_DIR/.config/foot/foot.ini" "$REPO_DIR/config/foot/foot.ini"
copy_file "$HOME_DIR/.config/ghostty/config" "$REPO_DIR/config/ghostty/config"
copy_file "$HOME_DIR/.config/kitty/kitty.conf" "$REPO_DIR/config/kitty/kitty.conf"
copy_file "$HOME_DIR/.config/mise/config.toml" "$REPO_DIR/config/mise/config.toml"
copy_file "$HOME_DIR/.config/sonora/settings.json" "$REPO_DIR/config/sonora/settings.json"
copy_file "$HOME_DIR/.config/tmux/tmux.conf" "$REPO_DIR/config/tmux/tmux.conf"
copy_file "$HOME_DIR/.config/voxtype/config.toml" "$REPO_DIR/config/voxtype/config.toml"

copy_dir "$HOME_DIR/.config/hypr" "$REPO_DIR/config/hypr"
copy_dir "$HOME_DIR/.config/nvim" "$REPO_DIR/config/nvim"

copy_file "$HOME_DIR/.config/omarchy/omasettings.json" "$REPO_DIR/config/omarchy/omasettings.json"
copy_file "$HOME_DIR/.config/omarchy/shell.toml" "$REPO_DIR/config/omarchy/shell.toml"
copy_file "$HOME_DIR/.config/omarchy/shell.json" "$REPO_DIR/config/omarchy/shell.json"
copy_file "$HOME_DIR/.config/omarchy/dock-settings.json" "$REPO_DIR/config/omarchy/dock-settings.json"
copy_file "$HOME_DIR/.config/systemd/user/omarchy-backup.service" "$REPO_DIR/config/systemd/user/omarchy-backup.service"
copy_file "$HOME_DIR/.config/systemd/user/omarchy-backup.timer" "$REPO_DIR/config/systemd/user/omarchy-backup.timer"
copy_dir "$HOME_DIR/.config/omarchy/themes/porshe-959" "$REPO_DIR/config/omarchy/themes/porshe-959"

printf '\n===== UPDATING PACKAGE LISTS =====\n'

pacman -Qqe | sort > "$REPO_DIR/packages/explicit.txt"
pacman -Qqem | sort > "$REPO_DIR/packages/foreign.txt"

printf 'OK   packages/explicit.txt\n'
printf 'OK   packages/foreign.txt\n'

printf '\n===== UPDATING PLUGIN MANIFEST =====\n'

plugin_list="$(omarchy plugin list 2>/dev/null || true)"

{
    printf '# Omarchy third-party plugins\n'
    printf '# ID<TAB>STATE<TAB>GIT_URL\n'

    for plugin_dir in "$HOME_DIR/.config/omarchy/plugins"/*; do
        [[ -d "$plugin_dir" ]] || continue

        plugin_id="$(basename "$plugin_dir")"
        plugin_url="$(git -C "$plugin_dir" remote get-url origin 2>/dev/null || true)"

        [[ -n "$plugin_url" ]] || continue

        plugin_state="$(printf '%s\n' "$plugin_list" | awk -v id="$plugin_id" '$1 == id {print $2; exit}' || true)"
        printf '%s\t%s\t%s\n' "$plugin_id" "${plugin_state:-unknown}" "$plugin_url"
    done
} > "$REPO_DIR/plugins.txt"

printf 'OK   plugins.txt\n'

printf '\n===== STAGING =====\n'

git add -A

printf '\n===== GIT CHECK =====\n'

git diff --cached --check

if git diff --cached --quiet; then
    printf '\nNo changes detected. Nothing to commit or push.\n'
    exit 0
fi

printf '\n===== CHANGES =====\n'

git diff --cached --stat

COMMIT_MSG="Update Omarchy backup $(date '+%Y-%m-%d %H:%M:%S')"

printf '\n===== COMMIT =====\n'

git commit -m "$COMMIT_MSG"

printf '\n===== PUSH =====\n'

git push

printf '\n===== COMPLETE =====\n'

git log -1 --oneline
git status --short --branch