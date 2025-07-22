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

#check if backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
  echo "[restore-db] Backup directory not found at $BACKUP_DIR"
  exit 1
fi

#find all .sql backup files
mapfile -t BACKUP_FILES < <(find "$BACKUP_DIR" -name "*.sql" | sort)

if [ ${#BACKUP_FILES[@]} -eq 0 ]; then
  echo "[restore-db] No .sql backup files found in $BACKUP_DIR"
  exit 1
fi

#show list of available backups
echo "Available backups:"
for i in "${!BACKUP_FILES[@]}"; do
  echo "[$i] ${BACKUP_FILES[$i]}"
done

echo
read -p "Choose a backup number to restore: " SELECTION

#validate user selection
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 0 ] || [ "$SELECTION" -ge "${#BACKUP_FILES[@]}" ]; then
  echo "[restore-db] Invalid selection."
  exit 1
fi

SELECTED_FILE="${BACKUP_FILES[$SELECTION]}"
echo
read -p "Are you sure you want to restore '$SELECTED_FILE' to database '$DB_NAME'? This will overwrite current data. (yes/no): " CONFIRM

if [[ "$CONFIRM" != "yes" ]]; then
  echo "[restore-db] Restore canceled."
  exit 0
fi

echo "[restore-db] Restoring database from: $SELECTED_FILE..."

#execute restore command inside the database container
docker exec -i "$DB_CONTAINER" sh -c "exec mysql -u$DB_USER -p$DB_PASS $DB_NAME" < "$SELECTED_FILE"

echo "[restore-db] Restore completed successfully."
