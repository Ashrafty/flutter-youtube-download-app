import yt_dlp
import os
import argparse

def get_download_path():
    if os.name == 'nt':  # Windows
        return os.path.join(os.path.expanduser('~'), 'Downloads')
    elif os.name == 'posix':  # macOS and Linux
        return os.path.join(os.path.expanduser('~'), 'Downloads')
    else:
        return os.getcwd()  # Current working directory as fallback

def download_video(url, format_index):
    download_path = get_download_path()
    ydl_opts = {
        'format': f'{format_index}+bestaudio/best',
        'outtmpl': os.path.join(download_path, '%(title)s.%(ext)s'),
    }
    
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])

def get_available_formats(url):
    ydl_opts = {'listformats': True}
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        info = ydl.extract_info(url, download=False)
        formats = info.get('formats', [])
        return [f"{f['format_id']} - {f['ext']} - {f.get('resolution', 'N/A')}" for f in formats]

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='YouTube Downloader')
    parser.add_argument('--get-formats', type=str, help='Get available formats for a YouTube URL')
    parser.add_argument('--download', type=str, help='Download a YouTube video')
    parser.add_argument('--format-index', type=int, help='Format index for download')
    
    args = parser.parse_args()

    if args.get_formats:
        formats = get_available_formats(args.get_formats)
        for format in formats:
            print(format)
    elif args.download and args.format_index is not None:
        download_video(args.download, args.format_index)
        print("Download complete!")
    else:
        print("Invalid arguments. Use --get-formats or --download with --format-index.")