# Comprehensive Project Change Log — YouTube Bulk Subtitles Downloader

**Project:** `yt-bulk-subtitles-downloader-0.2`  
**Change-log scope:** The original ZIP supplied at the beginning of the session through the current failure-report build.  
**Current source:** `ytbsd.py` (final line references below are for this current file).  
**Current feature build:** Windows build-kit archive containing the revised source, README, dependency list, launcher/setup scripts, and `build_exe.bat`.

> **How to read the line references:** Python line numbers change when functions are inserted or expanded. “Original lines” refer to the initial `ytbsd.py` from the supplied `yt-bulk-subtitles-downloader-0.2.zip`. “Current lines” refer to the final `ytbsd.py` shipped with this build. Earlier intermediate ZIPs are identified by feature stage below. Line ranges are navigation anchors, not a claim that only those exact lines changed; edits to surrounding logic can shift nearby lines.

---

## 1. Executive summary

The project started as a command-line YouTube subtitle downloader that supported one video, a playlist, and a channel. During this session, it was extended to accept arbitrary lists of video URLs, gained consistent numbered output filenames and source-URL headers, gained a timestamp-preserving plain-text export, had its thread/proxy behavior bounded to reduce avoidable waiting, gained a Windows executable build script, and now creates a failure report that makes unavailable or failed subtitles easy to identify.

The current build retains the existing single-video, playlist, channel, and resume workflows. It adds one standalone URL-list workflow and one report file per completed or interrupted output generation.

### Current output behavior

- Subtitle files start at `01-`, then `02-`, `03-`, and so on.
- Duplicate titles receive a suffix such as `(2)`, `(3)`, etc.; subtitle files are not knowingly overwritten.
- `.md`, `.srt`, and `.txt` output remains available.
- Individual SRT and TXT files include a `Source video: URL` header and timestamped numbered cues. TXT uses the same timestamped cue content as SRT, stored with a `.txt` extension.
- Markdown puts the source URL on the first line of each Markdown file and repeats each video’s URL above its transcript section.
- Each job writes `00-failed-downloads.txt` alongside the subtitle output. Failed entries follow the requested layout: video title, URL, blank line. A clean run writes `No failed downloads.` to the report.

---

## 2. Iteration history

### Stage A — Original supplied project

The starting project already had the basic downloader, transcript fetching, proxy support, threading, Markdown and SRT output, progress persistence, and a console menu for a single video, playlist, or channel. The changes below are additions or revisions relative to that provided baseline, not a claim that every underlying capability was created from scratch during this session.

### Stage B — Multiple individual video URLs

**Intermediate archive:** `yt-bulk-subtitles-downloader-0.2-multi-url.zip`

Added a fourth download mode for a custom set of unrelated video URLs. The user can load a `.txt` file or paste one URL per line. Parsing ignores blank lines and comment lines beginning with `#`, validates common YouTube URL forms, removes duplicate video IDs, and preserves the first occurrence order. Video metadata for the list is fetched concurrently and reassembled into the original user-supplied order before transcript retrieval.

**Main source locations in the final file:**

- `get_user_choice()` — lines 1582–1604: menu labels and valid choices, including option 4.
- `get_multiple_video_urls()` — lines 1644–1708: text-file or pasted-line input, validation, comments, deduplication, and ordering.
- `get_video_metadata_for_url_list()` — lines 1711–1787: concurrent metadata retrieval, order preservation, and fallback records for metadata lookup failures.
- `run_new_job()` — lines 1982–2108: dispatches the multiple-URL workflow alongside existing modes.

The original `run_new_job()` occupied original lines 1782–1881. Its logic was expanded to obtain a URL list, resolve metadata, deduplicate returned video IDs, label the run as `multiple`, and then use the same transcript/output pipeline used by the other download modes.

### Stage C — Numbered filenames, collision handling, TXT format, and source URL headers

**Intermediate archive:** `yt-bulk-subtitles-downloader-0.2-multi-url-v2.zip`

1. Added a single filename utility to generate numbered output paths. The prefix uses at least two digits (`01-`, `02-`, etc.). It sanitizes invalid filename characters and adds a title suffix such as `(2)` when a title is repeated. It checks the filesystem before returning a path so existing subtitle files are preserved.
2. Added a plain-text output option in the format menu.
3. Added source-URL handling. Individual output files begin with `Source video: URL`; Markdown also adds the corresponding source above every video's section.
4. Kept separate output files for SRT and TXT downloads, while allowing Markdown to be a combined file or a set of word-count-split files.

**Main source locations in the final file:**

