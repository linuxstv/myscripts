#!/bin/bash

# Check if ffmpeg is installed
if ! command -v ffmpeg &> /dev/null; then
	echo "ffmpeg is not installed. Please install it first."
	exit 1
fi

# List all video files in the current directory
echo "Available video files:"
files=(*.mp4) # Change the extension if needed, e.g., *.mkv, *.avi
for i in "${!files[@]}"; do
	echo "$((i+1))) ${files[i]}"
done

# Check if there are no video files
if [ ${#files[@]} -eq 0 ]; then
	echo "No video files found in the current directory."
	exit 1
fi

# Ask the user to select a file by number
read -p "Select a file by number (1-${#files[@]}): " file_number
if ! [[ $file_number =~ ^[0-9]+$ ]] || [ $file_number -lt 1 ] || [ $file_number -gt ${#files[@]} ]; then
	echo "Invalid selection. Please choose a valid number."
	exit 1
fi
selected_file="${files[file_number-1]}"

# Ask the user for the start time (-ss)
read -p "Enter the start time (format: HH:MM:SS, e.g., 00:03:02): " start_time

# Ask the user for the duration (-t)
read -p "Enter the duration in seconds (e.g., 60): " duration
if ! [[ $duration =~ ^[0-9]+$ ]]; then
	echo "Invalid duration. Please enter a valid number."
	exit 1
fi

# Ask the user for the output file name
read -p "Enter the output file name (e.g., output.mp4): " output_file

# Confirm the inputs
echo "Selected file: $selected_file"
echo "Start time: $start_time"
echo "Duration: $duration seconds"
echo "Output file: $output_file"

# Execute the ffmpeg command
echo "Cutting video..."
ffmpeg -i "$selected_file" -ss "$start_time" -t "$duration" -c copy "$output_file"

# Check if the command was successful
if [ $? -eq 0 ]; then
	echo "Video successfully cut and saved to $output_file!"
else
	echo "Failed to cut the video. Please check your inputs."
fi
