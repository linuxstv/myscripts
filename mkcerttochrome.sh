#!/bin/bash
# Pastikan libnss3-tools sudah terinstall
if ! command -v certutil &> /dev/null; then
    echo "Install libnss3-tools terlebih dahulu: sudo apt install libnss3-tools"
    exit 1
fi

# Lokasi NSS database Chrome per user
NSSDB="$HOME/.pki/nssdb"

mkdir -p "$NSSDB"

# Cari semua rootCA.pem mkcert di folder user
MKCERT_ROOTS=(
    "$HOME/.local/share/mkcert/rootCA.pem"
    "$HOME/.local/share/mkcert/rootCA-key.pem"  # hanya untuk referensi, tidak digunakan
)

for ROOT in "${MKCERT_ROOTS[@]}"; do
    if [ -f "$ROOT" ]; then
        NAME=$(openssl x509 -noout -subject -in "$ROOT" | sed 's/subject= //')
        echo "Menambahkan $NAME ke NSS database Chrome..."
        certutil -d sql:"$NSSDB" -A -t "CT,C,C" -n "$NAME" -i "$ROOT"
    fi
done

echo "Selesai! Restart Chrome untuk melihat perubahan."