- `video_page_url()` and `get_video_source_url()` — lines 475–497: source URL normalization and compatibility with older saved progress data.
- `make_numbered_filepath()` — lines 500–520: sequential names, safe names, collision suffixes, and existing-file protection.
- `source_header()` — lines 523–525: consistent `Source video: URL` line.
- `create_markdown_output()` — lines 822–876: file-level header and per-video section URLs.
- `create_srt_output()` — lines 927–966: numbered per-video SRT files and source headers.
- `get_output_config()` — lines 1811–1863: output-format choices and Markdown splitting configuration.
- `finalize_output()` — lines 1884–1979: chooses output mode and output destination.

### Stage D — Timestamp-preserving TXT and speed/reliability adjustments

**Intermediate archives:** `yt-bulk-subtitles-downloader-0.2-multi-url-v3.zip` and `yt-bulk-subtitles-downloader-0.2-v3-windows-build-kit.zip`

#### TXT now uses the SRT cue structure

The TXT exporter writes the same numbered subtitle cues as the SRT exporter: cue number, start/end timestamp, subtitle text, and separation between cues. The file extension is `.txt`, so the file can be opened directly in a normal text editor without losing the timestamps. The source URL header is retained as the first line.

- `serialize_subtitle_segments()` — lines 528–537: stores transcript snippets as serializable text/start/duration records.
- `format_srt_timestamp()` — lines 540–546: normalizes numeric times to `HH:MM:SS,mmm`.
- `format_timestamped_subtitles()` — lines 549–572: returns SRT cue data from a live transcript or stored timestamp segments.
- `save_progress()` — lines 785–798: avoids attempting to serialize the live transcript API object and persists the serializable data needed for timestamped re-export.
- `create_text_output()` — lines 969–1008: uses the same timestamped cue renderer as SRT, rather than writing an untimed paragraph.

#### Thread and proxy handling

The original source set `DEFAULT_THREADS = 2`, allowed `MAX_THREADS = 1000`, and chose its suggested default from the number of saved proxies (original configuration and `get_threading_choice()` at original lines 144–151 and 1558–1589). This could make a very large worker count appear appropriate just because many proxy addresses existed.

The later build changes these defaults to:

- `DEFAULT_THREADS = 4`
- `MIN_THREADS = 1`
- `MAX_THREADS = 16`
- `MAX_PROXY_RETRIES = 3`
- Reduced staggering between workers (`THREAD_DELAY_MIN = 0.1`, `THREAD_DELAY_MAX = 0.3`)

The current `get_threading_choice()` — lines 1607–1631 — explicitly explains that the setting is the number of worker tasks, not the number of proxies, and bounds the user choice from 1 to 16. The current proxy/work queue code attempts direct connections first, tracks proxy failures, avoids repeatedly using a proxy already marked failed, and limits proxy fallbacks per video. At startup, refreshing free public proxies is optional; pressing Enter skips the scrape. This avoids automatically opening Chrome and waiting for a public proxy list on every launch.

These changes improve the app's defaults and avoid wasteful proxy behavior, but they cannot guarantee a particular download speed. Actual speed still depends on connection quality, YouTube request limits, transcript availability, and the responsiveness of YouTube services/proxies.

#### Concurrent metadata retrieval for a URL list

`get_video_metadata_for_url_list()` retrieves metadata concurrently with a small worker pool and sorts results back to the original input indices. This reduces serial waiting for a large list without changing the intended output order. If metadata lookup fails for an otherwise valid pasted URL, the current version keeps a fallback record using the parsed video ID and still attempts transcript retrieval; a placeholder title is used only when the actual YouTube title cannot be fetched.

#### Windows EXE build kit

The build-kit package added `build_exe.bat` and README instructions for PyInstaller. The batch script creates/reuses a virtual environment, installs dependencies and PyInstaller, and builds a one-file console executable named `yt-bsd.exe` under `dist`. The app is still built on Windows for Windows; Google Chrome itself is not packaged and is only relevant if the optional Selenium proxy-scraping step is used.

Relevant project files:

- `build_exe.bat` — automated PyInstaller build.
- `requirements.txt` — runtime dependency list.
- `setup.bat` and `start.bat` — existing setup and launch workflow.
- `README.md` — updated usage and Windows build instructions.

### Stage E — Failure report for missing subtitle output (current change)

**Current feature build:** adds `00-failed-downloads.txt` and this comprehensive change log.

The finalization path now creates one failure report next to the output files. A video is reported if no transcript was obtained or if a transcript exists but the requested SRT/TXT export could not be produced (for example, saved legacy data has no timestamps). Repeated IDs/URLs are not duplicated in the report.

The file format is intentionally simple, per the requested specification:

```text
Video title exactly as returned by YouTube metadata
https://www.youtube.com/watch?v=VIDEO_ID

Second failed video title
https://www.youtube.com/watch?v=VIDEO_ID_2

```

When no videos failed, the report contains:

```text
No failed downloads.
```

The report has the fixed name `00-failed-downloads.txt`, so it sorts before `01-...` subtitle files. It is refreshed in place on a later run rather than accumulating stale reports named `(2)`, `(3)`, etc.

