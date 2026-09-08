# Omarchy Backup & Restore

This repository contains a reproducible backup of an Omarchy installation, including user configuration, package selections, third-party plugins, custom themes, and the automated GitHub backup timer.

## Restore on a Fresh Omarchy Installation

### 1. Clone the repository

```bash
git clone git@github.com:nikhilmaity00/arch-btw.git ~/omarchy-backup
cd ~/omarchy-backup
```

### 2. Verify the restore environment

Run:

```bash
./restore.sh prepare
```

This verifies that the required commands and repository data are available and creates a private safety-backup directory.

### 3. Restore everything

When you are deliberately ready to restore the configuration:

```bash
./restore.sh all --confirm
```

The `--confirm` flag is required intentionally to prevent accidental full restores.

## Restore Stages

Individual stages can also be run separately:

```bash
./restore.sh configs
./restore.sh packages
./restore.sh plugins
./restore.sh systemd
```

### Configuration

Restores selected user configuration files, Hyprland, Neovim, Omarchy settings, and the custom `porshe-959` theme.

Before replacing an existing file or directory, the restore script creates a safety copy under:

```text
~/omarchy-restore-safety/<timestamp>/
```

Generated Omarchy theme symlinks and backup files are intentionally excluded.

### Packages

The package restore installs only packages that are missing.

Official packages are installed with `pacman`.

Foreign/AUR packages are handled separately with `yay`.

Packages are not removed by the restore script.

Package versions are not pinned; the repository records the package set rather than an exact historical package snapshot.

### Plugins

Third-party Omarchy plugins are restored from their recorded Git repositories.

The saved enabled/disabled state is restored.

Omarchy's built-in plugins are not recorded because they are expected to be provided by the Omarchy installation itself.

### Systemd Backup Timer

The restore installs:

```text
~/.config/systemd/user/omarchy-backup.service
~/.config/systemd/user/omarchy-backup.timer
```

The timer is enabled and started automatically by the `systemd` stage.

The backup runs every 30 minutes after the initial boot delay.

## Safety

The restore script:

- Does not remove packages.
- Does not remove plugins.
- Does not reboot the machine.
- Requires `--confirm` for a full restore.
- Creates safety backups before replacing existing configuration.
- Restricts destructive directory replacement to paths underneath `~/.config`.
- Excludes generated Omarchy theme symlinks and backup files.

## Validation

The restore workflow was tested on Omarchy before being committed.

Validated components:

- Environment detection
- Safety directory creation
- Full-restore confirmation guard
- Destructive-path guard
- Shell syntax
- Configuration restoration
- Generated-file/symlink exclusions
- `shell.json` permissions
- Official package detection
- AUR package detection
- Third-party plugin detection and state
- Systemd service configuration
- Systemd timer configuration and active state

The validated restore script is tracked in Git.

## Repository Location

GitHub:

```text
git@github.com:nikhilmaity00/arch-btw.git
```

Default branch:

```text
master
```