#!/bin/bash

ROOT_DIR=$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.." && pwd)
CONFIG_DIR="$ROOT_DIR/compose"
MIGRATION_FILE="$CONFIG_DIR/pg/migration.sql"
PG_CONTAINER_NAME="pg"

COMMAND=$1
shift

case "$COMMAND" in
  recreate)
    echo "Recreating the PostgreSQL data volume..."
    $ROOT_DIR/holi-dev.sh compose down pg
    docker volume rm holi-dev_pg_data
    $ROOT_DIR/holi-dev.sh compose up -d pg
    ;;
  connect)
    echo "Connecting to PostgreSQL instance..."
    $ROOT_DIR/holi-dev.sh compose exec -it pg psql -U postgres -d postgres
    ;;
  "" | *.sql)
    # Handle migration with optional file name
    if [[ "$COMMAND" == *.sql ]]; then
      MIGRATION_FILE="$COMMAND"
    fi

    # Check that the migration file exists and is not empty
    if [[ ! -s "$MIGRATION_FILE" ]]; then
      echo "Error: \"$MIGRATION_FILE\" is empty or does not exist." >&2
      exit 1
    fi

    # Check that the PostgreSQL container is running
    if ! $ROOT_DIR/holi-dev.sh compose ps --format '{{.Names}}' | grep -qx "$PG_CONTAINER_NAME"; then
      echo "Error: PostgreSQL container \"$PG_CONTAINER_NAME\" is not running." >&2
      exit 1
    fi

    # Copies the migration file to the pg container and executes it
    $ROOT_DIR/holi-dev.sh compose cp $MIGRATION_FILE pg:/tmp/pg-migration.sql && \
      $ROOT_DIR/holi-dev.sh compose exec -i pg psql -U postgres -d postgres -f /tmp/pg-migration.sql
    ;;
  *)
    echo "Usage: migrate recreate|connect|[<file.sql>]" >&2
    exit 1
    ;;
esac