**Main source locations in the final file:**

- `create_srt_output()` — lines 927–966: optionally records video IDs that could not be exported to SRT.
- `create_text_output()` — lines 969–1008: optionally records video IDs that could not be exported to timestamped TXT.
- `create_failed_download_report()` — lines 1011–1050: new report generator; filters successful exports, de-duplicates entries, writes title/URL/blank line blocks, and handles a clean run.
- `get_video_metadata_for_url_list()` — lines 1711–1787: does not silently discard a valid URL if metadata retrieval fails; it creates a fallback record so transcript retrieval can still be attempted.
- `finalize_output()` — lines 1884–1979: places the report beside the output files, passes through export failures, and prints the report path/count in the console.
- `README.md`: documents the report behavior and links this changelog.

#### Output folder placement rules

- **SRT:** `subtitles/<source name>/00-failed-downloads.txt`, beside the per-video `.srt` files.
- **TXT:** `subtitles/<source name>/00-failed-downloads.txt`, beside the per-video `.txt` files.
- **Split Markdown:** `subtitles/<source name>/00-failed-downloads.txt`, beside the split `.md` files.
- **Combined Markdown:** `subtitles/00-failed-downloads.txt`, beside the combined Markdown output file.

For a metadata lookup failure, the real YouTube title is unavailable by definition. In that exceptional case the report uses a clear fallback title such as `Title unavailable (VIDEO_ID)`; the original video URL is still recorded and attempted.

---

## 3. Source-code change map (original → current)

| Feature / area | Original source reference | Current source reference | Modification |
|---|---:|---:|---|
| Thread defaults | Lines 144–151 | Configuration near the top of `ytbsd.py` | Default workers increased from 2 to 4; maximum reduced from 1,000 to 16; maximum proxy retries reduced from 20 to 3; shorter worker staggering. |
| Main menu | `get_user_choice()`, lines 1533–1555 | `get_user_choice()`, lines 1582–1604 | Added mode 4 for multiple independent video URLs; resume remains available as mode 5 when a saved job exists. |
| Thread input | `get_threading_choice()`, lines 1558–1589 | `get_threading_choice()`, lines 1607–1631 | Removed proxy-count-driven default and 1–1000 input range; explained distinction between threads and proxies and bounded the range to 1–16. |
| URL input | `get_url()`, lines 1592–1599 | `get_multiple_video_urls()`, lines 1644–1708 (new) | Added loading a URL text file or pasting one URL per line, with validation, comments, and duplicate removal. |
| Metadata for URL list | Not present | `get_video_metadata_for_url_list()`, lines 1711–1787 (new) | Concurrent metadata fetch, stable original ordering, and fallback records on metadata failure. |
| Video URL identity | `extract_video_id()`, lines 557–567 | `extract_video_id()`, lines 459–472; `video_page_url()` and `get_video_source_url()` at lines 475–497 | Expanded handling for standard, shortened, Shorts, embed, live, and saved-progress URL cases; canonical fallback when needed. |
| Filename generation | Not present as a shared utility | `make_numbered_filepath()`, lines 500–520 (new) | Standardized numbering, filename sanitization, duplicate-title suffixes, and checks against existing files. |
| Source header | Previously output-specific / absent | `source_header()`, lines 523–525 (new) | Centralized `Source video: URL` text. |
| Timestamp storage/rendering | Raw/live transcript handling | `serialize_subtitle_segments()` lines 528–537; `format_srt_timestamp()` lines 540–546; `format_timestamped_subtitles()` lines 549–572 | Added serializable timing data and a shared SRT-compatible cue renderer. |
| Progress serialization | `save_progress()`, original lines 776–789 | `save_progress()`, lines 785–798 | Filters out non-serializable live transcript objects while preserving stored subtitle timing segments. |
| Markdown contents | `create_markdown_output()`, original lines 813–859 | Lines 822–876 | Adds file-level source URL and source URL above each video's section. |
| SRT output | `create_srt_output()`, original lines 910–943 | Lines 927–966 | Adds numbered collision-safe filenames and URL headers; tracks SRT export failures for the report. |
| TXT output | Not present in original source | `create_text_output()`, lines 969–1008 (new) | Adds one `.txt` file per video using the same timestamped cues as SRT and a source URL header. |
| Failure report | Not present | `create_failed_download_report()`, lines 1011–1050 (new) | Writes `00-failed-downloads.txt` in the output directory with the requested title/URL/blank-line structure. |
| Output selection | `get_output_config()`, original lines 1623–1671 | Lines 1811–1863 | Adds `.txt` as a selectable format and maintains Markdown combined/split options. |
| Final output | `finalize_output()`, original lines 1692–1779 | Lines 1884–1979 | Applies output naming and destination rules; writes the failure report and announces its path/count. |
| New job flow | `run_new_job()`, original lines 1782–1881 | Lines 1982–2108 | Adds multiple-URL metadata processing and routes all download modes through the common downloader/finalizer. |
| Startup behavior | `main()`, original lines 1914–1950 | Lines 2141–2184 | Proxy refresh is an explicit optional startup choice rather than an unavoidable wait. |
| EXE build | Not present in initial source ZIP | `build_exe.bat` (added in build-kit stage) | Automates virtual environment/dependency setup and PyInstaller build. |
| User docs | Initial README | Current `README.md` | Documents URL-list mode, file formats, threading, proxy behavior, executable build, failure report, and this changelog. |

