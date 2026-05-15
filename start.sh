#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="\( (cd " \)(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "\( {GREEN}======================================== \){NC}"
echo -e "         WormGPT - LOCAL AI"
echo -e "\( {GREEN}======================================== \){NC}"

# Détection plateforme
if [[ "$OSTYPE" == "linux-android"* ]] || [ -d "/data/data/com.termux" ]; then
    PLATFORM="termux"
    BACKEND="llamacpp"
else
    PLATFORM="desktop"
    # Par défaut Ollama si disponible, sinon llama.cpp
    if command -v ollama >/dev/null 2>&1; then
        BACKEND="ollama"
    else
        BACKEND="llamacpp"
    fi
fi

# Charger config si elle existe
if [ -f "config.json" ]; then
    CONFIG_BACKEND=$(python3 -c "
import json
try:
    with open('config.json') as f:
        print(json.load(f).get('backend', '$BACKEND'))
except:
    print('$BACKEND')
" 2>/dev/null || echo "$BACKEND")
    BACKEND="$CONFIG_BACKEND"
fi

echo -e "\( {GREEN}[*] \){NC} Plateforme : $PLATFORM | Backend : $BACKEND"

cleanup() {
    echo -e "\n\( {YELLOW}[*] \){NC} Arrêt en cours..."
    kill $(jobs -p) 2>/dev/null || true
    exit 0
}
trap cleanup SIGINT SIGTERM

# === Lancement du backend ===
if [ "$BACKEND" = "llamacpp" ]; then
    echo -e "\( {YELLOW}[*] \){NC} Démarrage llama.cpp sur port 11434 (compatible Ollama)..."

    if [ ! -f "bin/llama-server" ] || [ ! -f "models/gemma4.gguf" ]; then
        echo -e "\( {RED}[!] \){NC} Modèle ou llama-server manquant. Exécute ./install.sh d'abord."
        exit 1
    fi

    "$SCRIPT_DIR/bin/llama-server" \
        -m "$SCRIPT_DIR/models/gemma4.gguf" \
        --host 0.0.0.0 \
        --port 11434 \
        -c 16384 \                  # Context raisonnable (ajuste selon ta RAM)
        --n-gpu-layers 0 \          # Termux = 0, sur desktop tu peux mettre 40+
        > /dev/null 2>&1 &

    LLAMA_PID=$!

    # Health check
    for i in {1..40}; do
        if curl -s http://127.0.0.1:11434/health >/dev/null 2>&1; then
            echo -e "\( {GREEN}[OK] \){NC} llama-server prêt sur port 11434"
            break
        fi
        sleep 1
    done
else
    # Mode Ollama (Windows/Linux/macOS)
    echo -e "\( {YELLOW}[*] \){NC} Démarrage Ollama..."
    ollama serve >/dev/null 2>&1 &
    sleep 4

    if ! ollama list | grep -q "camchat"; then
        echo -e "\( {RED}[!] \){NC} Modèle 'camchat' non trouvé dans Ollama."
        echo "Exécute ollama create camchat -f Modelfile"
        exit 1
    fi
    echo -e "\( {GREEN}[OK] \){NC} Ollama + camchat prêt"
fi

echo -e "\n\( {GREEN}======================================== \){NC}"
echo -e "     🚀 Interface disponible sur → http://localhost:5000"
echo -e "\( {GREEN}======================================== \){NC}"

# Lancement Flask
if [ -d "venv" ]; then
    source venv/bin/activate 2>/dev/null || true
fi

export BACKEND="$BACKEND"
python3 chatbot/app.py
