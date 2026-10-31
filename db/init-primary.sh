#!/bin/sh
set -eu

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v repl_user="$POSTGRES_REPLICATION_USER" \
  -v repl_password="$POSTGRES_REPLICATION_PASSWORD" \
  -v repl_slot="$POSTGRES_REPLICATION_SLOT" <<'SQL'
CREATE ROLE :"repl_user" WITH REPLICATION LOGIN PASSWORD :'repl_password';
SELECT pg_create_physical_replication_slot(:'repl_slot');
SQL

echo "host replication $POSTGRES_REPLICATION_USER all scram-sha-256" >> "$PGDATA/pg_hba.conf"
