#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="\( (cd " \)(dirname "$0")" && pwd)"

echo -e "\( {GREEN}======================================== \){NC}"
echo -e "     WormGPT - LOCAL AI INSTALLER"
echo -e "\( {GREEN}======================================== \){NC}"
echo ""

# Détection plateforme
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
echo -e "\( {GREEN}[*] \){NC} Plateforme détectée : $PLATFORM"

# Python
echo -e "\n\( {YELLOW}[1/4] \){NC} Vérification Python..."
if ! command -v python3 &> /dev/null; then
    echo -e "\( {YELLOW}[*] \){NC} Installation de Python..."
    case "$PLATFORM" in
        termux) pkg install -y python ;;
        linux)
            if command -v apt-get &> /dev/null; then sudo apt-get update && sudo apt-get install -y python3 python3-pip python3-venv
            elif command -v dnf &> /dev/null; then sudo dnf install -y python3 python3-pip
            elif command -v pacman &> /dev/null; then sudo pacman -Sy --noconfirm python python-pip
            fi ;;
        macos) brew install python ;;
    esac
fi
echo -e "\( {GREEN}[OK] \){NC} Python OK"

# Backend
echo -e "\n\( {YELLOW}[2/4] \){NC} Installation du backend..."
if [ "$PLATFORM" == "termux" ]; then
    BACKEND="llamacpp"
    echo -e "\( {YELLOW}[*] \){NC} Construction de llama.cpp (Termux)..."
    pkg install -y libomp cmake make clang git
    # (le reste du build reste identique à ta version actuelle)
else
    BACKEND="ollama"
    if ! command -v ollama &> /dev/null; then
        echo -e "\( {YELLOW}[*] \){NC} Installation d'Ollama..."
        if [ "$PLATFORM" == "macos" ]; then
            brew install ollama
        else
            curl -fsSL https://ollama.com/install.sh | sh
        fi
    fi
fi

# Model + Python deps + Config (je peux te le compléter si tu veux, mais pour l'instant tu peux garder ta partie actuelle qui est bonne)

echo -e "\n\( {GREEN}Installation terminée ! \){NC}"
echo "Lance maintenant : ./start.sh"
