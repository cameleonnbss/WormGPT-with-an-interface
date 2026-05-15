**WormGPT interface*

```
░██       ░██                                       ░██████  ░█████████  ░██████████
░██       ░██                                      ░██   ░██ ░██     ░██     ░██    
░██  ░██  ░██  ░███████  ░██░████ ░█████████████  ░██        ░██     ░██     ░██    
░██ ░████ ░██ ░██    ░██ ░███     ░██   ░██   ░██ ░██  █████ ░█████████      ░██    
░██░██ ░██░██ ░██    ░██ ░██      ░██   ░██   ░██ ░██     ██ ░██             ░██    
░████   ░████ ░██    ░██ ░██      ░██   ░██   ░██  ░██  ░███ ░██             ░██    
░███     ░███  ░███████  ░██      ░██   ░██   ░██   ░█████░█ ░██             ░██    
                                                                                    
                                                                                    
                                                                                    
```

**Self-hosted uncensored Local AI Chatbot by camzzz**

100% local inference — no data sent anywhere. Runs on Windows, Linux, macOS, and Termux (Android).

## Model

**Gemma 4 E4B Uncensored Heretic** (Q4_K_M, ~5GB)

| Spec | Value |
|------|-------|
| Architecture | Gemma 4 |
| Parameters | 7.5B |
| Context | 131072 tokens |
| Quantization | Q4_K_M (5.66 BPW) |
| File size | ~5 GB |

## Features

- Modern dark web UI with glassmorphism design
- Real-time token-by-token streaming (SSE)
- Auto GPU detection & offloading
- Editable system prompt (live from web UI or file)
- Chat history export & reload
- Adjustable temperature and max tokens
- Copy button on AI responses
- Mobile responsive (hamburger menu, touch-friendly)
- Cross-platform: Windows, Linux, macOS, Termux

## Quick Start

### WINDOWS (PowerShell as Administrator)

```powershell
# 1. Clone the repository
git clone https://github.com/cameleonnbss/WormGPT-with-an-interface.git
cd WormGPT-with-an-interface

# 2. Run the installer
.\install.bat

# 3. Start WormGPT
.\start.bat
```

### LINUX / macOS (Terminal)

```bash
# 1. Clone the repository
git clone https://github.com/cameleonnbss/WormGPT-with-an-interface.git
cd WormGPT-with-an-interface

# 2. Make scripts executable
chmod +x install.sh start.sh

# 3. Run the installer
./install.sh

# 4. Start WormGPT
./start.sh
```

### TERMUX (Android)

```bash
# 1. Update packages
pkg update && pkg upgrade -y

# 2. Install dependencies
pkg install -y git python clang cmake build-essential

# 3. Clone the repository
git clone https://github.com/cameleonnbss/WormGPT-with-an-interface.git
cd WormGPT-with-an-interface

# 4. Make scripts executable
chmod +x install.sh start.sh

# 5. Run the installer
./install.sh

# 6. Start WormGPT
./start.sh
```

---

## 🚀 MANUAL INSTALLATION (If scripts fail)

### Step 1: Install Python

**Windows:**
```powershell
winget install Python.Python.3.12
```

**Linux:**
```bash
sudo apt update && sudo apt install python3 python3-pip python3-venv -y
```

**macOS:**
```bash
brew install python@3.12
```

### Step 2: Install Backend (Ollama or llama.cpp)

**Option A - Ollama (Recommended for GPU):**

```bash
# Windows
winget install Ollama.Ollama

# Linux/macOS
curl -fsSL https://ollama.com/install.sh | sh

# Termux - use llama.cpp instead
```

**Option B - llama.cpp (For Termux / CPU only):**

```bash
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp
mkdir build && cd build
cmake .. -DLLAMA_CUBLAS=OFF  # Set ON for NVIDIA GPU
cmake --build . --config Release -j$(nproc)
```

### Step 3: Download the Model

