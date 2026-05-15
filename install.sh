#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$INSTALL_DIR"

echo -e "${GREEN}========================================${NC}"
echo -e "     WormGPT - LOCAL AI INSTALLER"
echo -e "${GREEN}========================================${NC}"
echo ""

# Détection plateforme
if [ -d "/data/data/com.termux" ]; then
    PLATFORM="termux"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    PLATFORM="linux"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    PLATFORM="macos"
else
    PLATFORM="unknown"
fi

echo -e "${GREEN}[*]${NC} Plateforme détectée : $PLATFORM"

# Python
echo -e "\n${YELLOW}[1/4]${NC} Configuration Python..."
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}[*]${NC} Installation Python..."
    case "$PLATFORM" in
        termux) pkg install -y python ;;
        linux)
            sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv || \
            sudo dnf install -y python3 python3-pip || \
            sudo pacman -Sy --noconfirm python python-pip ;;
        macos) brew install python ;;
    esac
fi

# Backend
echo -e "\n${YELLOW}[2/4]${NC} Installation du backend..."
if [ "$PLATFORM" == "termux" ]; then
    BACKEND="llamacpp"
    echo -e "${YELLOW}[*]${NC} Construction llama.cpp..."
    pkg install -y libomp cmake make clang git
    if [ ! -f "bin/llama-server" ]; then
        cd /tmp && rm -rf llama.cpp
        git clone --depth 1 https://github.com/ggml-org/llama.cpp.git
        cd llama.cpp
        cmake -B build -DCMAKE_BUILD_TYPE=Release
        cmake --build build --config Release -j$(nproc) --target llama-server
        mkdir -p "$INSTALL_DIR/bin"
        cp build/bin/llama-server "$INSTALL_DIR/bin/llama-server"
        cd "$INSTALL_DIR"
        rm -rf /tmp/llama.cpp
    fi
else
    BACKEND="ollama"
    if ! command -v ollama &> /dev/null; then
        echo -e "${YELLOW}[*]${NC} Installation Ollama..."
        if [ "$PLATFORM" == "macos" ]; then
            brew install ollama
        else
            curl -fsSL https://ollama.com/install.sh | sh
        fi
    fi
fi

# Modèle
echo -e "\n${YELLOW}[3/4]${NC} Téléchargement du modèle Gemma 4 E4B Uncensored Heretic..."
mkdir -p models
if [ ! -f "models/gemma4.gguf" ]; then
    echo -e "${YELLOW}[*]${NC} Download ~5.4 GB (Q4_K_M)..."
    curl -L --progress-bar -o "models/gemma4.gguf" \
    "https://huggingface.co/mradermacher/gemma-4-E4B-it-ultra-uncensored-heretic-GGUF/resolve/main/gemma-4-E4B-it-ultra-uncensored-heretic.Q4_K_M.gguf"
else
    echo -e "${GREEN}[OK]${NC} Modèle déjà présent"
fi

# Python deps + Config
echo -e "\n${YELLOW}[4/4]${NC} Installation dépendances Python..."
if [ "$PLATFORM" == "termux" ]; then
    pip install flask requests markdown
else
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip
    pip install flask requests markdown
fi

# Configuration finale
cat > config.json << EOF
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

echo -e "\n${GREEN}========================================${NC}"
echo -e "     INSTALLATION TERMINÉE AVEC SUCCÈS !"
echo -e "${GREEN}========================================${NC}"
echo -e "\nLance maintenant : ./start.sh"
echo -e "Interface → http://localhost:5000"
