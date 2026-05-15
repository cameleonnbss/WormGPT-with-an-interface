#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${GREEN}========================================${NC}"
echo -e "       WormGPT - Installation"
echo -e "${GREEN}========================================${NC}"
echo ""

# Détection plateforme
if [[ "$OSTYPE" == "linux-android"* ]] || [ -d "/data/data/com.termux" ]; then
    PLATFORM="termux"
else
    PLATFORM="desktop"
fi

echo -e "${GREEN}[*]${NC} Plateforme détectée : $PLATFORM"

# Vérifier les dépendances
echo -e "${YELLOW}[*]${NC} Vérification des dépendances..."

check_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo -e "${RED}[!]${NC} $1 n'est pas installé."
        return 1
    fi
    echo -e "${GREEN}[OK]${NC} $1 trouvé"
    return 0
}

check_cmd python3 || exit 1
check_cmd curl || exit 1

# Créer l'environnement virtuel
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}[*]${NC} Création du venv..."
    python3 -m venv venv
fi

source venv/bin/activate

echo -e "${YELLOW}[*]${NC} Installation des dépendances Python..."
pip install --upgrade pip >/dev/null 2>&1
pip install flask requests >/dev/null 2>&1

echo -e "${GREEN}[OK]${NC} Dépendances Python installées"

# Téléchargement llama.cpp (desktop uniquement)
if [ "$PLATFORM" = "desktop" ]; then
    if [ ! -f "bin/llama-server" ]; then
        echo -e "${YELLOW}[*]${NC} Téléchargement de llama-server..."
        mkdir -p bin
        
        # Détection architecture
        ARCH=$(uname -m)
        if [ "$ARCH" = "x86_64" ]; then
            LLAMA_URL="https://github.com/ggerganov/llama.cpp/releases/download/b3946/llama-b3946-bin-ubuntu-x64.zip"
        elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
            LLAMA_URL="https://github.com/ggerganov/llama.cpp/releases/download/b3946/llama-b3946-bin-ubuntu-arm64.zip"
        else
            echo -e "${YELLOW}[!]${NC} Architecture $ARCH non supportée pour le binaire précompilé."
            echo -e "    Compilation manuelle nécessaire."
            exit 1
        fi
        
        curl -L -o /tmp/llama.zip "$LLAMA_URL" 2>/dev/null
        unzip -q /tmp/llama.zip -d /tmp/llama_extract
        cp /tmp/llama_extract/build/bin/llama-server bin/llama-server 2>/dev/null || \
        cp /tmp/llama_extract/bin/llama-server bin/llama-server 2>/dev/null || \
        find /tmp/llama_extract -name "llama-server" -exec cp {} bin/llama-server \;
        chmod +x bin/llama-server
        rm -rf /tmp/llama.zip /tmp/llama_extract
        echo -e "${GREEN}[OK]${NC} llama-server installé"
    else
        echo -e "${GREEN}[OK]${NC} llama-server déjà présent"
    fi
fi

# Téléchargement du modèle
mkdir -p models
if [ ! -f "models/gemma4.gguf" ]; then
    echo -e "${YELLOW}[*]${NC} Téléchargement du modèle Gemma 4B..."
    echo -e "${BLUE}    Cela peut prendre quelques minutes...${NC}"
    
    # URL du modèle (à adapter selon ton modèle exact)
    MODEL_URL="https://huggingface.co/google/gemma-2-2b-it/resolve/main/gemma-2-2b-it-Q4_K_M.gguf"
    
    curl -L --progress-bar -o models/gemma4.gguf "$MODEL_URL" || {
        echo -e "${RED}[!]${NC} Échec du téléchargement du modèle."
        echo -e "    Télécharge manuellement le .gguf dans le dossier models/"
        exit 1
    }
    echo -e "${GREEN}[OK]${NC} Modèle téléchargé"
else
    echo -e "${GREEN}[OK]${NC} Modèle déjà présent"
fi

# Création du config.json
if [ ! -f "config.json" ]; then
    cat > config.json << 'EOF'
{
    "backend": "llamacpp",
    "model_path": "models/gemma4.gguf",
    "host": "0.0.0.0",
    "port": 5000
}
EOF
    echo -e "${GREEN}[OK]${NC} config.json créé"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "   ${GREEN}Installation terminée !${NC}"
echo -e ""
echo -e "   Lance avec : ${YELLOW}./start.sh${NC}"
echo -e "${GREEN}========================================${NC}"
