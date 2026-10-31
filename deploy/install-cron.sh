#!/usr/bin/env bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "eseguilo con sudo" >&2
  exit 1
fi

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_USER="${SUDO_USER:-root}"
BACKUP_DIR="$(. "$APP_DIR/.env" && echo "${BACKUP_DIR:-/var/backups/flashcardapp}")"

mkdir -p "$BACKUP_DIR"
chown "$APP_USER" "$BACKUP_DIR"
touch /var/log/flashcardapp-backup.log /var/log/flashcardapp-sync.log
chown "$APP_USER" /var/log/flashcardapp-backup.log /var/log/flashcardapp-sync.log

cat > /etc/cron.d/flashcardapp <<CRON
30 3 * * * $APP_USER $APP_DIR/deploy/backup.sh >> /var/log/flashcardapp-backup.log 2>&1
0 * * * * $APP_USER $APP_DIR/deploy/sync-vault.sh >> /var/log/flashcardapp-sync.log 2>&1
CRON

echo "cron installato in /etc/cron.d/flashcardapp"
