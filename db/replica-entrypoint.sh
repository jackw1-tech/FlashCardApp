#!/bin/sh
set -eu

if [ ! -s "$PGDATA/PG_VERSION" ]; then
  echo "Attendo il primary..."

  until pg_isready -h "$PRIMARY_HOST" -p 5432; do
    sleep 1
  done

  echo "Creo la replica dal base backup..."

  PGPASSWORD="$POSTGRES_REPLICATION_PASSWORD" pg_basebackup \
    --host="$PRIMARY_HOST" \
    --port=5432 \
    --username="$POSTGRES_REPLICATION_USER" \
    --pgdata="$PGDATA" \
    --format=plain \
    --wal-method=stream \
    --write-recovery-conf \
    --slot="$POSTGRES_REPLICATION_SLOT" \
    --progress
fi
chmod 0700 "$PGDATA"
echo "Avvio PostgreSQL come standby..."

exec postgres \
  -c hot_standby=on \
  -c recovery_min_apply_delay="${REPLICA_APPLY_DELAY:-0}" \
  -c shared_buffers=64MB \
  -c max_connections=20 \
  -c work_mem=4MB
