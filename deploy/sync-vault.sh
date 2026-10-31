#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
docker compose -f docker-compose.prod.yml exec -T backend python manage.py sync_vault --embed
