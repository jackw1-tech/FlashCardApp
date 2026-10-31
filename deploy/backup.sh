#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
set -a
. ./.env
set +a

BACKUP_DIR="${BACKUP_DIR:-/var/backups/flashcardapp}"
BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-14}"
COMPOSE="docker compose -f docker-compose.prod.yml"

mkdir -p "$BACKUP_DIR"
file="$BACKUP_DIR/flashcards-$(date -u +%Y%m%dT%H%M%SZ).sql.gz"

$COMPOSE exec -T db pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" --format=plain --no-owner | gzip -9 > "$file.tmp"
mv "$file.tmp" "$file"

find "$BACKUP_DIR" -name 'flashcards-*.sql.gz' -mtime +"$BACKUP_KEEP_DAYS" -delete

if [ -n "${BACKUP_RCLONE_REMOTE:-}" ]; then
  rclone copy "$file" "$BACKUP_RCLONE_REMOTE"
  rclone delete --min-age "${BACKUP_KEEP_DAYS}d" "$BACKUP_RCLONE_REMOTE"
fi

echo "backup: $file"
