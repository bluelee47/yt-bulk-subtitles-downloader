@echo off
setlocal
cd /d "%~dp0"

echo ================================================
echo Building YT Bulk Subtitles Downloader EXE
echo ================================================
echo.

REM Reuse the project's virtual environment, or create it if missing.
if not exist "venv\Scripts\python.exe" (
    where py >nul 2>&1
    if not errorlevel 1 (
        py -3 -m venv venv
    ) else (
        python -m venv venv
    )
    if errorlevel 1 goto :failed
)

call "venv\Scripts\activate.bat"
if errorlevel 1 goto :failed

echo Installing/updating project dependencies and PyInstaller...
python -m pip install --upgrade pip
if errorlevel 1 goto :failed
python -m pip install -r requirements.txt pyinstaller
if errorlevel 1 goto :failed

echo.
echo Compiling a standalone console executable...
python -m PyInstaller --noconfirm --clean --onefile --console --name yt-bsd --collect-all yt_dlp --collect-all youtube_transcript_api --collect-all selenium --collect-all webdriver_manager --collect-all rich ytbsd.py
if errorlevel 1 goto :failed

if not exist "dist\yt-bsd.exe" goto :failed

echo.
echo ================================================
echo Build completed successfully!
echo Executable: %CD%\dist\yt-bsd.exe
echo ================================================
echo.
echo Copy yt-bsd.exe to a normal writable folder before running it.
echo The subtitles folder and proxies.txt will be stored beside the EXE.
echo Keep the EXE in the same folder if you want to preserve resume progress.
pause
exit /b 0

:failed
echo.
echo BUILD FAILED. Read the error messages above, then try again.
pause
exit /b 1
