# YouTube Bulk Subtitles Downloader (YTBSD)

A high-performance CLI tool for mass downloading subtitles (captions) from YouTube channels, playlists, or individual videos.

![Screenshot](screenshot.jpg)

## Features

- **Bulk Download** - Download subtitles from channels, playlists, or a custom list of individual video URLs
- **Multiple Output Formats** - Save as Markdown, timestamped SRT, or timestamped plain TXT files
- **Bounded Multi-threading** - Uses 4 worker threads by default, configurable from 1 to 16
- **Direct-First Connections** - Avoids slow proxy hops when a direct connection works
- **Optional Proxy Fallback** - Free public proxies can be refreshed manually at startup; failed proxies are skipped and retries are capped
- **Failure Report** - Every job creates `00-failed-downloads.txt` beside its output, listing each video with no exported subtitle as title, source URL, and a blank line
- **Resume Capability** - Progress is saved automatically; interrupted downloads can be resumed
- **Cross-Platform** - Works on Windows, Linux, and macOS

## Installation

### Option 1: From Source

1. Clone or download this repository
2. Run `setup.bat` (Windows) to create a virtual environment and install dependencies
3. Run `start.bat` to launch the tool


### Build your own Windows executable

1. Install Python 3.8 or newer on Windows and make sure the Python launcher (`py`) or `python` command works in Command Prompt.
2. Extract this project into a normal writable folder.
3. Double-click `build_exe.bat`. It creates/reuses the project's `venv`, installs the required packages plus PyInstaller, and builds a standalone console executable.
4. When finished, find `dist\yt-bsd.exe`. Copy it to a writable folder and run it from there. The application creates its `subtitles` folder and `proxies.txt` beside the executable.

The build script uses PyInstaller's one-file mode and collects the application's third-party packages. The executable is built for Windows; build it on Windows rather than on Linux or macOS. An executable built this way includes Python and the project's Python dependencies, but it does not include Google Chrome. Chrome is only needed for the optional Selenium-based proxy-list scraping feature.

### Option 2: Windows Executable

Download the pre-compiled executable from the [Releases](https://github.com/roundyyy/yt-bulk-subtitles-downloader/releases/download/0.1/yt-bsd.exe) page.

## Requirements

- Python 3.10 or newer
- Google Chrome (only if you choose to refresh public proxies via Selenium)

## Usage

1. Launch the tool using `start.bat`
2. At startup, optionally refresh the free public proxy list. This launches Chrome and can be slow; press Enter to skip it.
3. Select download mode:
   - Single video
   - Playlist
   - Channel (videos, shorts, or both)
   - Multiple individual videos (load a `.txt` file or paste URLs one per line)
4. For multiple videos, choose a text file or paste URLs. Blank lines and `#` comment lines are ignored; duplicate video IDs are removed.
5. Configure thread count and output format.
6. Wait for download to complete.

### Text file format for multiple videos

Create a plain-text `.txt` file with one YouTube video URL per line. For example:

```text
https://www.youtube.com/watch?v=VIDEO_ID_01
https://youtu.be/VIDEO_ID_02
https://www.youtube.com/shorts/VIDEO_ID_03
```

Use real YouTube video URLs in place of the example IDs. Lines that are blank or begin with `#` are ignored. Invalid lines are skipped, and the downloader continues with the valid URLs.

Output files are saved to the `subtitles` folder. Every subtitle output filename begins with a sequential prefix (`01-`, `02-`, `03-`, and so on). When video titles repeat or a file already exists, a numeric suffix is added to avoid overwriting. The source video URL is written on the first line of each subtitle output file; Markdown also includes the respective URL at the start of every video section. Each job also writes `00-failed-downloads.txt` in the same folder as the output files. It lists videos whose subtitles could not be downloaded/exported as the YouTube title on line one, the video URL on line two, and a blank line between entries. If all subtitle files were created, the report says `No failed downloads.`.

## Output Formats

| Format | Description |
|--------|-------------|
| Markdown (.md) | All transcripts in one or more files, with a table of contents and source URL before every video section. |
| SRT (.srt) | Individual timestamped subtitle file per video. Each file begins with `Source video: URL`. Some subtitle players may not accept a metadata line before the first SRT cue. |
| Plain text (.txt) | Individual text file per video with the same numbered timestamp cues as SRT. Each file begins with `Source video: URL`. |

## Project change log

See [`CHANGELOG-COMPREHENSIVE.md`](CHANGELOG-COMPREHENSIVE.md) for the detailed development history, modified functions, line references, and verification notes covering the changes made to this project during this session.

## Disclaimer

This tool is intended for educational purposes only.

## Acknowledgments

- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - Video metadata extraction
- [youtube-transcript-api](https://github.com/jdepoix/youtube-transcript-api) - Transcript fetching

## License

MIT License


