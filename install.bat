@echo off
title CamChat Installer
color 0C

echo.
echo  ======================================
echo   CAMCHAT - LOCAL AI INSTALLER
echo   by camzzz
echo  ======================================
echo.

:: [1/4] Check Python
echo [1/4] Checking Python...
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Python not found.
    echo [*] Download from https://python.org
    pause
    exit /b 1
)
echo [OK] Python found.
echo.

:: [2/4] Install Ollama
echo [2/4] Setting up Ollama...
ollama --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Ollama already installed.
    goto :step3
)

echo [*] Installing Ollama via winget...
winget install Ollama.Ollama --accept-package-agreements --accept-source-agreements
if %errorlevel% neq 0 (
    echo [!] Winget failed. Trying direct download...
    powershell -Command "Invoke-WebRequest -Uri 'https://ollama.com/download/OllamaSetup.exe' -OutFile '%TEMP%\OllamaSetup.exe'"
    if not exist "%TEMP%\OllamaSetup.exe" (
        echo [!] Download failed. Install manually: https://ollama.com/download
        pause
        exit /b 1
    )
    echo [*] Running installer...
    start /wait "" "%TEMP%\OllamaSetup.exe"
    del /q "%TEMP%\OllamaSetup.exe" 2>nul
)
echo [OK] Ollama installed.
echo [*] Waiting for Ollama...
timeout /t 5 /nobreak >nul
echo.

:step3
:: [3/4] Download model and create it in Ollama
echo [3/4] Downloading AI model...

cd /d "%~dp0"
if not exist "models" mkdir "models"

:: Find ollama
set OLLAMA_CMD=ollama
where ollama >nul 2>&1
if %errorlevel% neq 0 (
    if exist "%LOCALAPPDATA%\Programs\Ollama\ollama.exe" (
        set "OLLAMA_CMD=%LOCALAPPDATA%\Programs\Ollama\ollama.exe"
    ) else if exist "%ProgramFiles%\Ollama\ollama.exe" (
        set "OLLAMA_CMD=%ProgramFiles%\Ollama\ollama.exe"
    ) else (
        echo [!] Cannot find ollama. Close this terminal, open a new one, re-run install.bat
        pause
        exit /b 1
    )
)

:: Start ollama serve
start /B "" %OLLAMA_CMD% serve >nul 2>&1
timeout /t 3 /nobreak >nul

:: Check if model already created
%OLLAMA_CMD% list 2>nul | findstr "camchat" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Model already set up.
    goto :step4
)

:: Download GGUF if not present
if exist "models\gemma4.gguf" (
    echo [OK] GGUF file already downloaded.
) else (
    echo [*] Downloading Gemma 4 Uncensored model (~5GB)...
    echo [*] This will take a few minutes.
    echo.
    curl -L --progress-bar -o "models\gemma4.gguf" "https://huggingface.co/llmfan46/gemma-4-E4B-it-uncensored-heretic-GGUF/resolve/main/gemma-4-E4B-it-uncensored-heretic-Q4_K_M.gguf"
    if not exist "models\gemma4.gguf" (
        echo [!] Download failed. Check your internet.
        pause
        exit /b 1
    )
    echo [OK] Model downloaded.
)

:: Create model in Ollama from Modelfile
echo [*] Importing model into Ollama...
%OLLAMA_CMD% create camchat -f Modelfile
if %errorlevel% neq 0 (
    echo [!] Model import failed.
    pause
    exit /b 1
)
echo [OK] Model "camchat" created in Ollama.
echo.

:step4
:: [4/4] Python deps
echo [4/4] Installing Python dependencies...
pip install flask requests markdown >nul 2>&1
echo [OK] Done.
echo.

:: Write config
echo {"backend":"ollama","model":"camchat","platform":"windows","web_port":5000}> "config.json"

echo.
echo  ======================================
echo   INSTALLATION COMPLETE
echo  ======================================
echo.
echo  To start: start.bat
echo  Web UI: http://localhost:5000
echo.
pause
