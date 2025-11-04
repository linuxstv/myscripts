#!/bin/bash
# resizegab.sh - Mode A (temp folders kept)
# Potong US Letter (ambil atas), gabung 2-per-A4 (atas-bawah), jika ganjil gunakan empty slot.
# Tambahan: shrink/scale saat packing ke A4 untuk menghindari teks kepotong.

##############
# Konfigurasi
##############
CROP_HEIGHT="139.7mm"      # tinggi bagian yang diambil (setengah US Letter)
MARGIN_TOP="15mm"          # geser isi ke atas jika perlu
MARGIN_LEFT="5mm"          # margin kiri
MARGIN_RIGHT="5mm"         # margin kanan
SCALE_A4="0.98"            # skala saat menempatkan ke A4 (0.98 = 98%). Turunkan jika masih kepotong.

##############
# Temp folders
##############
CROP_DIR="temp_crop"
A4_DIR="temp_a4"
FINAL="resized-gab.pdf"

mkdir -p "$CROP_DIR" "$A4_DIR"

##############
# Buat empty.pdf (A5 kosong) di folder temp_crop
##############
EMPTY_PDF="$CROP_DIR/empty.pdf"
if [ ! -f "$EMPTY_PDF" ]; then
    # buat empty PDF berukuran A5-ish (setengah US Letter)
    # Kita gunakan pdfjam untuk membuat halaman kosong ukuran CROP_HEIGHT x 215.9mm
    pdfjam --papersize "{215.9mm,$CROP_HEIGHT}" --outfile "$EMPTY_PDF" < /dev/null 2>/dev/null || {
        # fallback sederhana: tulis header PDF minimal (may work)
        printf "%%PDF-1.1\n1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 215.9 139.7] >> endobj\nxref\n0 4\n0000000000 65535 f \n0000000010 00000 n \n0000000060 00000 n \n0000000120 00000 n \ntrailer << /Root 1 0 R >>\nstartxref\n180\n%%EOF\n" > "$EMPTY_PDF"
    }
fi

##############
# Langkah 1: potong bagian atas (ambil CROP_HEIGHT) dari tiap PDF di folder kerja
##############
echo "🔪 Memotong bagian atas tiap PDF (ambil $CROP_HEIGHT)..."
i=0
shopt -s nullglob
for pdf in *.pdf; do
    # hindari memproses file hasil akhir jika rerun
    if [ "$pdf" = "$FINAL" ]; then
        continue
    fi
    out="$CROP_DIR/$(printf "%03d" $i)_crop.pdf"
    echo "  - $pdf -> $out"
    # trim: kiri top right bottom => kita trim bagian bawah (yaitu CROP_HEIGHT dari bawah)
    # pdfjam --trim takes: left bottom right top (some versions differ), we used consistent earlier.
    # Here we crop to top by trimming bottom to CROP_HEIGHT.
    pdfjam "$pdf" --trim "0 $CROP_HEIGHT 0 0" --clip true --papersize "{215.9mm,$CROP_HEIGHT}" --outfile "$out" 2>/dev/null
    if [ ! -f "$out" ]; then
        echo "    ⚠️ Warning: pdfjam gagal membuat $out — coba ulang atau cek file."
    fi
    i=$((i+1))
done

##############
# Langkah 2: gabungkan tiap 2 crop menjadi 1 A4 (atas-bawah), gunakan SCALE_A4 untuk mencegah clipping
##############
echo "📐 Menggabungkan tiap 2 crop menjadi halaman A4 (1x2)..."
files=( "$CROP_DIR"/*.pdf )
count=${#files[@]}
idx=0
a4idx=0

while [ $idx -lt $count ]; do
    f1="${files[$idx]}"
    if [ $((idx+1)) -lt $count ]; then
        f2="${files[$((idx+1))]}"
    else
        f2="$EMPTY_PDF"
    fi

    outa4="$A4_DIR/$(printf "%03d" $a4idx)_A4.pdf"
    echo "  - Pair: $f1 + $f2 -> $outa4 (scale=$SCALE_A4)"
    # nup 1x2 = 1 column x 2 rows (atas-bawah)
    # gunakan --scale untuk mengecilkan sedikit agar tidak kepotong
    pdfjam "$f1" "$f2" --nup 1x2 \
        --papersize "{210mm,297mm}" \
        --scale "$SCALE_A4" \
        --offset "${MARGIN_LEFT} ${MARGIN_TOP}" \
        --delta "${MARGIN_RIGHT} 0mm" \
        --outfile "$outa4" 2>/dev/null

    if [ ! -f "$outa4" ]; then
        echo "    ⚠️ Warning: gagal membuat $outa4"
    fi

    idx=$((idx+2))
    a4idx=$((a4idx+1))
done

##############
# Langkah 3: gabungkan semua A4 menjadi satu file final
##############
echo "📚 Menggabungkan ${a4idx} file A4 menjadi $FINAL..."
pdfjam "$A4_DIR"/*.pdf --outfile "$FINAL" 2>/dev/null

if [ -f "$FINAL" ]; then
    echo "✅ Selesai. File final: $FINAL"
else
    echo "❌ Gagal membuat $FINAL — cek error di stdout/stderr"
fi

#echo "✳️ File sementara ada di: $CROP_DIR/ dan $A4_DIR/ (tidak dihapus)."

##############################################
# Langkah 4: Hapus folder sementara (jika sukses)
##############################################
if [ -f "$FINAL" ]; then
    echo "🧹 Menghapus folder sementara..."
    rm -rf "$CROP_DIR" "$A4_DIR"
    echo "✅ Folder sementara dihapus."
else
    echo "⚠️ File final tidak ditemukan, folder sementara TIDAK dihapus."
fi
