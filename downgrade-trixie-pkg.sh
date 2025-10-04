#!/bin/bash
# downgrade-trixie-pkg.sh
# Downgrade semua paket /now ke versi Trixie otomatis, dengan opsi dry-run

LOGFILE="$HOME/downgrade-trixie-$(date +%Y%m%d-%H%M%S).log"
echo "=== Downgrade Trixie Local Packages /now $(date +"%a %d %b %Y %H:%M:%S %Z") ===" | tee -a "$LOGFILE"

DRYRUN=0
if [ "$1" == "--dry-run" ]; then
    DRYRUN=1
    echo "=== MODE DRY-RUN: Tidak akan mengeksekusi apt-get ===" | tee -a "$LOGFILE"
fi

# 1. Ambil daftar paket /now
packages=$(apt list --installed 2>/dev/null | grep '/now' | cut -d/ -f1)

if [ -z "$packages" ]; then
    echo "Tidak ada paket /now untuk didowngrade." | tee -a "$LOGFILE"
    exit 0
fi

declare -A pkg_versions

# 2. Ambil versi Trixie yang cocok untuk downgrade
for pkg in $packages; do
    # ambil semua versi
    while read -r ver_line; do
        ver=$(echo "$ver_line" | awk '{print $1}')
        # baca baris berikutnya untuk repo
        read -r repo_line
        if echo "$repo_line" | grep -q 'trixie'; then
            pkg_versions["$pkg"]="$ver"
            break
        fi
    done < <(apt-cache policy "$pkg" | grep -E '^[[:space:]]*[0-9]+\.[0-9]+' -A1)
done

if [ ${#pkg_versions[@]} -eq 0 ]; then
    echo "Tidak ada versi Trixie yang tersedia untuk paket /now." | tee -a "$LOGFILE"
    exit 0
fi

# 3. Tampilkan paket yang akan didowngrade
echo "=== Paket yang akan didowngrade ===" | tee -a "$LOGFILE"
for pkg in "${!pkg_versions[@]}"; do
    echo "$pkg=${pkg_versions[$pkg]}" | tee -a "$LOGFILE"
done

# 4. Eksekusi downgrade jika bukan dry-run
if [ $DRYRUN -eq 0 ]; then
    echo "=== Mengeksekusi downgrade semua paket... ===" | tee -a "$LOGFILE"
    args=()
    for pkg in "${!pkg_versions[@]}"; do
        args+=("$pkg=${pkg_versions[$pkg]}")
    done
    sudo apt-get install --allow-downgrades -y "${args[@]}" | tee -a "$LOGFILE"
else
    echo "=== Dry-run selesai. Tidak ada paket yang diinstal. ===" | tee -a "$LOGFILE"
fi

echo "=== Selesai ===" | tee -a "$LOGFILE"
echo "Log tersimpan di: $LOGFILE"
