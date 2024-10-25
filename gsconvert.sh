#!/bin/bash

# Function to list PDF files and allow user to pick one by number
pick_file() {
  local files=(*.pdf)
  echo "Available PDF files:"
  
  # List PDF files with numbered options
  for i in "${!files[@]}"; do
    echo "$((i+1)). ${files[i]}"
  done
  
  # Prompt user to pick a file by number
  read -p "Enter the number of the file you want to convert: " file_number
  
  # Convert user input to an index and check if it's valid
  if [[ "$file_number" -gt 0 && "$file_number" -le "${#files[@]}" ]]; then
    chosen_file="${files[file_number-1]}"
    echo "You selected '$chosen_file'"
  else
    echo "Invalid selection."
    exit 1
  fi
}

# Prompt the user to select a single file or all files
echo "Choose an option:"
echo "1. Convert a specific PDF file"
echo "2. Convert all PDF files in the folder"
read -p "Enter your choice (1 or 2): " choice

# Prompt the user for the color image resolution
read -p "Enter the desired color image resolution (e.g., 85): " resolution

# Create the 'converted' directory if it doesn't exist
mkdir -p converted

# Process based on the user's choice
if [ "$choice" -eq 1 ]; then
  # Call function to pick a file by number
  pick_file
  
  # Define the output filename
  output_file="converted/${chosen_file%.pdf}-converted.pdf"
  
  # Run Ghostscript on the selected file
  gs -sDEVICE=pdfwrite \
     -dCompatibilityLevel=1.4 \
     -dDownsampleColorImages=true \
     -dColorImageResolution="$resolution" \
     -dNOPAUSE \
     -dBATCH \
     -sOutputFile="$output_file" "$chosen_file"
  echo "File '$chosen_file' has been converted and saved to 'converted' folder."

elif [ "$choice" -eq 2 ]; then
  # Loop through all PDF files in the current folder
  for file in *.pdf; do
    # Define the output filename with the 'converted' folder path
    output_file="converted/${file%.pdf}-converted.pdf"
    
    # Run Ghostscript with the user-defined resolution and other specified settings
    gs -sDEVICE=pdfwrite \
       -dCompatibilityLevel=1.4 \
       -dDownsampleColorImages=true \
       -dColorImageResolution="$resolution" \
       -dNOPAUSE \
       -dBATCH \
       -sOutputFile="$output_file" "$file"
    echo "Converted '$file' to 'converted/$output_file'."
  done
else
  echo "Invalid choice. Please run the script again and select 1 or 2."
fi
