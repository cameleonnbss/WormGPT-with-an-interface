#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo " ======================================"
echo "  CAMCHAT - LOCAL AI INSTALLER"
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
echo -e "${GREEN}[*]${NC} Platform: $PLATFORM"
echo ""

# [1/4] Check Python
echo "[1/4] Checking Python..."
if command -v python3 &> /dev/null; then
    echo -e "${GREEN}[OK]${NC} Python found."
else
    echo -e "${YELLOW}[*]${NC} Installing Python..."
    case "$PLATFORM" in
        termux) pkg install -y python ;;
        linux)
            if command -v apt-get &> /dev/null; then sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv
            elif command -v dnf &> /dev/null; then sudo dnf install -y python3 python3-pip
            elif command -v pacman &> /dev/null; then sudo pacman -Sy --noconfirm python python-pip
            fi ;;
        macos) brew install python ;;
    esac
    echo -e "${GREEN}[OK]${NC} Python installed."
fi
echo ""

# [2/4] Install backend
echo "[2/4] Setting up AI backend..."

if [ "$PLATFORM" == "termux" ]; then
    # Termux: Ollama not available, use llama.cpp
    echo -e "${YELLOW}[*]${NC} Termux detected - using llama.cpp backend"
    BACKEND="llamacpp"

    if [ -f "$INSTALL_DIR/bin/llama-server" ]; then
        echo -e "${GREEN}[OK]${NC} llama-server already built."
    else
        echo -e "${YELLOW}[*]${NC} Building llama.cpp from source (this takes ~5 min)..."
        pkg install -y cmake make clang git
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
        echo -e "${GREEN}[OK]${NC} llama-server built."
    fi
else
    # Linux/macOS: use Ollama
    BACKEND="ollama"

    if command -v ollama &> /dev/null; then
        echo -e "${GREEN}[OK]${NC} Ollama already installed."
    else
        echo -e "${YELLOW}[*]${NC} Installing Ollama..."
        if [ "$PLATFORM" == "macos" ]; then
            brew install ollama
        else
            curl -fsSL https://ollama.com/install.sh | sh
        fi
        echo -e "${GREEN}[OK]${NC} Ollama installed."
    fi
fi
echo ""

# [3/4] Download model
echo "[3/4] Downloading AI model..."

cd "$INSTALL_DIR"
mkdir -p models

download_model() {
    if [ -f "models/gemma4.gguf" ]; then
        echo -e "${GREEN}[OK]${NC} Model file already downloaded."
        return
    fi
    echo -e "${YELLOW}[*]${NC} Downloading Gemma 4 Uncensored model (~5GB)..."
    echo -e "${YELLOW}[*]${NC} This will take a few minutes."
    echo ""
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O "models/gemma4.gguf" "https://huggingface.co/llmfan46/gemma-4-E4B-it-uncensored-heretic-GGUF/resolve/main/gemma-4-E4B-it-uncensored-heretic-Q4_K_M.gguf"
    elif command -v curl &> /dev/null; then
        curl -L --progress-bar -o "models/gemma4.gguf" "https://huggingface.co/llmfan46/gemma-4-E4B-it-uncensored-heretic-GGUF/resolve/main/gemma-4-E4B-it-uncensored-heretic-Q4_K_M.gguf"
    else
        echo -e "${RED}[!]${NC} Neither wget nor curl found."
        exit 1
    fi
    if [ ! -f "models/gemma4.gguf" ]; then
        echo -e "${RED}[!]${NC} Download failed. Check your internet."
        exit 1
    fi
    echo -e "${GREEN}[OK]${NC} Model downloaded."
}

if [ "$BACKEND" == "ollama" ]; then
    # Start ollama serve if not running
    ollama list &> /dev/null 2>&1 || {
        echo -e "${YELLOW}[*]${NC} Starting Ollama..."
        ollama serve &> /dev/null &
        sleep 3
    }

    if ollama list 2>/dev/null | grep -q "camchat"; then
        echo -e "${GREEN}[OK]${NC} Model already set up in Ollama."
    else
        download_model
        echo -e "${YELLOW}[*]${NC} Importing model into Ollama..."
        ollama create camchat -f Modelfile
        if [ $? -ne 0 ]; then
            echo -e "${RED}[!]${NC} Model import failed."
            exit 1
        fi
        echo -e "${GREEN}[OK]${NC} Model \"camchat\" created in Ollama."
    fi
else
    # Termux: just download the GGUF
    download_model
fi
echo ""

# [4/4] Python deps
echo "[4/4] Installing Python dependencies..."
VENV_DIR="$INSTALL_DIR/venv"

if [ "$PLATFORM" == "termux" ]; then
    pip install flask requests markdown
else
    python3 -m venv "$VENV_DIR"
    source "$VENV_DIR/bin/activate"
    pip install --upgrade pip
    pip install flask requests markdown
fi
echo -e "${GREEN}[OK]${NC} Done."
echo ""

# Write config
cat > "$INSTALL_DIR/config.json" << EOF
{"backend":"$BACKEND","model":"camchat","platform":"$PLATFORM","web_port":5000}
EOF

echo ""
echo " ======================================"
echo "  INSTALLATION COMPLETE"
echo " ======================================"
echo ""
echo " To start: ./start.sh"
echo " Web UI: http://localhost:5000"
echo ""
