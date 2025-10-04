#!/bin/bash
# downgrade-trixie-pkg.sh
# Downgrade semua paket /now ke versi Trixie otomatis
# Dry-run dulu, lalu eksekusi jika dikonfirmasi

LOGFILE="$HOME/downgrade-trixie-$(date +%Y%m%d-%H%M%S).log"
echo "=== Downgrade Trixie Local Packages /now $(date +"%a %d %b %Y %H:%M:%S %Z") ===" | tee -a "$LOGFILE"

# 1. Ambil daftar paket yang statusnya /now
packages=$(apt list --installed 2>/dev/null | grep '/now' | cut -d/ -f1)

if [ -z "$packages" ]; then
    echo "Tidak ada paket /now untuk didowngrade." | tee -a "$LOGFILE"
    exit 0
fi

declare -A pkg_versions

# 2. Ambil versi Trixie untuk masing-masing paket
for pkg in $packages; do
    # Ambil versi yang memiliki repo trixie
    trixie_ver=$(apt-cache policy "$pkg" | awk '/https:\/\/deb.debian.org\/debian.*trixie/ {print prev} {prev=$1}')
    if [ -n "$trixie_ver" ]; then
        pkg_versions["$pkg"]="$trixie_ver"
    else
        echo "Paket $pkg: versi Trixie tidak ditemukan, dilewati." | tee -a "$LOGFILE"
    fi
done

if [ ${#pkg_versions[@]} -eq 0 ]; then
    echo "Tidak ada paket /now dengan versi Trixie, tidak ada yang akan didowngrade." | tee -a "$LOGFILE"
    exit 0
fi

# 3. Tampilkan paket yang akan didowngrade (dry-run)
echo "=== Paket yang akan didowngrade (dry-run) ===" | tee -a "$LOGFILE"
for pkg in "${!pkg_versions[@]}"; do
    echo "$pkg=${pkg_versions[$pkg]}" | tee -a "$LOGFILE"
done

# 4. Tanya user apakah mau eksekusi
read -p "Dry-run selesai. Apakah Anda ingin mengeksekusi downgrade sekarang? (y/N) " yn
if [[ "$yn" =~ ^[Yy]$ ]]; then
    echo "=== Mengeksekusi downgrade semua paket... ===" | tee -a "$LOGFILE"
    args=()
    for pkg in "${!pkg_versions[@]}"; do
        args+=("$pkg=${pkg_versions[$pkg]}")
    done
    sudo apt-get install --allow-downgrades -y "${args[@]}" | tee -a "$LOGFILE"
    echo "=== Selesai ===" | tee -a "$LOGFILE"
else
    echo "Eksekusi dibatalkan oleh pengguna." | tee -a "$LOGFILE"
fi

echo "Log tersimpan di: $LOGFILE"
