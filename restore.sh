#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
SAFETY_DIR="$HOME_DIR/omarchy-restore-safety/$TIMESTAMP"

usage() {
    cat <<USAGE
Usage:
  ./restore.sh prepare
  ./restore.sh configs
  ./restore.sh packages
  ./restore.sh plugins
  ./restore.sh systemd
  ./restore.sh all

Stages:
  prepare   Verify the environment and create the safety-backup directory.
  configs   Restore backed-up user configuration and custom theme.
  packages  Install missing official and foreign packages.
  plugins   Restore third-party plugins and enabled/disabled state.
  systemd   Restore and enable the backup service/timer.
  all       Run all stages in order.

This script never removes packages or plugins and never reboots the system.
USAGE
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

verify_environment() {
    printf '\n===== ENVIRONMENT CHECK =====\n'

    need_cmd git
    need_cmd pacman
    need_cmd omarchy
    need_cmd rsync
    need_cmd systemctl

    [[ -f "$REPO_DIR/packages/explicit.txt" ]] ||
        die "Missing packages/explicit.txt"

    [[ -f "$REPO_DIR/packages/foreign.txt" ]] ||
        die "Missing packages/foreign.txt"

    [[ -f "$REPO_DIR/plugins.txt" ]] ||
        die "Missing plugins.txt"

    [[ -d "$REPO_DIR/config" ]] ||
        die "Missing config directory"

    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        printf 'OS:         %s\n' "${PRETTY_NAME:-unknown}"
    fi

    if command -v omarchy >/dev/null 2>&1; then
        printf 'Omarchy:    detected\n'
    fi

    printf 'Repository: %s\n' "$REPO_DIR"
    printf 'Safety dir: %s\n' "$SAFETY_DIR"
}

prepare_safety_dir() {
    mkdir -p "$SAFETY_DIR"
    chmod 700 "$SAFETY_DIR"

    printf 'Safety backup directory: %s\n' "$SAFETY_DIR"
}

backup_existing() {
    local src="$1"

    [[ -e "$src" || -L "$src" ]] || return 0

    local relative
    relative="${src#"$HOME_DIR"/}"

    mkdir -p "$SAFETY_DIR/$(dirname "$relative")"

    if [[ -d "$src" && ! -L "$src" ]]; then
        rsync -a "$src/" "$SAFETY_DIR/$relative/"
    else
        cp -a "$src" "$SAFETY_DIR/$relative"
    fi

    printf 'SAFETY %s\n' "$src"
}

restore_file() {
    local src="$1"
    local dst="$2"

    [[ -f "$src" ]] || {
        printf 'SKIP %s\n' "$src"
        return 0
    }

    backup_existing "$dst"

    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"

    printf 'RESTORED %s\n' "$dst"
}

restore_dir() {
    local src="$1"
    local dst="$2"

    [[ -d "$src" ]] || {
        printf 'SKIP %s/\n' "$src"
        return 0
    }

    backup_existing "$dst"

    rm -rf -- "$dst"
    mkdir -p "$dst"

    rsync -a \
        --exclude='*.bak' \
        --exclude='*.omasettings.bak' \
        --exclude='themes/current.theme' \
        --exclude='lua/plugins/theme.lua' \
        "$src/" "$dst/"

    printf 'RESTORED %s/\n' "$dst"
}

restore_configs() {
    printf '\n===== RESTORING CONFIGURATION =====\n'

    restore_file "$REPO_DIR/home/.bashrc" "$HOME_DIR/.bashrc"
    restore_file "$REPO_DIR/home/.XCompose" "$HOME_DIR/.XCompose"

    restore_file "$REPO_DIR/config/chromium-flags.conf" "$HOME_DIR/.config/chromium-flags.conf"
    restore_file "$REPO_DIR/config/mimeapps.list" "$HOME_DIR/.config/mimeapps.list"
    restore_file "$REPO_DIR/config/starship.toml" "$HOME_DIR/.config/starship.toml"

    restore_file "$REPO_DIR/config/alacritty/alacritty.toml" "$HOME_DIR/.config/alacritty/alacritty.toml"
    restore_file "$REPO_DIR/config/btop/btop.conf" "$HOME_DIR/.config/btop/btop.conf"
    restore_file "$REPO_DIR/config/foot/foot.ini" "$HOME_DIR/.config/foot/foot.ini"
    restore_file "$REPO_DIR/config/ghostty/config" "$HOME_DIR/.config/ghostty/config"
    restore_file "$REPO_DIR/config/kitty/kitty.conf" "$HOME_DIR/.config/kitty/kitty.conf"
    restore_file "$REPO_DIR/config/mise/config.toml" "$HOME_DIR/.config/mise/config.toml"
    restore_file "$REPO_DIR/config/sonora/settings.json" "$HOME_DIR/.config/sonora/settings.json"
    restore_file "$REPO_DIR/config/tmux/tmux.conf" "$HOME_DIR/.config/tmux/tmux.conf"
    restore_file "$REPO_DIR/config/voxtype/config.toml" "$HOME_DIR/.config/voxtype/config.toml"

    restore_dir "$REPO_DIR/config/hypr" "$HOME_DIR/.config/hypr"
    restore_dir "$REPO_DIR/config/nvim" "$HOME_DIR/.config/nvim"

    restore_file "$REPO_DIR/config/omarchy/omasettings.json" "$HOME_DIR/.config/omarchy/omasettings.json"
    restore_file "$REPO_DIR/config/omarchy/shell.toml" "$HOME_DIR/.config/omarchy/shell.toml"
    restore_file "$REPO_DIR/config/omarchy/shell.json" "$HOME_DIR/.config/omarchy/shell.json"
    restore_file "$REPO_DIR/config/omarchy/dock-settings.json" "$HOME_DIR/.config/omarchy/dock-settings.json"

    if [[ -f "$HOME_DIR/.config/omarchy/shell.json" ]]; then
        chmod 600 "$HOME_DIR/.config/omarchy/shell.json"
    fi

    restore_dir "$REPO_DIR/config/omarchy/themes/porshe-959" \
        "$HOME_DIR/.config/omarchy/themes/porshe-959"

    printf '\nConfiguration restore complete.\n'
}

restore_packages() {
    printf '\n===== RESTORING PACKAGES =====\n'

    need_cmd sudo
    need_cmd pacman

    local -a official_missing=()
    local -a foreign_missing=()
    local pkg

    while IFS= read -r pkg; do
        [[ -n "$pkg" && "$pkg" != \#* ]] || continue

        # Foreign/AUR packages are handled separately below.
        if grep -Fxq "$pkg" "$REPO_DIR/packages/foreign.txt"; then
            continue
        fi

        if ! pacman -Q "$pkg" >/dev/null 2>&1; then
            official_missing+=("$pkg")
        fi
    done < "$REPO_DIR/packages/explicit.txt"

    if ((${#official_missing[@]} > 0)); then
        printf '\nMissing official packages:\n'
        printf '  %s\n' "${official_missing[@]}"
        printf '\nInstalling missing official packages...\n'

        sudo pacman -S --needed "${official_missing[@]}"
    else
        printf 'All saved official packages are already installed.\n'
    fi

    while IFS= read -r pkg; do
        [[ -n "$pkg" && "$pkg" != \#* ]] || continue

        if ! pacman -Q "$pkg" >/dev/null 2>&1; then
            foreign_missing+=("$pkg")
        fi
    done < "$REPO_DIR/packages/foreign.txt"

    if ((${#foreign_missing[@]} > 0)); then
        printf '\nMissing foreign/AUR packages:\n'
        printf '  %s\n' "${foreign_missing[@]}"

        if ! command -v yay >/dev/null 2>&1; then
            printf '\nWARNING: yay is not installed.\n'
            printf 'Foreign/AUR packages were NOT installed.\n'
            printf 'Install yay, then rerun: ./restore.sh packages\n'
        else
            printf '\nInstalling missing foreign/AUR packages with yay...\n'
            yay -S --needed "${foreign_missing[@]}"
        fi
    else
        printf 'All saved foreign/AUR packages are already installed.\n'
    fi
}

restore_plugins() {
    printf '\n===== RESTORING PLUGINS =====\n'

    need_cmd omarchy

    local plugin_id
    local plugin_state
    local plugin_url
    local current_state

    while IFS=$'\t' read -r plugin_id plugin_state plugin_url; do
        [[ -n "$plugin_id" ]] || continue
        [[ "$plugin_id" == \#* ]] && continue
        [[ -n "$plugin_url" ]] || continue

        printf '\nPlugin: %s\n' "$plugin_id"
        printf 'State:  %s\n' "$plugin_state"
        printf 'Source: %s\n' "$plugin_url"

        current_state="$(
            omarchy plugin list 2>/dev/null |
            awk -v id="$plugin_id" '$1 == id {print $2; exit}' || true
        )"

        if [[ -z "$current_state" ]]; then
            printf 'Installing plugin...\n'
            omarchy plugin add "$plugin_url" --yes

            current_state="$(
                omarchy plugin list 2>/dev/null |
                awk -v id="$plugin_id" '$1 == id {print $2; exit}' || true
            )"
        else
            printf 'Already installed (%s).\n' "$current_state"
        fi

        case "$plugin_state" in
            enabled)
                if [[ "$current_state" == "enabled" ]]; then
                    printf 'Already enabled.\n'
                else
                    omarchy plugin enable "$plugin_id"
                fi
                ;;
            disabled)
                if [[ "$current_state" == "disabled" ]]; then
                    printf 'Already disabled.\n'
                else
                    omarchy plugin disable "$plugin_id"
                fi
                ;;
            *)
                printf 'WARNING: Unknown state "%s"; leaving plugin state unchanged.\n' "$plugin_state"
                ;;
        esac
    done < "$REPO_DIR/plugins.txt"

    printf '\nPlugin restore complete.\n'
}

restore_systemd() {
    printf '\n===== RESTORING SYSTEMD BACKUP TIMER =====\n'

    restore_file \
        "$REPO_DIR/config/systemd/user/omarchy-backup.service" \
        "$HOME_DIR/.config/systemd/user/omarchy-backup.service"

    restore_file \
        "$REPO_DIR/config/systemd/user/omarchy-backup.timer" \
        "$HOME_DIR/.config/systemd/user/omarchy-backup.timer"

    systemctl --user daemon-reload
    systemctl --user enable --now omarchy-backup.timer

    printf '\nTimer status:\n'
    systemctl --user status omarchy-backup.timer --no-pager --lines=8

    printf '\nSystemd restore complete.\n'
}

main() {
    cd "$REPO_DIR"

    case "${1:-}" in
        prepare)
            verify_environment
            prepare_safety_dir
            ;;
        configs)
            verify_environment
            prepare_safety_dir
            restore_configs
            ;;
        packages)
            verify_environment
            prepare_safety_dir
            restore_packages
            ;;
        plugins)
            verify_environment
            prepare_safety_dir
            restore_plugins
            ;;
        systemd)
            verify_environment
            prepare_safety_dir
            restore_systemd
            ;;
        all)
            verify_environment
            prepare_safety_dir
            restore_configs
            restore_packages
            restore_plugins
            restore_systemd
            printf '\n===== RESTORE COMPLETE =====\n'
            printf 'Safety backup: %s\n' "$SAFETY_DIR"
            printf 'No reboot or session restart was performed.\n'
            ;;
        *)
            usage
            exit 2
            ;;
    esac
}

main "$@"
