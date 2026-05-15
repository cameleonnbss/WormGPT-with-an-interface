

---

**WormGPT interface**

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

**Gemma 4 E4B Uncensored Heretic** (Q4_K_M, ~5.4 GB)

| Spec | Value |
|------|-------|
| Architecture | Gemma 4 |
| Parameters | 7.5B |
| Context | 131072 tokens |
| Quantization | Q4_K_M (5.66 BPW) |
| File size | ~5.4 GB |

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
pkg install -y git python clang cmake make libomp

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

### Step 3: Download the Model (corrigé)

```bash
# Create models directory
mkdir -p models

# Download Gemma 4 E4B Uncensored Heretic (~5.4GB)
cd models
curl -L -o gemma4.gguf "https://huggingface.co/mradermacher/gemma-4-E4B-it-ultra-uncensored-heretic-GGUF/resolve/main/gemma-4-E4B-it-ultra-uncensored-heretic.Q4_K_M.gguf"
cd ..
```

### Step 5: Create Configuration File (corrigé)

```json
{
  "backend": "ollama",
  "model": "camchat",
  "platform": "desktop",
  "web_port": 5000,
  "llama_port": 11434,
  "context_size": 32768,
  "temperature": 0.85,
  "max_tokens": 2048
}
```

---

## Platform Support

| Platform | Backend     | GPU Support                  | Notes                          |
|----------|-------------|------------------------------|--------------------------------|
| Windows  | Ollama      | NVIDIA (CUDA), AMD (Vulkan)  | Recommended                    |
| Linux    | Ollama      | NVIDIA (CUDA), AMD (ROCm)    | Recommended                    |
| macOS    | Ollama      | Apple Silicon (Metal)        | Recommended                    |
| Termux   | llama.cpp   | CPU only                     | Context limited (~8k-16k max)  |

## Project Structure

```
WormGPT-with-an-interface/
├── install.sh / install.bat
├── start.sh / start.bat
├── Modelfile
├── system_prompt.txt
├── config.json
├── chatbot/
│   ├── app.py
│   └── templates/index.html
├── models/gemma4.gguf
└── venv/ (Linux/macOS)
```

---

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
