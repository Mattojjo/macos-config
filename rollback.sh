#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

usage() {
  echo "Usage: $0 [-l] [-r <backup_dir>] [-y]"
  echo "  -l           List available backups"
  echo "  -r <dir>     Restore from backup directory"
  echo "  -y           Non-interactive (assume yes)"
  exit 1
}

LIST=false
RESTORE_DIR=""
AUTO_YES=false

while getopts ":lr:y" opt; do
  case $opt in
    l) LIST=true ;;
    r) RESTORE_DIR="$OPTARG" ;;
    y) AUTO_YES=true ;;
    *) usage ;;
  esac
done
shift $((OPTIND -1))

BACKUP_ROOT="$HOME/.config"

if $LIST; then
  echo "Available backups in $BACKUP_ROOT:"
  ls -1d "$BACKUP_ROOT"/backup_* 2>/dev/null || echo "  (none)"
  exit 0
fi

if [ -z "$RESTORE_DIR" ]; then
  if [ $# -ge 1 ]; then
    RESTORE_DIR="$1"
  else
    echo "No backup specified. Use -l to list backups or provide a path to restore.";
    usage
  fi
fi

if [ ! -d "$RESTORE_DIR" ]; then
  echo "Backup directory not found: $RESTORE_DIR"; exit 1
fi

if [ "$AUTO_YES" = false ]; then
  echo -n "Restore backup $RESTORE_DIR to ~/.config/? (y/N) "
  read -r reply
  echo
  if [[ ! $reply =~ ^[Yy]$ ]]; then
    echo "Cancelled."; exit 0
  fi
fi

# Perform restore using rsync if available
if command -v rsync >/dev/null 2>&1; then
  rsync -a --delete "$RESTORE_DIR/" "$HOME/.config/"
else
  cp -a "$RESTORE_DIR/." "$HOME/.config/"
fi

echo "Restore complete from $RESTORE_DIR"