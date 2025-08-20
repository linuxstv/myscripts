#!/bin/bash
set -e

# Buat direktori sementara
mkdir -p temp_a5 temp_a4

# Atur margin yang bisa disesuaikan
MARGIN_LEFT="-10mm"
MARGIN_TOP="-15mm"
MARGIN_RIGHT="15mm"

# Kumpulkan input PDF, skip file dummy & output
shopt -s nullglob
input_files=()
for file in *.pdf; do
  case "$file" in
    empty.pdf|final_merged.pdf) continue ;;
  esac
  input_files+=("$file")
done

if (( ${#input_files[@]} == 0 )); then
  echo "Tidak ada file PDF input di folder ini."
  exit 1
fi

# Langkah 1: Potong setiap file dan hanya ambil bagian atasnya
a5_files=()
for file in "${input_files[@]}"; do
  base=$(basename "$file" .pdf)
  top_file="temp_a5/${base}_top.pdf"
  pdfjam "$file" --trim "0 139.7mm 0 0" --clip true --papersize "{215.9mm,139.7mm}" --outfile "$top_file"
  a5_files+=("$top_file")
done

# Pastikan Ghostscript ada untuk membuat dummy
if ! command -v gs >/dev/null 2>&1; then
  echo "Error: Ghostscript (gs) tidak ditemukan. Silakan install paket 'ghostscript' dulu."
  exit 1
fi

# Buat halaman kosong A5 landscape (dummy) SETELAH langkah potong,
# supaya tidak ikut terproses di loop atas.
# 612x421 pt ≈ 215.9mm x 139.7mm
gs -o empty.pdf -sDEVICE=pdfwrite -g612x421 -c showpage

# Langkah 2: Gabungkan setiap dua file bagian atas menjadi satu halaman A4 dengan margin
a4_files=()
num_files=${#a5_files[@]}
for ((i=0; i<num_files; i+=2)); do
  a4_file="temp_a4/a4_$(printf "%02d" $((i/2+1))).pdf"
  if [[ -n "${a5_files[i+1]:-}" ]]; then
    # Genap -> dua file
    pdfjam "${a5_files[i]}" "${a5_files[i+1]}" \
      --nup 1x2 \
      --trim "$MARGIN_LEFT $MARGIN_TOP $MARGIN_RIGHT 0" \
      --papersize "{210mm,297mm}" \
      --outfile "$a4_file"
  else
    # Ganjil -> padankan dengan halaman kosong agar tetap di slot atas
    pdfjam "${a5_files[i]}" empty.pdf \
      --nup 1x2 \
      --trim "$MARGIN_LEFT $MARGIN_TOP $MARGIN_RIGHT 0" \
      --papersize "{210mm,297mm}" \
      --outfile "$a4_file"
  fi
  a4_files+=("$a4_file")
done

# Langkah 3: Gabungkan semua file A4 menjadi satu file akhir
if (( ${#a4_files[@]} > 0 )); then
  pdfjam "${a4_files[@]}" --outfile final_merged.pdf
else
  echo "Tidak ada file A4 untuk digabung."
  exit 1
fi

# Bersihkan direktori sementara dan file dummy
rm -r temp_a5 temp_a4
rm -f empty.pdf

echo "Proses selesai! File hasil akhir: final_merged.pdf"
