#!/bin/bash

set -e

#set env variables from .env file
set -a
source .env
set +a

DB_CONTAINER="dj-mariadb"
DB_NAME="$MYSQL_DATABASE"
DB_USER="root"
DB_PASS="$MYSQL_ROOT_PASSWORD"

BACKUP_DIR="./backups"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +"%Y%m%d-%H%M")
BACKUP_FILE="$BACKUP_DIR/domjudge-backup-$TIMESTAMP.sql"

echo "[backup-db] Creating backup of database '$DB_NAME' from container '$DB_CONTAINER' using root..."

docker exec "$DB_CONTAINER" \
  sh -c "exec mysqldump -u$DB_USER -p$DB_PASS $DB_NAME" > "$BACKUP_FILE"

echo "[backup-db] Backup saved to: $BACKUP_FILE"
