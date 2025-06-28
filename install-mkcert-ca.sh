#!/bin/bash

# Nama file CA
CA_FILE="rootCA.pem"

# Cek apakah file CA ada di direktori skrip
if [ ! -f "$CA_FILE" ]; then
  echo "❌ File $CA_FILE tidak ditemukan di folder ini."
  exit 1
fi

# Deteksi OS
OS="$(uname)"

if [ "$OS" = "Linux" ]; then
  echo "🛠️ Menginstal mkcert root CA di Linux..."
  sudo cp "$CA_FILE" "/usr/local/share/ca-certificates/mkcert-rootCA.crt"
  sudo update-ca-certificates
  echo "✅ Instalasi selesai di Linux. Silakan restart browser."
elif [ "$OS" = "Darwin" ]; then
  echo "🛠️ Menginstal mkcert root CA di macOS..."
  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain "$CA_FILE"
  echo "✅ Instalasi selesai di macOS. Silakan restart browser."
else
  echo "❌ Sistem operasi tidak dikenali: $OS"
  exit 1
fi
