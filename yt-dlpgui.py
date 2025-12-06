import subprocess
import tkinter as tk
import vlc
from tkinter import messagebox
import threading
import tkinter.filedialog as fd
import os

default_folder_path = os.getcwd()

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

def create_media_player():
	"""Create a media player window using VLC."""
	global vlc_instance, media_player

	# Create frame for the media player
	video_frame = tk.Frame(root, bg="black", relief="solid", bd=2)
	video_frame.grid(row=2, column=0, padx=10, pady=10, sticky="nsew")

	# VLC player instance
	vlc_instance = vlc.Instance()
	media_player = vlc_instance.media_player_new()
	media_player.set_hwnd(video_frame.winfo_id())  # Embed VLC into Tkinter Frame
	media_player.set_media(vlc_instance.media_new(r"path_to_your_video.mp4"))  # Replace with your video path

	# Add Play button
	play_button = tk.Button(video_frame, text="Play", command=play_video)
	play_button.pack(side="left", padx=5, pady=5)

	pause_button = tk.Button(video_frame, text="Pause", command=pause_video)
	pause_button.pack(side="left", padx=5, pady=5)


def play_video():
	"""Play video."""
	media_player.play()


def pause_video():
	"""Pause video."""
	media_player.pause()

# Download the video with real-time progress
def download_video(video_url, video_format, audio_format, status_box, stop_button, cookie):
	def download():
		global default_folder_path  # Use the updated global folder path
		try:
			# Prepare the format string
			format_string = video_format
			if audio_format:
				format_string += f"+{audio_format}"

			# Running yt-dlp with a custom progress handler using the --progress option
			output_template = os.path.join(default_folder_path, "%(title)s.%(ext)s")  # Include folder path
			# Add cookies parameter if enabled
			cookies = ["--cookies-from-browser", "chrome", "--cookies", "cookies.txt"] if cookie else []
			process = subprocess.Popen(
				[
					"yt-dlp",
					*cookies,
					"-f", f"{format_string}",
					"-o", output_template,
					"--progress",
					video_url
				],
				stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
			)

			# Store the process for termination later
			stop_button.process = process

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
			# Delete cookies.txt if it exists
			if cookie:
				try:
					if os.path.exists("cookies.txt"):
						os.remove("cookies.txt")
						status_box.insert("end", "cookies.txt deleted successfully.\n")
				except Exception as e:
					status_box.insert("end", f"Error deleting cookies.txt: {str(e)}\n")

		except Exception as e:
			status_box.config(state="normal")
			status_box.insert("end", f"Error: {str(e)}\n")
			status_box.config(state="disabled")

	# Run the download in a separate thread to avoid freezing the GUI
	download_thread = threading.Thread(target=download)
	download_thread.start()

# Stop the download
def stop_download(stop_button, status_box):
	if hasattr(stop_button, "process"):
		stop_button.process.terminate()
		status_box.config(state="normal")
		status_box.insert("end", "Download stopped.\n")
		status_box.config(state="disabled")

# Function to play the downloaded video
def play_video():
	try:
		# Get the latest downloaded file from the default folder
		global default_folder_path
		files = [os.path.join(default_folder_path, f) for f in os.listdir(default_folder_path) if os.path.isfile(os.path.join(default_folder_path, f))]
		if not files:
			messagebox.showerror("Error", "No downloaded videos found in the selected folder.")
			return

		# Sort files by modification time (most recent file first)
		latest_file = max(files, key=os.path.getmtime)

		# Check if it's a video file
		if not latest_file.lower().endswith(('.mp4', '.mkv', '.avi', '.webm', '.flv', '.mov')):
			messagebox.showerror("Error", "The latest file is not a video format.")
			return

		# Open the video file with the default video player
		if os.name == "nt":  # For Windows
			os.startfile(latest_file)
		elif os.name == "posix":  # For macOS/Linux
			subprocess.run(["open" if sys.platform == "darwin" else "xdg-open", latest_file])
		else:
			messagebox.showerror("Error", "Unable to open the video file.")
	except Exception as e:
		messagebox.showerror("Error", f"An error occurred while trying to play the video: {str(e)}")

