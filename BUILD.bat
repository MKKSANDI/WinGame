@echo off
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"

set "MODE=%~1"
if "%MODE%"=="" set "MODE=pyinstaller"

echo ============================================
echo WinGame Build Script
echo Mode: %MODE%
echo ============================================
echo.

python --version >nul 2>&1
if errorlevel 1 (
    echo Python is not available in PATH.
    exit /b 1
)

python -m pip install --upgrade pip >nul
python -m pip install -r requirements.txt
if errorlevel 1 (
    echo Failed to install runtime requirements.
    exit /b 1
)

if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist dist_nuitka rmdir /s /q dist_nuitka

set "EXE_PATH="

if /i "%MODE%"=="pyinstaller" (
    python -m pip install pyinstaller
    if errorlevel 1 (
        echo Failed to install PyInstaller.
        exit /b 1
    )

    python -m PyInstaller ^
      --noconfirm ^
      --clean ^
      --onefile ^
      --windowed ^
      --name "WinGame" ^
      --icon "WinGame.ico" ^
      --add-data "WinGame.png;." ^
      --add-data "system.png;." ^
      --add-data "game.png;." ^
      GamePerformanceOptimizer.py
    if errorlevel 1 (
        echo PyInstaller build failed.
        exit /b 1
    )
    set "EXE_PATH=dist\WinGame.exe"
) else if /i "%MODE%"=="nuitka" (
    python -m pip install nuitka ordered-set zstandard dill
    if errorlevel 1 (
        echo Failed to install Nuitka dependencies.
        exit /b 1
    )

    python -m nuitka ^
      --onefile ^
      --enable-plugin=pyqt6 ^
      --windows-disable-console ^
      --windows-icon-from-ico=WinGame.ico ^
      --include-data-file=WinGame.png=WinGame.png ^
      --include-data-file=system.png=system.png ^
      --include-data-file=game.png=game.png ^
      --output-dir=dist_nuitka ^
      --output-filename=WinGame.exe ^
      GamePerformanceOptimizer.py
    if errorlevel 1 (
        echo Nuitka build failed.
        exit /b 1
    )
    set "EXE_PATH=dist_nuitka\WinGame.exe"
) else (
    echo Unknown mode "%MODE%".
    echo Use one of:
    echo   BUILD.bat pyinstaller
    echo   BUILD.bat nuitka
    exit /b 1
)

if not exist "%EXE_PATH%" (
    echo Build completed but executable was not found: %EXE_PATH%
    exit /b 1
)

for /f %%i in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd-HHmmss"') do set "STAMP=%%i"
set "RELEASE_DIR=releases\wingame-%STAMP%"
set "RELEASE_ZIP=releases\wingame-%STAMP%.zip"

if not exist releases mkdir releases
if exist "%RELEASE_DIR%" rmdir /s /q "%RELEASE_DIR%"
mkdir "%RELEASE_DIR%"

copy /y "%EXE_PATH%" "%RELEASE_DIR%\WinGame.exe" >nul
copy /y "README.md" "%RELEASE_DIR%\" >nul
copy /y "requirements.txt" "%RELEASE_DIR%\" >nul
copy /y "sample_config.json" "%RELEASE_DIR%\" >nul
copy /y "RUN_AS_ADMIN.bat" "%RELEASE_DIR%\" >nul

powershell -NoProfile -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%RELEASE_DIR%\\*' -DestinationPath '%RELEASE_ZIP%' -Force" >nul
if errorlevel 1 (
    echo Release packaging failed.
    exit /b 1
)

echo.
echo Build complete.
echo EXE: %EXE_PATH%
echo Release folder: %RELEASE_DIR%
echo Release zip: %RELEASE_ZIP%
exit /b 0