```bash
# Create models directory
mkdir -p models

# Download Gemma 4 E4B Uncensored Heretic (~5GB)
cd models
curl -L -o gemma-4-heretic.Q4_K_M.gguf "https://huggingface.co/bartowski/Gemma-4-E4B-Heretic-GGUF/resolve/main/Gemma-4-E4B-Heretic.Q4_K_M.gguf"
cd ..
```

### Step 4: Install Python Dependencies

```bash
# Create virtual environment
python -m venv venv

# Activate the environment
# Windows:
venv\Scripts\activate
# Linux/macOS/Termux:
source venv/bin/activate

# Install Flask and dependencies
pip install flask flask-cors requests
```

### Step 5: Create Configuration File

Create `config.json`:

```json
{
    "model_path": "models/gemma-4-heretic.Q4_K_M.gguf",
    "backend": "ollama",
    "context_size": 131072,
    "temperature": 0.85,
    "max_tokens": 1500,
    "port": 5000,
    "gpu_layers": 33,
    "threads": 8
}
```

### Step 6: Launch Manually

```bash
# Start Ollama (if using)
ollama serve &

# Launch web interface
python chatbot/app.py
```

---



# Activate virtual environment
source venv/bin/activate

# Launch web interface
echo "[*] Starting server on http://localhost:5000

Then open **http://localhost:5000** in your browser.

## What the installer does

| Step | Windows | Linux/macOS | Termux |
|------|---------|-------------|--------|
| 1 | Check Python | Check Python | Install Python via pkg |
| 2 | Install Ollama (winget) | Install Ollama (curl) | Build llama.cpp from source |
| 3 | Download GGUF model (~5GB) | Download GGUF model | Download GGUF model |
| 4 | Import into Ollama | Import into Ollama | Ready (llama.cpp loads GGUF directly) |
| 5 | Install Flask + deps | Install Flask + venv | Install Flask + deps |

No manual configuration needed. Everything is automatic.

## Platform Support

| Platform | Backend | GPU Support | Notes |
|----------|---------|-------------|-------|
| Windows | Ollama | NVIDIA (CUDA), AMD (Vulkan) | Requires winget or manual Ollama install |
| Linux | Ollama | NVIDIA (CUDA), AMD (ROCm) | Automatic via install script |
| macOS | Ollama | Apple Silicon (Metal) | Via Homebrew |
| Termux | llama.cpp | CPU only | Built from source, context limited to 2048 |

## Requirements

- ~6GB disk space (model + backend)
- 8GB+ RAM recommended (4GB minimum)
- Python 3.8+
- Internet connection (for install only)
- GPU recommended but not required

## Configuration

### System Prompt

Edit the AI's personality:
- Click **Settings** in the web UI
- Or edit `system_prompt.txt` directly

Changes apply immediately — no restart needed.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `WEB_PORT` | `5000` | Web interface port |
| `BACKEND` | `ollama` | Backend (`ollama` or `llamacpp`) |

## Project Structure

```
CamChat/
├── install.sh / install.bat     # Auto-installer (detects OS)
├── start.sh / start.bat         # Launch script
├── Modelfile                    # Ollama model import definition
├── system_prompt.txt            # Editable AI personality
├── config.json                  # Auto-generated config
├── chatbot/
│   ├── app.py                   # Flask backend (SSE streaming)
│   ├── requirements.txt
│   └── templates/
│       └── index.html           # Web UI (responsive)
├── models/                      # GGUF file (downloaded by installer)
├── history/                     # Exported conversations
└── venv/                        # Python venv (Linux/macOS only)
```

## How It Works

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│  Browser    │────▶│  Flask App   │────▶│  Ollama / llama  │
│  (port 5000)│◀────│  (SSE stream)│◀────│  (inference)     │
└─────────────┘     └──────────────┘     └─────────────────┘
```

1. Installer downloads the GGUF model and sets up the backend
2. `start` launches the inference server + web UI
3. Flask proxies chat requests to the backend API
4. Responses stream back token-by-token via SSE

## License

MIT

---

*Built by [camzzz](https://github.com/cameleonnbss)*
discord: cameleonmortis_new
