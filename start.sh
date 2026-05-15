#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$SCRIPT_DIR/venv"

echo ""
echo " ======================================"
echo "  WormGPT - LOCAL AI"
echo "  by camzzz"
echo " ======================================"
echo ""

cd "$SCRIPT_DIR"

# Detect backend from config
BACKEND="ollama"
if [ -f "config.json" ]; then
    BACKEND=$(python3 -c "import json;print(json.load(open('config.json'))['backend'])" 2>/dev/null || echo "ollama")
fi

# Also detect Termux
if [ -d "/data/data/com.termux" ]; then
    BACKEND="llamacpp"
fi

echo -e "${GREEN}[*]${NC} Backend: $BACKEND"

cleanup() {
    echo ""
    echo -e "${YELLOW}[*]${NC} Shutting down..."
    [ -n "$LLAMA_PID" ] && kill $LLAMA_PID 2>/dev/null
    exit 0
}
trap cleanup SIGINT SIGTERM

if [ "$BACKEND" == "llamacpp" ]; then
    # llama.cpp mode (Termux)
    if [ ! -f "bin/llama-server" ]; then
        echo -e "${RED}[!]${NC} llama-server not found. Run ./install.sh first."
        exit 1
    fi
    if [ ! -f "models/gemma4.gguf" ]; then
        echo -e "${RED}[!]${NC} Model not found. Run ./install.sh first."
        exit 1
    fi

    echo "[*] Starting llama-server (CPU mode)..."
    "$SCRIPT_DIR/bin/llama-server" \
        -m "$SCRIPT_DIR/models/gemma4.gguf" \
        --host 0.0.0.0 \
        --port 8080 \
        -c 2048 \
        -ngl 0 \
        > /dev/null 2>&1 &
    LLAMA_PID=$!

    echo -e "${YELLOW}[*]${NC} Waiting for server..."
    for i in $(seq 1 60); do
        if curl -s http://127.0.0.1:8080/health > /dev/null 2>&1; then
            echo -e "${GREEN}[OK]${NC} llama-server ready!"
            break
        fi
        sleep 1
    done

    if ! kill -0 $LLAMA_PID 2>/dev/null; then
        echo -e "${RED}[!]${NC} llama-server failed to start."
        exit 1
    fi
else
    # Ollama mode (Linux/macOS)
    if ! command -v ollama &> /dev/null; then
        echo -e "${RED}[!]${NC} Ollama not found. Run ./install.sh first."
        exit 1
    fi

    echo "[*] Starting Ollama..."
    ollama list &> /dev/null 2>&1 || {
        ollama serve &> /dev/null &
        sleep 3
    }

    echo "[*] Checking model..."
    if ! ollama list 2>/dev/null | grep -q "camchat"; then
        echo -e "${RED}[!]${NC} Model \"camchat\" not found. Run ./install.sh first."
        exit 1
    fi
    echo -e "${GREEN}[OK]${NC} Model ready."
fi

echo ""
echo " ======================================"
echo "  READY - http://localhost:5000"
echo "  Press Ctrl+C to stop"
echo " ======================================"
echo ""

if [ -d "$VENV_DIR" ]; then
    source "$VENV_DIR/bin/activate"
fi

export BACKEND="$BACKEND"
python3 "$SCRIPT_DIR/chatbot/app.py"
