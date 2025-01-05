import subprocess
import tkinter as tk
from tkinter import messagebox
import threading

# Check if yt-dlp is installed
def check_yt_dlp():
	try:
		subprocess.run(["yt-dlp", "--version"], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		return True
	except FileNotFoundError:
		messagebox.showerror("Error", "yt-dlp is not installed. Please install it with 'pip install yt-dlp'.")
		return False

# Fetch available formats
def fetch_formats(video_url):
	try:
		result = subprocess.run(["yt-dlp", "-F", video_url], check=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
		return result.stdout
	except subprocess.CalledProcessError as e:
		messagebox.showerror("Error", f"Failed to fetch formats: {e.stderr}")
		return None

# Download the video with real-time progress
def download_video(video_url, video_format, audio_format, status_box):
	def download():
		try:
			# Prepare the format string
			format_string = video_format
			if audio_format:
				format_string += f"+{audio_format}"

			# Running yt-dlp with a custom progress handler using the --progress option
			process = subprocess.Popen(
				[
					"yt-dlp",
					"-f", f"{format_string}",
					"-o", "%(title)s.%(ext)s",
					"--progress",
					video_url
				],
				stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
			)

			# Continuously read the output
			for line in process.stdout:
				status_box.config(state="normal")
				status_box.insert("end", line)
				status_box.yview("end")  # Auto-scroll to the bottom
				status_box.config(state="disabled")

			process.stdout.close()
			process.wait()

			if process.returncode == 0:
				status_box.config(state="normal")
				status_box.insert("end", "Download completed successfully!\n")
				status_box.config(state="disabled")
			else:
				status_box.config(state="normal")
				status_box.insert("end", f"Download failed with exit code {process.returncode}\n")
				status_box.config(state="disabled")

		except Exception as e:
			status_box.config(state="normal")
			status_box.insert("end", f"Error: {str(e)}\n")
			status_box.config(state="disabled")

	# Run the download in a separate thread to avoid freezing the GUI
	download_thread = threading.Thread(target=download)
	download_thread.start()

# Main application
def main():
	if not check_yt_dlp():
		return

	root = tk.Tk()
	root.title("YouTube Video Downloader")
	root.geometry("800x600")  # Set an initial size
	root.attributes("-zoomed", True)  # Maximize the window

	main_frame = tk.Frame(root)
	main_frame.pack(fill="both", expand=True)

	# URL Input Frame
	url_frame = tk.Frame(main_frame)
	url_frame.pack(fill="x", padx=10, pady=5)

	tk.Label(url_frame, text="YouTube video URL:").grid(row=0, column=0, sticky="w", padx=5)

	url_entry = tk.Entry(url_frame)
	url_entry.grid(row=0, column=1, padx=5, pady=5, sticky="ew")

	fetch_button = tk.Button(url_frame, text="Fetch Formats", command=lambda: on_fetch_formats(url_entry.get()))
	fetch_button.grid(row=0, column=2, padx=5, pady=5)
	
	url_frame.grid_columnconfigure(1, weight=1)

	# Create context menu for right-click
	def on_right_click(event):
		context_menu.post(event.x_root, event.y_root)

	def copy_url():
		url_entry.clipboard_clear()
		url_entry.clipboard_append(url_entry.get())

	def cut_url():
		url_entry.clipboard_clear()
		url_entry.clipboard_append(url_entry.get())
		url_entry.delete(0, 'end')

	def paste_url():
		url_entry.insert('insert', root.clipboard_get())

	def select_all_url():
		url_entry.select_range(0, 'end')

	context_menu = tk.Menu(root, tearoff=0)
	context_menu.add_command(label="Cut", command=cut_url)
	context_menu.add_command(label="Copy", command=copy_url)
	context_menu.add_command(label="Paste", command=paste_url)
	context_menu.add_command(label="Select All", command=select_all_url)

	# Bind right-click event on URL input box
	url_entry.bind("<Button-3>", on_right_click)

	# Input Options Frame (Grid 1)
	input_options_frame = tk.Frame(main_frame)
	input_options_frame.pack(fill="x", padx=10, pady=5)

	video_audio_grid = tk.Frame(input_options_frame)
	video_audio_grid.grid(row=0, column=0, padx=5, pady=5, sticky="ew")

	tk.Label(video_audio_grid, text="Video code (e.g., 136 for 720p):").grid(row=0, column=0, sticky="w", padx=5, pady=5)
	video_format_entry = tk.Entry(video_audio_grid)
	video_format_entry.grid(row=0, column=1, padx=5, pady=5, sticky="ew")

	tk.Label(video_audio_grid, text="Audio code (e.g., 140 for m4a):").grid(row=1, column=0, sticky="w", padx=5, pady=5)
	audio_format_entry = tk.Entry(video_audio_grid)
	audio_format_entry.grid(row=1, column=1, padx=5, pady=5, sticky="ew")

	tk.Button(input_options_frame, text="Download", command=lambda: on_download()).grid(row=1, column=0, padx=5, pady=5, sticky="w")

	input_options_frame.grid_columnconfigure(1, weight=1)

	# Download Status Frame (side by side with Video/Audio fields)
	status_frame = tk.Frame(input_options_frame)
	status_frame.grid(row=0, column=2, rowspan=2, padx=10, pady=5)

	tk.Label(status_frame, text="Download Status:").pack(anchor="w", padx=5, pady=5)
	status_box = tk.Text(status_frame, wrap="word", height=8, state="disabled")
	status_box.pack(fill="both", expand=True, padx=5, pady=5)

	# Available Formats Frame (Video and Audio)
	formats_frame = tk.Frame(main_frame)
	formats_frame.pack(fill="both", expand=True, padx=10, pady=5)

	tk.Label(formats_frame, text="Available Video Formats:").pack(anchor="w", padx=5, pady=5)
	video_formats_listbox = tk.Listbox(formats_frame, height=10)
	video_formats_listbox.pack(fill="both", expand=True, padx=5, pady=5)

	tk.Label(formats_frame, text="Available Audio Formats:").pack(anchor="w", padx=5, pady=5)
	audio_formats_listbox = tk.Listbox(formats_frame, height=10)
	audio_formats_listbox.pack(fill="both", expand=True, padx=5, pady=5)

	def on_fetch_formats(video_url):
		video_formats_listbox.delete(0, "end")  # Clear previous video formats
		audio_formats_listbox.delete(0, "end")  # Clear previous audio formats

		if not video_url:
			messagebox.showerror("Error", "Please enter a YouTube video URL.")
			return

		formats = fetch_formats(video_url)
		if formats:
			# Extracting and populating video and audio formats into the listboxes
			format_lines = formats.splitlines()
			for line in format_lines:
				if line.strip():
					if 'audio' in line:  # Audio format
						audio_formats_listbox.insert("end", line)
					else:  # Video format
						video_formats_listbox.insert("end", line)

	def on_download():
		video_format = video_format_entry.get()
		audio_format = audio_format_entry.get()

		if not video_format:
			messagebox.showerror("Error", "Please enter a video format code.")
			return

		status_box.config(state="normal")
		status_box.delete("1.0", "end")  # Clear previous output
		status_box.insert("1.0", "Starting download...\n")
		status_box.config(state="disabled")

		# Call the download function with the status box
		download_video(url_entry.get(), video_format, audio_format, status_box)

	# When a video format is selected, fill the video code field
	def on_video_format_select(event):
		selected_video_format = video_formats_listbox.get(video_formats_listbox.curselection())
		if selected_video_format:
			# Extract the video format code (e.g., "136 video")
			video_code = selected_video_format.split()[0]
			video_format_entry.delete(0, "end")
			video_format_entry.insert(0, video_code)

	# When an audio format is selected, fill the audio code field
	def on_audio_format_select(event):
		selected_audio_format = audio_formats_listbox.get(audio_formats_listbox.curselection())
		if selected_audio_format:
			# Extract the audio format code (e.g., "140 audio")
			audio_code = selected_audio_format.split()[0]
			audio_format_entry.delete(0, "end")
			audio_format_entry.insert(0, audio_code)

	# Bind selection events
	video_formats_listbox.bind("<<ListboxSelect>>", on_video_format_select)
	audio_formats_listbox.bind("<<ListboxSelect>>", on_audio_format_select)

	root.mainloop()

if __name__ == "__main__":
	main()
