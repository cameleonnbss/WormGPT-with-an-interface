#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="\( (cd " \)(dirname "$0")" && pwd)"

echo ""
echo " ======================================"
echo "  WormGPT - LOCAL AI INSTALLER"
echo "  by camzzz"
echo " ======================================"
echo ""

detect_platform() {
    if [ -d "/data/data/com.termux" ]; then
        echo "termux"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

PLATFORM=$(detect_platform)
echo -e "\( {GREEN}[*] \){NC} Platform: $PLATFORM"
echo ""

# [1/4] Python
echo "[1/4] Checking Python..."
if command -v python3 &> /dev/null; then
    echo -e "\( {GREEN}[OK] \){NC} Python found."
else
    echo -e "\( {YELLOW}[*] \){NC} Installing Python..."
    case "$PLATFORM" in
        termux) pkg install -y python ;;
        linux)
            if command -v apt-get &> /dev/null; then sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv
            elif command -v dnf &> /dev/null; then sudo dnf install -y python3 python3-pip
            elif command -v pacman &> /dev/null; then sudo pacman -Sy --noconfirm python python-pip
            fi ;;
        macos) brew install python ;;
    esac
    echo -e "\( {GREEN}[OK] \){NC} Python installed."
fi
echo ""

# [2/4] Backend
echo "[2/4] Setting up AI backend..."

if [ "$PLATFORM" == "termux" ]; then
    echo -e "\( {YELLOW}[*] \){NC} Termux detected - using llama.cpp"
    BACKEND="llamacpp"

    if [ -f "$INSTALL_DIR/bin/llama-server" ]; then
        echo -e "\( {GREEN}[OK] \){NC} llama-server already built."
    else
        echo -e "\( {YELLOW}[*] \){NC} Building llama.cpp..."
        pkg install -y libomp cmake make clang git
        cd /tmp
        rm -rf llama.cpp
        git clone --depth 1 https://github.com/ggml-org/llama.cpp.git
        cd llama.cpp
        cmake -B build -DCMAKE_BUILD_TYPE=Release
        cmake --build build --config Release -j$(nproc) --target llama-server
        mkdir -p "$INSTALL_DIR/bin"
        cp build/bin/llama-server "$INSTALL_DIR/bin/llama-server"
        cd "$INSTALL_DIR"
        rm -rf /tmp/llama.cpp
        echo -e "\( {GREEN}[OK] \){NC} llama-server built."
    fi
else
    BACKEND="ollama"
    if command -v ollama &> /dev/null; then
        echo -e "\( {GREEN}[OK] \){NC} Ollama already installed."
    else
        echo -e "\( {YELLOW}[*] \){NC} Installing Ollama..."
        if [ "$PLATFORM" == "macos" ]; then
            brew install ollama
        else
            curl -fsSL https://ollama.com/install.sh | sh
        fi
        echo -e "\( {GREEN}[OK] \){NC} Ollama installed."
    fi
fi
echo ""

# [3/4] Model
echo "[3/4] Downloading AI model..."
cd "$INSTALL_DIR"
mkdir -p models

if [ -f "models/gemma4.gguf" ]; then
    echo -e "\( {GREEN}[OK] \){NC} Model already downloaded."
else
    echo -e "\( {YELLOW}[*] \){NC} Downloading Gemma 4 Uncensored (\~5GB)..."
    curl -L --progress-bar -o "models/gemma4.gguf" \
    "https://huggingface.co/llmfan46/gemma-4-E4B-it-uncensored-heretic-GGUF/resolve/main/gemma-4-E4B-it-uncensored-heretic-Q4_K_M.gguf"
    echo -e "\( {GREEN}[OK] \){NC} Model downloaded."
fi
echo ""

# [4/4] Python deps + Config
echo "[4/4] Installing Python dependencies..."
if [ "$PLATFORM" == "termux" ]; then
    pip install flask requests markdown
else
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install flask requests markdown
fi

# Config final
cat > "$INSTALL_DIR/config.json" << EOF
{
  "backend": "$BACKEND",
  "model": "camchat",
  "platform": "$PLATFORM",
  "web_port": 5000,
  "llama_port": 11434,
  "context_size": 32768,
  "temperature": 0.85,
  "max_tokens": 2048
}
EOF

echo ""
echo " ======================================"
echo "  INSTALLATION COMPLETE !"
echo " ======================================"
echo ""
echo " Lance maintenant : ./start.sh"
echo " Interface → http://localhost:5000"
echo ""
