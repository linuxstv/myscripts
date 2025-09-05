#!/bin/bash

# === Konfigurasi Umum ===
DB_USER="mariadbuser"
DB_PASS="mariadbpass"
BACKUP_DIR="/tmp/dbbackup"
DATE=$(date +%Y%m%d_%H%M%S)
LOGFILE="/home/uservps/log/dbbackup.log"

REMOTE_USER="userbackupserver"
REMOTE_HOST="10.8.0.83"
REMOTE_PATH="/home/userbackupserver/backups"

# === Daftar Database ===
DATABASES=("dbname1" "dbname2" "dbnameetc")

# === Persiapan ===
mkdir -p $BACKUP_DIR

# === Mulai Log ===
exec >> "$LOGFILE" 2>&1
echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Backup Started ==="

for DB in "${DATABASES[@]}"; do
  BACKUP_FILE="${BACKUP_DIR}/${DB}-${DATE}.sql.gz"
  echo "Backup $DB..."
  mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB" | gzip > "$BACKUP_FILE"

  echo "Upload ke client $REMOTE_HOST..."
  scp "$BACKUP_FILE" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_PATH}/"

  if [ $? -eq 0 ]; then
    echo "Upload sukses $DB"
    rm -f "$BACKUP_FILE"
  else
    echo "Upload gagal untuk $DB"
  fi

  echo
done

echo "=== [$(date '+%Y-%m-%d %H:%M:%S')] Backup Finished ==="
echo
