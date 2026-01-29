#!/bin/bash
# restore_script.sh

# Exit on error
set -e

# Check if backup file was provided
if [ -z "$1" ]; then
    echo "Usage: ./restore_skyportal.sh ./backups/skyportal_backup_TIMESTAMP.tar.gz"
    exit 1
fi

BACKUP_FILE=$1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMP_DIR="$SCRIPT_DIR/restore_temp"
PGDATA_PATH="$SCRIPT_DIR/data/dbdata/pgdata"

# Function to clear ACLs (matching your backup script logic)
cleanup_acls() {
    if [[ -d "$PGDATA_PATH" ]]; then
        echo "🧹 Cleaning up ACLs on $PGDATA_PATH..."
        sudo setfacl -R -b "$PGDATA_PATH"
    fi
}
trap cleanup_acls EXIT

echo "Preparing to restore from $BACKUP_FILE..."

# 1. Unpack the backup
mkdir -p "$TEMP_DIR"
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR" --strip-components=1

# 2. Stop the containers to prevent file corruption during file swap
echo "Stopping SkyPortal services..."
docker-compose stop

# 3. Restore Local Config and Raw Data
echo "Restoring config files..."
rm -rf "$SCRIPT_DIR/config"
cp -r "$TEMP_DIR/config_backup" "$SCRIPT_DIR/config"

echo "Restoring raw dbdata files..."
rm -rf "$SCRIPT_DIR/data/dbdata"
mkdir -p "$SCRIPT_DIR/data"
cp -r "$TEMP_DIR/dbdata_raw" "$SCRIPT_DIR/data/dbdata"

# 4. Handle Permissions (Matching your backup script setup)
echo "Applying ACLs to $PGDATA_PATH..."
sudo setfacl -R -m u:turbo:rwX,m:rwX "$PGDATA_PATH"

# 5. Restore Named Volumes (thumbnails & persistentdata)
echo "Restoring thumbnails volume..."
docker run --rm \
  -v thumbnails:/volume \
  -v "$TEMP_DIR":/backup \
  alpine sh -c "rm -rf /volume/* && tar -xzf /backup/thumbnails.tar.gz -C /volume"

echo "Restoring persistentdata volume..."
docker run --rm \
  -v persistentdata:/volume \
  -v "$TEMP_DIR":/backup \
  alpine sh -c "rm -rf /volume/* && tar -xzf /backup/persistentdata.tar.gz -C /volume"

# 6. Start the DB container to perform the SQL restore
echo "Starting database for SQL restoration..."
docker-compose up -d db
echo "Waiting for database to be ready..."
sleep 10 # Give Postgres a moment to initialize

# 7. SQL Restore (Logical Dump)
echo "Re-importing SQL dump..."
# Drop and recreate the public schema to ensure a clean slate
docker exec -i postgres14.4 psql -U skyportal -d skyportal -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;"
docker exec -i postgres14.4 psql -U skyportal -d skyportal < "$TEMP_DIR/db_dump.sql"

# 8. Finalize and Restart Everything
echo "Restarting all services..."
docker-compose up -d
rm -rf "$TEMP_DIR"

echo "Restore complete! SkyPortal is running."