### What was replaced or removed

- The previous default-thread recommendation that was derived from the number of proxy addresses was removed. Proxy count is shown for information only and no longer sets the thread count.
- The unbounded-feeling 1–1,000 worker prompt was replaced by a 1–16 range.
- The earlier TXT behavior (untimed plain transcript text) was replaced by timestamped cue output matching SRT.
- Metadata failures from the multiple-URL list no longer automatically cause that otherwise-valid URL to disappear from the rest of the job; a fallback record is kept where the video ID can be extracted.
- No original download mode was intentionally removed. Single video, playlist, channel, and resume remain available.

---

## 4. Output naming and failure-report contract

### Subtitle naming

Examples:

```text
01- Introduction.srt
02- Introduction (2).srt
03- Chapter 3.srt
```

The leading number is the output sequence within the generated output set. If the same title appears more than once, or a target filename already exists, an additional suffix is used to avoid overwriting the previous subtitle. Existing files are not deliberately replaced by regular subtitle file creation.

### Failure report

The report name is fixed as `00-failed-downloads.txt`. The report is separate from subtitle numbering and is always created when finalization runs, including interrupted/partial finalization. An entry is included when:

- a video returned no transcript;
- transcript download attempts failed; or
- a transcript exists but the requested timestamped SRT/TXT export could not be completed.

Each unique failed video is output in source order with exactly the title line, URL line, and blank line. The report does not add error text after each URL, because the requested format was title + URL + empty line. If there are zero failures, the file contains a one-line success note instead of being empty.

The report is regenerated on each finalization. This ensures an earlier failure list is replaced after a subsequent run, instead of misleadingly retaining failures that have since been resolved.

---

## 5. Build and runtime notes

- Source execution continues to use `start.bat` after setup.
- `build_exe.bat` builds a Windows console executable using PyInstaller's one-file mode and names it `yt-bsd.exe` in `dist`.
- Build the Windows executable on Windows; a PyInstaller executable is platform-specific.
- The executable bundles Python and collected project dependencies but does not include Google Chrome. Chrome is relevant only to the optional Selenium-based public-proxy scraping workflow.
- The executable and its working folder should be kept in a writable location because the tool creates `subtitles`, `.progress.json`, and optionally `proxies.txt` beside the launched script/executable.

---

## 6. Verification performed for this build

The current version was checked using:

1. Python syntax compilation (`py_compile`) of the updated `ytbsd.py`.
2. Isolated functional tests of the failed-report generator, including the exact title/URL/blank-line layout, duplicate suppression, clean-run message, and stable report filename.
3. Isolated output tests confirming SRT and TXT produce identical timestamped cue content and include the source URL on the first line.
4. Checks that per-video output starts with `01-` and the report is placed in the same folder as the per-video subtitle outputs.
5. ZIP integrity verification after packaging.

**Not verified here:** A live YouTube transcript download and a real Windows EXE execution. The environment used for this edit did not have the downloader's runtime packages installed and cannot establish live YouTube behavior. Therefore this log does not claim an end-to-end network test or a measured speed increase.

---

## 7. Files in the current build

- `ytbsd.py` — downloader source, including multiple URL input, numbered output, timestamp-preserving formats, bounded connection handling, and failure report generation.
- `README.md` — updated user-facing feature and build instructions.
- `CHANGELOG-COMPREHENSIVE.md` — this change log.
- `requirements.txt` — project runtime dependencies.
- `start.bat` — launcher.
- `setup.bat` — setup helper.
- `build_exe.bat` — Windows PyInstaller build helper.
- `screenshot.jpg` — project screenshot retained from the original project.

---

## 8. Current report example

When two videos fail, `00-failed-downloads.txt` will look like this:

```text
The first failed video title
https://www.youtube.com/watch?v=VIDEO_ID_01

The second failed video title
https://www.youtube.com/watch?v=VIDEO_ID_02

```

Replace the example title and IDs above with the actual title/URLs supplied by YouTube during a real job. The final implementation writes the returned title and source URL; if metadata retrieval itself fails, the report uses a fallback title containing the video ID because the exact title was not available to the program.
