@echo off
REM === Slime Split Build Script ===
REM Creates .love file and Windows executable

set GAME_NAME=slime-split
set LOVE_DIR=C:\Program Files\LOVE

echo [1/3] Creating .love file...
if exist "build" rmdir /s /q "build"
mkdir build

REM Create .love (zip with main.lua at root)
cd /d "%~dp0"
powershell -Command "Compress-Archive -Path 'main.lua','conf.lua','src' -DestinationPath 'build\%GAME_NAME%.zip' -Force"
ren "build\%GAME_NAME%.zip" "%GAME_NAME%.love"

echo [2/3] Creating Windows executable...
if exist "%LOVE_DIR%\love.exe" (
    mkdir "build\%GAME_NAME%-win64"
    copy /b "%LOVE_DIR%\love.exe"+"build\%GAME_NAME%.love" "build\%GAME_NAME%-win64\%GAME_NAME%.exe" >nul
    REM Copy required DLLs
    for %%f in ("%LOVE_DIR%\*.dll") do copy "%%f" "build\%GAME_NAME%-win64\" >nul
    copy "%LOVE_DIR%\license.txt" "build\%GAME_NAME%-win64\" >nul 2>nul
    echo    Windows build created: build\%GAME_NAME%-win64\
) else (
    echo    LOVE not found at %LOVE_DIR%, skipping Windows build
)

echo [3/3] Done!
echo.
echo Output files:
echo    build\%GAME_NAME%.love          - Cross-platform LOVE package
echo    build\%GAME_NAME%-win64\        - Windows standalone
echo.
echo Next steps:
echo    - Web build: use love.js (see README)
echo    - Upload to itch.io
pause