# Main application
def main():
	if not check_yt_dlp():
		return

	# Default folder path
	default_folder_path = os.path.expanduser("~/Downloads")

	def browse_folder():
		global default_folder_path  # Make it global
		selected_folder = fd.askdirectory(initialdir=default_folder_path, title="Select Download Folder")
		if selected_folder:  # Update only if a folder is selected
			default_folder_path = selected_folder.rstrip("/")  # Remove trailing '/'
			folder_entry.delete(0, "end")  # Clear the entry box
			folder_entry.insert(0, default_folder_path)  # Update with the selected folder

	def update_default_folder_path(event=None):
		global default_folder_path
		new_folder_path = folder_entry.get().rstrip("/")  # Remove trailing '/'
		if os.path.isdir(new_folder_path):
			default_folder_path = new_folder_path
			folder_entry.delete(0, tk.END)
			folder_entry.insert(0, default_folder_path)  # Update entry without trailing '/'
			print(f"Updated default folder path to: {default_folder_path}")
		else:
			print("Invalid folder path entered.")

	def on_checkbox_toggle():
		if checkbox_var.get():
			print("With cookies!")
			messagebox.showinfo("Cookies", "Download by using cookies from chrome!")
		else:
			print("Without cookies!")
			messagebox.showinfo("Cookies", "Download without using cookies!")

	root = tk.Tk()
	root.title("YT-DLP Video Downloader")
	root.geometry("800x600")  # Set an initial size
	root.attributes("-zoomed", True)  # Maximize the window

	main_frame = tk.Frame(root)
	main_frame.pack(fill="both", expand=True)

	# Parent Frame for URL and Folder
	top_frame = tk.Frame(main_frame)
	top_frame.pack(fill="x", padx=10, pady=5)

	# URL Input Frame
	url_frame = tk.Frame(top_frame)
	url_frame.grid(row=0, column=0, sticky="ew", padx=5)

	tk.Label(url_frame, text="Video URL:").grid(row=0, column=0, sticky="w", padx=5)
	url_entry = tk.Entry(url_frame)
	url_entry.grid(row=0, column=1, padx=5, pady=5, sticky="ew")
	fetch_button = tk.Button(url_frame, text="Fetch Formats", command=lambda: on_fetch_formats(url_entry.get()))
#	fetch_button = tk.Button(url_frame, text="Fetch Formats", command=create_media_player)
	fetch_button.grid(row=0, column=2, padx=5, pady=5)

	# Add another placeholder widget to demonstrate layout
#	exit_button = tk.Button(url_frame, text="Exit", command=root.quit)
#	exit_button.grid(row=0, column=1, padx=10, pady=10)

	# Ensure URL entry expands
	url_frame.grid_columnconfigure(1, weight=1)

	# Folder Selection Frame
	folder_frame = tk.Frame(top_frame)
	folder_frame.grid(row=0, column=1, sticky="e", padx=5)

	folder_entry = tk.Entry(folder_frame, width=50)  # Entry widget for folder path
	folder_entry.insert(0, default_folder_path)  # Set the default folder path
	folder_entry.grid(row=0, column=0, padx=5, pady=5, sticky="w")
	# Add event listeners for focus out or key release
	folder_entry.bind("<FocusOut>", update_default_folder_path)
	folder_entry.bind("<KeyRelease>", update_default_folder_path)

	browse_button = tk.Button(folder_frame, text="Browse", command=browse_folder)
	browse_button.grid(row=0, column=1, padx=5)

	# Configure column expansion for top_frame
	top_frame.grid_columnconfigure(0, weight=1)  # Allow URL section to expand
	top_frame.grid_columnconfigure(1, weight=0)  # Prevent folder frame from stretching

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
		try:
			url_entry.delete("sel.first", "sel.last")
		except tk.TclError:
			pass
		url_entry.event_generate("<<Paste>>")

	def select_all_url():
		url_entry.select_range(0, tk.END)
		url_entry.icursor(tk.END)

	def show_context_menu(event):
		"""Display the right-click context menu at the cursor's location."""
		context_menu_fe.post(event.x_root, event.y_root)

	def copy_text():
		folder_entry.event_generate("<<Copy>>")

	def cut_text():
		folder_entry.event_generate("<<Cut>>")

	def paste_text():
		try:
			# Delete selected text and paste clipboard content
			folder_entry.delete("sel.first", "sel.last")
		except tk.TclError:
			# No text selected, just insert clipboard content
			pass
		folder_entry.event_generate("<<Paste>>")

	def select_all_text():
		folder_entry.select_range(0, tk.END)
		folder_entry.icursor(tk.END)  # Move cursor to the end of the selection

	def hide_context_menu(event=None):
		"""Hide the context menu."""
		context_menu.unpost()
		context_menu_fe.unpost()

	# Create a context menu for the url_entry
	context_menu = tk.Menu(root, tearoff=0)
	context_menu.add_command(label="Cut", command=cut_url)
	context_menu.add_command(label="Copy", command=copy_url)
	context_menu.add_command(label="Paste", command=paste_url)
	context_menu.add_command(label="Select All", command=select_all_url)
	# Create a context menu for the folder_entry
	context_menu_fe = tk.Menu(root, tearoff=0)
	context_menu_fe.add_command(label="Cut", command=cut_text)
	context_menu_fe.add_command(label="Copy", command=copy_text)
	context_menu_fe.add_command(label="Paste", command=paste_text)
	context_menu_fe.add_command(label="Select All", command=select_all_text)

	# Bind right-click event on URL input box
	url_entry.bind("<Button-3>", on_right_click)
	# Bind right-click to show the context menu
	folder_entry.bind("<Button-3>", show_context_menu)  # Button-3 is the right mouse button
	# Bind global click to hide the context menu
	root.bind("<Button-1>", hide_context_menu)  # Button-1 is the left mouse button

	# Input Options Frame (Grid 1)
	input_options_frame = tk.Frame(root, width=800, height=100)
	input_options_frame.pack(fill="x", padx=10, pady=5)

	video_audio_grid = tk.Frame(input_options_frame)
	video_audio_grid.grid(row=0, column=0, padx=5, pady=5, sticky="ew")

	tk.Label(video_audio_grid, text="Video code (e.g., 136 for 720p):").grid(row=0, column=0, sticky="w", padx=5, pady=5)
	video_format_entry = tk.Entry(video_audio_grid)
	video_format_entry.grid(row=0, column=1, padx=5, pady=5, sticky="ew")
	video_format_entry.insert(0, "136")  # Default value for Video code

	# Add the Empty V button
	empty_v_button = tk.Button(video_audio_grid, text="Empty V", command=lambda: video_format_entry.delete(0, "end"))
	empty_v_button.grid(row=0, column=2, padx=5, pady=5)

	# Add the Default V button
	def_v_button = tk.Button(video_audio_grid, text="Default V", command=lambda: video_format_entry.delete(0, "end") or video_format_entry.insert(0, "136"))
	def_v_button.grid(row=0, column=3, padx=5, pady=5)

	tk.Label(video_audio_grid, text="Audio code (e.g., 140 for m4a):").grid(row=1, column=0, sticky="w", padx=5, pady=5)
	audio_format_entry = tk.Entry(video_audio_grid)
	audio_format_entry.grid(row=1, column=1, padx=5, pady=5, sticky="ew")
	audio_format_entry.insert(0, "140")  # Default value for Audio code

	# Add the Empty A button
	empty_a_button = tk.Button(video_audio_grid, text="Empty A", command=lambda: audio_format_entry.delete(0, "end"))
	empty_a_button.grid(row=1, column=2, padx=5, pady=5)

	# Add the Default A button
	def_a_button = tk.Button(video_audio_grid, text="Default A", command=lambda: audio_format_entry.delete(0, "end") or audio_format_entry.insert(0, "140"))
	def_a_button.grid(row=1, column=3, padx=5, pady=5)

	# Add the Download button
	tk.Button(input_options_frame, text="Download", command=lambda: on_download()).grid(row=2, column=0, padx=5, pady=5, sticky="w")

	# Add the Stop button
	stop_button = tk.Button(input_options_frame, text="Stop", command=lambda: stop_download(stop_button, status_box))
	stop_button.grid(row=2, column=0, padx=150, pady=5, sticky="w")

	# Add the "Play" button in the input_options_frame
