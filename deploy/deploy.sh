#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."
COMPOSE="docker compose -f docker-compose.prod.yml"

git pull --ff-only
$COMPOSE build
$COMPOSE up -d --remove-orphans
$COMPOSE ps
docker image prune -f >/dev/null
