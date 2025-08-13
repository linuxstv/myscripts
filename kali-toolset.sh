#!/bin/bash
set -e

echo "Adding Kali Linux repository and key..."

# Install dependencies
apt update
apt install -y curl gnupg

# Add Kali repo key
curl -fsSL https://archive.kali.org/archive-key.asc | gpg --dearmor | tee /etc/apt/trusted.gpg.d/kali-archive-keyring.gpg > /dev/null

# Add Kali repo
echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" | tee /etc/apt/sources.list.d/kali.list

# Update package lists
apt update

echo "Installing Smart Kali-Lite toolset..."

# Install recommended Kali tool categories
apt install -y kali-tools-top10 kali-tools-information-gathering kali-tools-web kali-tools-passwords

echo "Cleaning up..."

# Optional: You can remove Kali repo after install if you want to keep your system stable
# Uncomment below lines to remove Kali repo after install
# rm /etc/apt/sources.list.d/kali.list
# apt update

echo "Installation complete! You now have Kali tools on your system."
echo "You can add more Kali tool categories anytime, e.g., 'sudo apt install kali-tools-wireless'"