#	print("Creating Play button...")
#	play_button = tk.Button(input_options_frame, text="Play", command=play_video)
#	play_button.grid(row=2, column=1, padx=10, pady=5)
#	print("Play button created.")
	tk.Label(input_options_frame, text="Cookies:").grid(row=2, column=0, padx=250, pady=5, sticky="w")
	# Create a checkbox variable
	checkbox_var = tk.BooleanVar()
	# Add a checkbox
	checkbox = tk.Checkbutton(
		input_options_frame,
		text="Yes",
		variable=checkbox_var,
		command=on_checkbox_toggle
	)
	checkbox.grid(row=2, column=0, padx=300, pady=5)

	input_options_frame.grid_columnconfigure(0, weight=1)
#	input_options_frame.grid_columnconfigure(2, weight=1)

	# Download Status Frame (side by side with Video/Audio fields)
	status_frame = tk.Frame(input_options_frame)
	status_frame.grid(row=0, column=2, rowspan=4, padx=10, pady=5)

	tk.Label(status_frame, text="Download Status:").pack(anchor="w", padx=5, pady=5)
	status_box = tk.Text(status_frame, wrap="word", height=8, state="disabled")
	status_box.pack(fill="both", expand=True, padx=5, pady=5)

	# Available Formats Frame (Video and Audio)
	formats_frame = tk.Frame(main_frame)
	formats_frame.pack(fill="both", expand=True, padx=10, pady=5)

	tk.Label(formats_frame, text="Available Video Formats:").pack(anchor="w", padx=5, pady=5)
	video_formats_listbox = tk.Listbox(formats_frame, height=8)
	video_formats_listbox.pack(fill="both", expand=True, padx=5, pady=5)

	tk.Label(formats_frame, text="Available Audio Formats:").pack(anchor="w", padx=5, pady=5)
	audio_formats_listbox = tk.Listbox(formats_frame, height=8)
	audio_formats_listbox.pack(fill="both", expand=True, padx=5, pady=5)

	def on_fetch_formats(video_url):
		video_formats_listbox.delete(0, "end")  # Clear previous video formats
		audio_formats_listbox.delete(0, "end")  # Clear previous audio formats

		if not video_url:
			messagebox.showerror("Error", "Please enter a video URL.")
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
		cookie = checkbox_var.get()

		if not video_format:
			messagebox.showerror("Error", "Please enter a video format code.")
			return

		status_box.config(state="normal")
		status_box.delete("1.0", "end")  # Clear previous output
		status_box.insert("1.0", "Starting download...\n")
		status_box.config(state="disabled")

		# Call the download function with the status box
		download_video(url_entry.get(), video_format, audio_format, status_box, stop_button, cookie)

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

	# Start the GUI loop
	root.mainloop()

if __name__ == "__main__":
	main()

