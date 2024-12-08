#!/bin/bash

# Check if yt-dlp is installed
if ! command -v yt-dlp &> /dev/null; then
	echo "yt-dlp is not installed. Please install it with 'pip install yt-dlp'."
	exit 1
fi

# Ask the user for the video URL
read -p "Enter the YouTube video URL: " VIDEO_URL

# Display available formats
echo "Fetching available formats..."
yt-dlp -F "$VIDEO_URL"

# Ask the user to select video and audio formats
read -p "Enter the format code for the video stream (e.g., 136 for 720p): " VIDEO_FORMAT
read -p "Enter the format code for the audio stream (e.g., 140 for audio only): " AUDIO_FORMAT

# Confirm choices
echo "You selected video format: $VIDEO_FORMAT and audio format: $AUDIO_FORMAT"

# Perform the download
echo "Downloading..."
yt-dlp -f "$VIDEO_FORMAT+$AUDIO_FORMAT" -o "%(title)s.%(ext)s" "$VIDEO_URL"

# Check if the download was successful
if [ $? -eq 0 ]; then
	echo "Download completed successfully!"
else
	echo "Download failed. Please check your inputs and try again."
fi
