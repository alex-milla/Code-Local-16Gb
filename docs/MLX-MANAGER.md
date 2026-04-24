# MLX Manager Setup Guide

This guide explains how to run the MLX inference server using **MLX Manager** — a professional tool for managing MLX-optimized models on Apple Silicon.

## Why MLX Manager?

Our previous custom `server.py` solution required manual restarts to switch models and was fragile on 16 GB Macs. MLX Manager replaces it with:

- **Web UI** for one-click model download and management
- **Automatic model switching** — select any model in Open WebUI, MLX Manager loads it automatically
- **LRU memory management** — unloads unused models to stay within 16 GB
- **Auto-start on boot** — `mlx-manager install-service`
- **Built-in inference server** — OpenAI + Anthropic API compatible
- **Real-time metrics** — memory usage, tokens/sec, queue depth

## Installation (Mac Mini)

### Option 1: One-command installer (recommended)

```bash
cd ~/Code-Local-16Gb
bash scripts/install-mlx-manager.sh
```

This creates a dedicated virtual environment at `~/.local/mlx-manager-venv`.

### Option 2: Manual install

```bash
# Create virtual environment
python3 -m venv ~/.local/mlx-manager-venv
source ~/.local/mlx-manager-venv/bin/activate

# Install
pip install mlx-manager

# Verify
mlx-manager --version
```

## Starting the Server

### Manual start (for testing)

```bash
source ~/.local/mlx-manager-venv/bin/activate
mlx-manager serve --host 0.0.0.0 --port 4000
```

Open the web UI at `http://YOUR_MAC_IP:4000`.

### Auto-start on boot

```bash
source ~/.local/mlx-manager-venv/bin/activate
mlx-manager install-service
```

The service starts automatically on every login. To check status:

```bash
launchctl list | grep mlx-manager
```

## Downloading Models

1. Open `http://YOUR_MAC_IP:4000` in a browser
2. **Register** — create an account (first user becomes admin)
3. Go to **Models** → **Browse**
4. Search for and download:
   - `mlx-community/phi-4-4bit`
   - `mlx-community/Qwen3-14B-4bit`
   - `mlx-community/Qwen2.5-Coder-14B-Instruct-4bit`
   - `mlx-community/DeepSeek-R1-Distill-Qwen-14B-4bit`

> If you already downloaded these via `mlx-lm`, they may be cached in `~/.cache/huggingface/hub/`. MLX Manager can detect them automatically.

## Connecting Open WebUI (Windows PC)

1. In Open WebUI, go to **Settings → Admin Settings → Connections**
2. Add a **Direct Connection** (OpenAI Compatible):
   - **URL:** `http://YOUR_MAC_IP:4000/v1`
   - **Auth:** Bearer `sk-local` (or whatever MLX Manager shows)
   - **Provider Type:** OpenAI
3. **Save** and refresh

All 4 models will appear in the chat dropdown. Select any model — MLX Manager loads it automatically.

## Server Control Commands

| Command | Description |
|---------|-------------|
| `mlx-manager serve --host 0.0.0.0 --port 4000` | Start manually |
| `mlx-manager install-service` | Enable auto-start |
| `mlx-manager status` | Show running servers |
| `launchctl unload ~/Library/LaunchAgents/com.mlx-manager.plist` | Stop auto-start |

## Memory Tuning for 16 GB Macs

Set these environment variables before starting:

```bash
export MLX_SERVER_MAX_MEMORY_GB=12      # Leave 4 GB for macOS
export MLX_SERVER_MAX_MODELS=2          # Keep 2 models in RAM max
export MLX_SERVER_TIMEOUT_CHAT_SECONDS=300
```

## Troubleshooting

### Models don't appear in Open WebUI
- Refresh the connection in **Settings → Connections**
- Check that models are downloaded in the MLX Manager web UI
- Verify the Mac IP hasn't changed

### Out of memory errors
- Lower `MLX_SERVER_MAX_MEMORY_GB` to 10 or 11
- Reduce `MLX_SERVER_MAX_MODELS` to 1
- Close browsers and heavy apps on the Mac Mini

### Server doesn't start
- Check that Python 3.11+ is installed: `python3 --version`
- Check logs: `~/Library/Logs/mlx-manager/`

## Legacy Solution

If you need to fall back to the original custom server, see `proxy/server.py` and `scripts/start-mlx-server.sh` in this repo. These are preserved for backwards compatibility but are no longer actively maintained.
