#!/bin/bash

# Buat direktori sementara
mkdir -p temp_a5 temp_a4

# Atur margin yang bisa disesuaikan
MARGIN_LEFT="-10mm"
MARGIN_TOP="-15mm"
MARGIN_RIGHT="15mm"

# Langkah 1: Potong setiap file dan hanya ambil bagian atasnya
a5_files=()
for file in *.pdf; do
  base=$(basename "$file" .pdf)
  
  # Potong bagian atas dan simpan
  top_file="temp_a5/${base}_top.pdf"
  pdfjam "$file" --trim "0 139.7mm 0 0" --clip true --papersize "{215.9mm,139.7mm}" --outfile "$top_file"
  a5_files+=("$top_file")
done

# Langkah 2: Gabungkan setiap dua file bagian atas menjadi satu halaman A4 dengan margin kiri, atas, dan kanan
a4_files=()
num_files=${#a5_files[@]}
for ((i=0; i<num_files; i+=2)); do
  if [[ -n "${a5_files[i+1]}" ]]; then
    a4_file="temp_a4/a4_$(printf "%02d" $((i/2+1))).pdf"
    pdfjam "${a5_files[i]}" "${a5_files[i+1]}" --nup 1x2 --trim "$MARGIN_LEFT $MARGIN_TOP $MARGIN_RIGHT 0" --papersize "{210mm,297mm}" --outfile "$a4_file"
    a4_files+=("$a4_file")
  else
    # Jika jumlah file ganjil, file terakhir tetap jadi A4 sendiri dengan margin
    a4_file="temp_a4/a4_$(printf "%02d" $((i/2+1))).pdf"
    pdfjam "${a5_files[i]}" --trim "$MARGIN_LEFT $MARGIN_TOP $MARGIN_RIGHT 0" --papersize "{210mm,297mm}" --outfile "$a4_file"
    a4_files+=("$a4_file")
  fi
done

# Langkah 3: Gabungkan semua file A4 menjadi satu file akhir
pdfjam "${a4_files[@]}" --outfile final_merged.pdf

# Bersihkan direktori sementara
rm -r temp_a5 temp_a4

echo "Proses selesai! File hasil akhir: final_merged.pdf"
