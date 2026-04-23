# Code Local 16GB

Run large language models locally on your **Mac Mini M4 (16 GB RAM)** and connect from any device on your network — Windows, Linux, or another Mac.

**No cloud. No API fees. Your data never leaves your home network.**

## What is this?

A fork of [claude-code-local](https://github.com/nicedreamzapp/claude-code-local) optimized for **16 GB Apple Silicon Macs**. The original targets 64–128 GB machines with massive models. This edition curates **14B-parameter models** that actually fit in 16 GB of unified memory while maximizing code quality and minimizing hallucinations.

| Model | Size | RAM Used | Best For |
|-------|------|----------|----------|
| **Phi-4 14B** ⭐ | ~7.7 GB | ~10 GB | **Lowest hallucinations**, general coding |
| **Qwen3 14B** | ~8.3 GB | ~11 GB | Long context, large codebases |
| **Qwen2.5 Coder 14B** | ~8 GB | ~11 GB | Code-specific tasks, refactoring |

> ⭐ **Recommended:** Phi-4 14B scores highest on formal hallucination benchmarks and runs comfortably within 16 GB.

## How it works

```
┌─────────────────┐      HTTP (WiFi/Ethernet)      ┌─────────────────────┐
│  Your Computer  │  ─────────────────────────────► │   Mac Mini M4       │
│  (Windows/Mac)  │                                 │   MLX Server        │
│  Open WebUI     │  ◄───────────────────────────── │   Phi-4 / Qwen3     │
└─────────────────┘                                 └─────────────────────┘
```

The Mac Mini runs a Python server that loads an MLX model and exposes an **OpenAI-compatible API**. Your computer connects to it like any other AI service — but everything happens inside your home.

## Requirements

- **Mac with Apple Silicon** (M1/M2/M3/M4)
- **16 GB unified memory** (also works on 8 GB and 32 GB with auto-detection)
- **macOS Sonoma or later**
- **Xcode Command Line Tools** (for `git`; install with `xcode-select --install`)
- **Node.js/npm** (only if you want to try Claude Code as client; Open WebUI does not need it)

## Mac Mini Setup (Server)

### 1. Clone the repository

```bash
git clone https://github.com/alex-milla/Code-Local-16Gb.git
cd Code-Local-16Gb
```

> If `git` is not found, install Xcode Command Line Tools first: `xcode-select --install`

### 2. Run the installer

```bash
bash setup.sh
```

You will be asked to choose a mode:
- **[1] LOCAL** — Everything on the Mac Mini (server + client)
- **[2] SERVER** — Mac Mini is the AI brain only; you use a client from another computer

Choose **2** for the setup described in this guide.

The script will:
1. Install Homebrew (if missing)
2. Install Python 3.12 and `mlx-lm`
3. Download the recommended model (Phi-4 14B, ~7.7 GB, one-time download)
4. Create launchers on your Desktop

### 3. (Optional) Pre-download all models

By default, each model is downloaded the first time you select it in Open WebUI. To download all 3 models upfront and avoid waiting later:

```bash
bash scripts/download-models.sh
```

This downloads ~24–28 GB total and caches them in `~/.cache/huggingface/hub/`.

### 4. Start the server

```bash
MLX_BIND_HOST=0.0.0.0 bash scripts/start-mlx-server.sh
```

The server will listen on all network interfaces (`0.0.0.0:4000`) so other devices can connect. All 3 models (`phi-4`, `qwen3-14b`, `qwen2.5-coder-14b`) are exposed automatically.

**Do not close this Terminal window.** The server must stay running.

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

All 3 models will appear in the chat dropdown: `phi-4`, `qwen3-14b`, and `qwen2.5-coder-14b`. Select any model — the server will load it automatically.

### Alternative client: Claude Code

> ⚠️ Claude Code is closed-source software from Anthropic. Recent versions may ignore custom `ANTHROPIC_BASE_URL` settings if you have leftover environment variables from previous installs (e.g., Ollama).

If you want to try Claude Code as client:

```powershell
# Windows PowerShell
$env:ANTHROPIC_BASE_URL = "http://YOUR_MAC_IP:4000"
$env:ANTHROPIC_API_KEY = "sk-local"
claude --bare
```

**Troubleshooting Claude Code:** If you get "Auth conflict" errors, check for stale environment variables:

```powershell
# Check for leftover Ollama or Anthropic variables
Get-ChildItem Env: | Where-Object { $_.Name -like "ANTHROPIC*" }
```

Remove any `ANTHROPIC_AUTH_TOKEN` or old `ANTHROPIC_BASE_URL` variables from **System Environment Variables** (Windows key → "Edit the system environment variables" → "Environment Variables").

---

## Memory tips for 16 GB Macs

- **Close browsers and heavy apps** before starting the server
- **Enable KV-cache quantization** for long conversations:
  ```bash
  MLX_KV_BITS=8 MLX_BIND_HOST=0.0.0.0 bash scripts/start-mlx-server.sh
  ```
- **Restart the server** between long sessions to free accumulated KV cache

---

## Updating the server

If you `git pull` updates on the Mac Mini, restart the server to apply changes:

```bash
cd ~/Code-Local-16Gb
git pull
MLX_BIND_HOST=0.0.0.0 bash scripts/start-mlx-server.sh
```

---

## Project Structure

```
Code-Local-16Gb/
 ├── proxy/server.py          ← MLX server (Anthropic + OpenAI API)
 ├── setup.sh                  ← One-command installer
 ├── launchers/                ← Desktop launchers for the Mac
 ├── scripts/start-mlx-server.sh
 ├── scripts/download-models.sh    ← Pre-download all models
 └── README.md
```

---

## License

MIT
