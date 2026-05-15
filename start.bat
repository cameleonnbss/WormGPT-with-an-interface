@echo off
chcp 65001 >nul
color 0a
echo.
echo ========================================
echo          WormGPT - LOCAL AI
echo ========================================
echo.

cd /d "%\~dp0"

:: Détection backend
set BACKEND=ollama
if exist config.json (
    for /f "tokens=*" %%a in ('powershell -NoProfile -Command "Get-Content config.json | ConvertFrom-Json | Select-Object -ExpandProperty backend"') do set BACKEND=%%a
)

echo [INFO] Backend détecté : %BACKEND%

if "%BACKEND%"=="llamacpp" (
    echo [INFO] Démarrage llama.cpp sur port 11434...
    if not exist bin\llama-server.exe (
        echo [ERREUR] llama-server manquant. Lance install.bat d'abord.
        pause
        exit
    )
    start /b "" bin\llama-server.exe -m models\gemma4.gguf --host 0.0.0.0 --port 11434 -c 16384 --n-gpu-layers 35 >nul 2>&1
) else (
    echo [INFO] Démarrage Ollama...
    start /b ollama serve
    timeout /t 4 >nul
)

echo.
echo ========================================
echo     Interface → http://localhost:5000
echo     Ctrl+C pour arrêter
echo ========================================
echo.

if exist venv (
    call venv\Scripts\activate.bat
)

set BACKEND=%BACKEND%
python chatbot\app.py

pause
