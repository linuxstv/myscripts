#!/bin/bash

# Prompt the user for the color image resolution
read -p "Enter the desired color image resolution (e.g., 85): " resolution

# Create the 'converted' directory if it doesn't exist
mkdir -p converted

# Loop through all PDF files in the current folder
for file in *.pdf; do
  # Define the output filename with the 'converted' folder path
  output_file="converted/${file%.pdf}.pdf"

  # Run Ghostscript with the user-defined resolution and other specified settings
  gs -sDEVICE=pdfwrite \
     -dCompatibilityLevel=1.4 \
     -dDownsampleColorImages=true \
     -dColorImageResolution="$resolution" \
     -dNOPAUSE \
     -dBATCH \
     -sOutputFile="$output_file" "$file"
done
