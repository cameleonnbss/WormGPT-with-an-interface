@echo off
title CamChat
color 0C

echo.
echo  ======================================
echo   WormGPT - LOCAL AI
echo   by camzzz
echo  ======================================
echo.

cd /d "%~dp0"

:: Find ollama
set OLLAMA_CMD=ollama
where ollama >nul 2>&1
if %errorlevel% neq 0 (
    if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
        set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    ) else if exist "%ProgramFiles%\Ollama\ollama.exe" (
        set "OLLAMA_CMD=%ProgramFiles%\Ollama\ollama.exe"
    ) else (
        echo [!] Ollama not found. Run install.bat first.
        pause
        exit /b 1
    )
)

:: Start Ollama serve
echo [*] Starting Ollama...
start /B "" %OLLAMA_CMD% serve >nul 2>&1
timeout /t 3 /nobreak >nul

:: Check model
echo [*] Checking model...
%OLLAMA_CMD% list 2>nul | findstr "camchat" >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Model "camchat" not found. Run install.bat first.
    pause
    exit /b 1
)
echo [OK] Model ready.
echo.
echo  ======================================
echo   READY - http://localhost:5000
echo   Press Ctrl+C to stop
echo  ======================================
echo.

python "chatbot\app.py"
