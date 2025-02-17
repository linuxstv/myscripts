#!/bin/bash

# MySQL database backup script

# Define MySQL credentials
DB_HOST="192.168.1.25"
DB_USER="dbuser"
DB_PASSWORD="dbpass"

# Define database names
declare -A DATABASES
DATABASES[1]="dbname1"
DATABASES[2]="dbname2"
DATABASES[3]="dbname3"

# Define backup directory
YEAR=$(date +"%Y")
BACKUP_DIR="$(pwd)/${YEAR}_backup"
mkdir -p "$BACKUP_DIR"
echo "Backup directory is set to: $BACKUP_DIR"

# Menampilkan daftar pilihan database
echo "Pilih database yang akan dibackup (pisahkan dengan spasi jika lebih dari satu):"
for i in "${!DATABASES[@]}"; do
    echo "$i) ${DATABASES[$i]}"
done
echo "0) Semua database"

# Meminta input dari pengguna
read -p "Masukkan angka database yang ingin dibackup: " -a CHOICES

# Mendapatkan timestamp
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Fungsi untuk membackup database
backup_db() {
    local DB_NAME="$1"
    local BACKUP_FILE="$BACKUP_DIR/${DB_NAME}-$TIMESTAMP.sql"

    mysqldump -h "$DB_HOST" -u"$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_FILE"

    if [ $? -eq 0 ]; then
        echo "File berhasil dibackup: $BACKUP_FILE"
    else
        echo "File gagal dibackup: $DB_NAME"
    fi
}

# Fungsi untuk menghapus file backup lama, menyisakan 2 terbaru
delete_oldest_files() {
    local prefix="$1"
    local files_to_delete

    files_to_delete=$(find "$BACKUP_DIR" -type f -name "${prefix}*.sql" -exec stat -c "%Y %n" {} + | sort -n | head -n -2 | awk '{print $2}')
    
    if [[ -n "$files_to_delete" ]]; then
        echo "$files_to_delete" | xargs rm -f
        echo "File backup lama untuk $prefix telah dihapus, menyisakan 2 terbaru."
    fi
}

# Mengeksekusi backup sesuai pilihan pengguna
for CHOICE in "${CHOICES[@]}"; do
    if [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
        if [ "$CHOICE" -eq 0 ]; then
            # Backup semua database
            for DB in "${DATABASES[@]}"; do
                backup_db "$DB"
                delete_oldest_files "$DB"
            done
            break # Keluar dari loop karena semua database sudah dibackup
        elif [[ -n "${DATABASES[$CHOICE]}" ]]; then
            # Backup hanya database yang dipilih
            backup_db "${DATABASES[$CHOICE]}"
            delete_oldest_files "${DATABASES[$CHOICE]}"
        else
            echo "Pilihan $CHOICE tidak valid!"
        fi
    else
        echo "Input harus berupa angka!"
    fi
done
