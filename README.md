# Code Local 16GB

Run large language models locally on your **Mac Mini M4 (16 GB RAM)** and connect from any device on your network — Windows, Linux, or another Mac.

**No cloud. No API fees. Your data never leaves your home network.**

## What is this?

A project optimized for **16 GB Apple Silicon Macs** that curates **14B-parameter models** fitting comfortably in unified memory while maximizing code quality and minimizing hallucinations.

| Model | Size | RAM Used | Best For |
|-------|------|----------|----------|
| **Phi-4 14B** ⭐ | ~7.7 GB | ~10 GB | **Lowest hallucinations**, general coding |
| **Qwen3 14B** | ~8.3 GB | ~11 GB | Long context, large codebases |
| **Qwen2.5 Coder 14B** | ~8 GB | ~11 GB | Code-specific tasks, refactoring |
| **DeepSeek-R1-Distill-Qwen-14B** | ~8 GB | ~11 GB | Reasoning, math, complex debugging |

> ⭐ **Recommended:** Phi-4 14B scores highest on formal hallucination benchmarks and runs comfortably within 16 GB.

## How it works

```
┌─────────────────┐      HTTP (WiFi/Ethernet)      ┌─────────────────────┐
│  Your Computer  │  ─────────────────────────────► │   Mac Mini M4       │
│  (Windows/Mac)  │                                 │   MLX Manager       │
│  Open WebUI     │  ◄───────────────────────────── │   4 models loaded   │
└─────────────────┘                                 └─────────────────────┘
```

The Mac Mini runs **[MLX Manager](https://github.com/tumma72/mlx-manager)** — a professional tool that manages MLX models and exposes an **OpenAI-compatible API**. Your computer connects to it like any other AI service — but everything happens inside your home.

### Why MLX Manager?

- **Web UI** for one-click model download and management
- **Automatic model switching** — select any model in Open WebUI, MLX Manager loads it automatically
- **LRU memory management** — unloads unused models to stay within 16 GB
- **Auto-start on boot** — no Terminal window needed
- **Real-time metrics** — memory usage, tokens/sec, queue depth

## Requirements

- **Mac with Apple Silicon** (M1/M2/M3/M4)
- **16 GB unified memory** (also works on 8 GB and 32 GB)
- **macOS Sonoma or later**
- **Xcode Command Line Tools** (for `git`; install with `xcode-select --install`)
- **Python 3.11 or 3.12**

## Mac Mini Setup (Server)

### 1. Clone the repository

```bash
git clone https://github.com/alex-milla/Code-Local-16Gb.git
cd Code-Local-16Gb
```

> If `git` is not found, install Xcode Command Line Tools first: `xcode-select --install`

### 2. Install MLX Manager

```bash
bash scripts/install-mlx-manager.sh
```

This creates a dedicated virtual environment and installs MLX Manager.

### 3. Start the server

**Manual (for testing):**
```bash
source ~/.local/mlx-manager-venv/bin/activate
mlx-manager serve --host 0.0.0.0 --port 4000
```

**Auto-start on boot:**
```bash
source ~/.local/mlx-manager-venv/bin/activate
mlx-manager install-service
```

The server listens on all network interfaces (`0.0.0.0:4000`) so other devices can connect.

### 4. Download models

Open `http://YOUR_MAC_IP:4000` in a browser on the Mac Mini:
1. **Register** — create an account (first user becomes admin)
2. Go to **Models** → **Browse**
3. Search for and download each model:
   - `mlx-community/phi-4-4bit`
   - `mlx-community/Qwen3-14B-4bit`
   - `mlx-community/Qwen2.5-Coder-14B-Instruct-4bit`
   - `mlx-community/DeepSeek-R1-Distill-Qwen-14B-4bit`

> Models previously downloaded via `mlx-lm` in `~/.cache/huggingface/hub/` may be detected automatically.

### Server control

| Command | Description |
|---------|-------------|
| `mlx-manager serve --host 0.0.0.0 --port 4000` | Start manually |
| `mlx-manager install-service` | Enable auto-start |
| `mlx-manager status` | Show running servers |
| `launchctl unload ~/Library/LaunchAgents/com.mlx-manager.plist` | Stop auto-start |

For detailed configuration, memory tuning, and troubleshooting, see [docs/MLX-MANAGER.md](docs/MLX-MANAGER.md).

---

## Client Setup (Windows / Linux / Mac)

### Recommended client: Open WebUI

Open WebUI is a web-based chat interface that connects to any OpenAI-compatible API.

1. **Install Open WebUI** on your client computer (see [Open WebUI docs](https://docs.openwebui.com/))
2. **Open Settings** → **Admin Settings** → **Connections**
3. **Add a Direct Connection** (OpenAI Compatible):
   - **URL:** `http://YOUR_MAC_IP:4000/v1`
   - **Auth:** Bearer `sk-local`
   - **Provider Type:** OpenAI
4. **Save** and reload

All 4 models will appear in the chat dropdown: `phi-4`, `qwen3-14b`, `qwen2.5-coder-14b`, and `deepseek-r1-14b`.

**MLX Manager automatically switches models** when you select a different one in Open WebUI. It unloads the previous model from memory before loading the new one to stay within the 16 GB budget. The switch takes ~10–30 seconds depending on the model size.

> **Note:** If the requested model has never been downloaded, MLX Manager will fetch it from HuggingFace automatically on first use. This may take several minutes. Pre-download models via the MLX Manager web UI to avoid waiting.

---

## Memory tips for 16 GB Macs

- **Close browsers and heavy apps** on the Mac Mini before loading large models
- **Set memory limits** in MLX Manager to prevent OOM:
  ```bash
  export MLX_SERVER_MAX_MEMORY_GB=12
  export MLX_SERVER_MAX_MODELS=2
  ```
- **Restart MLX Manager** between very long sessions to free accumulated KV cache

---

## Updating

To update MLX Manager to the latest version:

```bash
source ~/.local/mlx-manager-venv/bin/activate
pip install --upgrade mlx-manager
```

---

## Project Structure

```
Code-Local-16Gb/
 ├── docs/
 │    └── MLX-MANAGER.md       ← Detailed MLX Manager guide
 ├── scripts/
 │    └── install-mlx-manager.sh ← One-command installer
 ├── proxy/server.py           ← Legacy custom server (preserved)
 └── README.md
```

---

## License

MIT
