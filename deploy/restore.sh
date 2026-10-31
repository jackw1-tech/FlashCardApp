#!/usr/bin/env bash
set -euo pipefail

file="${1:?uso: deploy/restore.sh <backup.sql.gz>}"
cd "$(dirname "$0")/.."
set -a
. ./.env
set +a
COMPOSE="docker compose -f docker-compose.prod.yml"

read -r -p "Sovrascrivere il database $POSTGRES_DB con $file? [s/N] " answer
[ "$answer" = "s" ] || exit 1

$COMPOSE stop backend mcp
$COMPOSE exec -T db psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1 \
  -c "drop database if exists \"$POSTGRES_DB\" with (force)" \
  -c "create database \"$POSTGRES_DB\" owner \"$POSTGRES_USER\""
gunzip -c "$file" | $COMPOSE exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -v ON_ERROR_STOP=1 -q
$COMPOSE up -d backend mcp
echo "ripristino completato"
