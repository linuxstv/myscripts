#!/bin/bash
# resizegab.sh - Memotong US Letter (ambil setengah atas), lalu gabung 2-per-A4.
# Tidak menambah halaman kosong jika jumlah file genap.

##############
# Konfigurasi
##############
CROP_HEIGHT="139.7mm"      # tinggi crop (setengah US Letter)
MARGIN_TOP="15mm"          # margin atas pada A4
MARGIN_LEFT="5mm"
MARGIN_RIGHT="5mm"
SCALE_A4="0.98"            # skala untuk mencegah clipping

##############
# Temp folders
##############
CROP_DIR="temp_crop"
A4_DIR="temp_a4"
FINAL="resized-gab.pdf"

mkdir -p "$CROP_DIR" "$A4_DIR"

##############
# Buat empty.pdf untuk pasangan ganjil
##############
EMPTY_PDF="$CROP_DIR/empty.pdf"
if [ ! -f "$EMPTY_PDF" ]; then
    pdfjam --papersize "{215.9mm,$CROP_HEIGHT}" --outfile "$EMPTY_PDF" < /dev/null 2>/dev/null || {
        printf "%%PDF-1.1\n1 0 obj << /Type /Catalog /Pages 2 0 R >> endobj\n2 0 obj << /Type /Pages /Kids [3 0 R] /Count 1 >> endobj\n3 0 obj << /Type /Page /Parent 2 0 R /MediaBox [0 0 215.9 139.7] >> endobj\nxref\n0 4\n0000000000 65535 f \n0000000010 00000 n \n0000000060 00000 n \n0000000120 00000 n \ntrailer << /Root 1 0 R >>\nstartxref\n180\n%%EOF\n" > "$EMPTY_PDF"
    }
fi

##############
# Langkah 1: Potong bagian atas tiap PDF
##############
echo "🔪 Memotong bagian atas tiap PDF..."
i=0
shopt -s nullglob
for pdf in *.pdf; do
    [[ "$pdf" == "$FINAL" ]] && continue
    out="$CROP_DIR/$(printf "%03d" $i)_crop.pdf"
    echo "  - $pdf -> $out"

    pdfjam "$pdf" \
        --trim "0 $CROP_HEIGHT 0 0" \
        --clip true \
        --papersize "{215.9mm,$CROP_HEIGHT}" \
        --outfile "$out" 2>/dev/null

    i=$((i+1))
done

##############
# Langkah 2: Gabungkan tiap 2 crop menjadi A4
##############
echo "📐 Menggabungkan tiap 2 crop menjadi halaman A4..."

# Ambil semua file crop kecuali empty.pdf
files=()
for f in "$CROP_DIR"/*.pdf; do
    [[ "$(basename "$f")" == "empty.pdf" ]] && continue
    files+=("$f")
done

count=${#files[@]}
idx=0
a4idx=0

while [ $idx -lt $count ]; do
    f1="${files[$idx]}"

    if [ $((idx+1)) -lt $count ]; then
        f2="${files[$((idx+1))]}"
    else
        f2="$EMPTY_PDF"   # dipakai hanya jika ganjil
    fi

    outa4="$A4_DIR/$(printf "%03d" $a4idx)_A4.pdf"
    echo "  - Pair: $f1 + $f2 -> $outa4"

    pdfjam "$f1" "$f2" \
        --nup 1x2 \
        --papersize "{210mm,297mm}" \
        --scale "$SCALE_A4" \
        --offset "${MARGIN_LEFT} ${MARGIN_TOP}" \
        --delta "${MARGIN_RIGHT} 0mm" \
        --outfile "$outa4" 2>/dev/null

    idx=$((idx+2))
    a4idx=$((a4idx+1))
done

##############
# Langkah 3: Gabungkan seluruh A4 jadi 1 file
##############
echo "📚 Menggabungkan semua A4 menjadi $FINAL..."
pdfjam "$A4_DIR"/*.pdf --outfile "$FINAL" 2>/dev/null

if [ ! -f "$FINAL" ]; then
    echo "❌ Gagal membuat file final."
    exit 1
fi

echo "✅ Selesai: $FINAL"

##############
# Langkah 4: Bersihkan temp folders
##############
echo "🧹 Menghapus folder sementara..."
rm -rf "$CROP_DIR" "$A4_DIR"
echo "✅ Folder sementara dihapus."
