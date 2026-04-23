# Claude Code Local — 16GB Edition

A fork of [claude-code-local](https://github.com/nicedreamzapp/claude-code-local) optimized for **Mac Mini M4 and other Apple Silicon Macs with 16 GB of unified memory**.

Run [Claude Code](https://claude.ai/code) with local open-source models instead of Anthropic's cloud API. Your code never leaves your machine.

## Why this fork?

The original project targets high-end Macs (64–128 GB RAM) with massive models like Qwen 3.5 122B and Llama 3.3 70B. Those simply don't fit on a 16 GB Mac.

This edition curates a **16GB-friendly model lineup** that actually fits in your RAM while maximizing code quality and minimizing hallucinations.

| Model | Size | RAM Used | Speed | Best For |
|-------|------|----------|-------|----------|
| **Phi-4 14B** ⭐ | ~7.7 GB | ~10 GB | ~20 tok/s | **Lowest hallucinations**, general coding |
| **Qwen3 14B** | ~8.3 GB | ~11 GB | ~18 tok/s | Long context, large codebases |
| **Qwen2.5 Coder 14B** | ~8 GB | ~11 GB | ~18 tok/s | Code-specific tasks, refactoring |

> ⭐ **Recommended:** Phi-4 14B scores highest on formal hallucination benchmarks (PHANTOM F1: 0.885) and runs comfortably within 16 GB.

## Requirements

- **Mac with Apple Silicon** (M1/M2/M3/M4)
- **16 GB unified memory** (also works on 8 GB and 32 GB with auto-detection)
- **macOS Sonoma or later**
- **Claude Code CLI** installed (`npm install -g @anthropic-ai/claude-code`)

## Quick Start

```bash
git clone https://github.com/alex-milla/Code-Local-16Gb.git
cd claude-code-local-16gb
bash setup.sh
```

`setup.sh` will ask you two things:
1. **Deployment mode**: Local (everything on this Mac) or Server (this Mac runs models, Claude Code runs on another computer)
2. Then it installs Python 3.12, `mlx-lm`, downloads the model, and creates launchers

Then **double-click any launcher on your Desktop** to start coding locally.

### Mode 1: Local (default)
Everything runs on the Mac Mini. Claude Code + models on the same machine.

### Mode 2: Server
The Mac Mini acts as an AI inference server. You run Claude Code from another computer (Windows, Linux, or another Mac) on the same network.

```
🖥️  Your Windows/Mac/Linux          🍎  Mac Mini M4 (server)
        │                                   │
   Claude Code                            MLX Server
   (npm install)                          (proxy/server.py)
        │                                   │
        └─────────── HTTP ─────────────────┘
              ANTHROPIC_BASE_URL=http://mac-mini-ip:4000
```

**On the remote computer:**
```powershell
$env:ANTHROPIC_BASE_URL = "http://192.168.1.X:4000"
$env:ANTHROPIC_API_KEY = "sk-local"
claude --model claude-sonnet-4-6
```

> Both computers must be on the same WiFi/Ethernet. The Mac Mini must stay on. macOS may ask to allow Python through the Firewall — click **Allow**.

## Manual Start

```bash
# 1. Set up the MLX virtualenv
python3.12 -m venv ~/.local/mlx-server
~/.local/mlx-server/bin/pip install mlx-lm

# 2. Start the server with a 16GB-friendly model
MLX_MODEL=mlx-community/phi-4-4bit bash scripts/start-mlx-server.sh

# 3. Launch Claude Code
ANTHROPIC_BASE_URL=http://localhost:4000 \
ANTHROPIC_API_KEY=sk-local \
claude --model claude-sonnet-4-6
```

## Available Models

All models are pulled automatically from [Hugging Face mlx-community](https://huggingface.co/mlx-community) on first run.

| Model ID | Parameters | Disk | Notes |
|----------|-----------|------|-------|
| `mlx-community/phi-4-4bit` | 14B | ~7.7 GB | Microsoft. Best reasoning, lowest hallucinations. MIT license. |
| `mlx-community/Qwen3-14B-4bit` | 14B | ~8.3 GB | Alibaba. Excellent long-context handling. |
| `mlx-community/Qwen2.5-Coder-14B-Instruct-4bit` | 14B | ~8 GB | Alibaba. Specialized for code generation. |

### Memory tips for 16 GB Macs

- **Close browsers and heavy apps** before starting the server
- **Enable KV-cache quantization** for long conversations:
  ```bash
  MLX_KV_BITS=8 MLX_MODEL=mlx-community/phi-4-4bit bash scripts/start-mlx-server.sh
  ```
- **Restart the server** between long sessions to free accumulated KV cache

## How It Works

```
┌─────────────────────────────────────────────┐
│              YOUR MAC (16 GB)               │
│                                             │
│  📝 You type ──> 🤖 Claude Code             │
│                      │                      │
│                      ▼                      │
│                 ⚡ MLX Server (port 4000)   │
│                      │                      │
│                      ▼                      │
│                 🥊 Local model (Phi-4 etc.) │
│                      │                      │
│                      ▼                      │
│  📝 Answer <─── ✨ Clean response           │
│                                             │
│         🔒 Nothing leaves this box.         │
└─────────────────────────────────────────────┘
```

The server (`proxy/server.py`) is a single Python file that:
1. Loads an MLX model natively on your Apple GPU
2. Exposes an Anthropic-compatible API on `localhost:4000`
3. Translates tool calls between Claude Code's format and the model's native format
4. Strips thinking tags and reasoning artifacts from model output
5. Reuses prompt caches across requests for speed

## Project Structure

```
claude-code-local-16gb/
 ├── proxy/
 │   └── server.py                 ← MLX Native Anthropic Server
 ├── launchers/
 │   ├── Claude Local.command      ← Default (Phi-4 14B)
 │   ├── Qwen3 14B.command         ← Long-context model
 │   ├── Qwen2.5 Coder 14B.command ← Code-specialized model
 │   └── lib/
 │       └── claude-local-common.sh ← Shared helpers
 ├── scripts/
 │   └── start-mlx-server.sh       ← Server start helper
 ├── setup.sh                      ← One-command installer
 └── README.md                     ← You are here
```

## Differences from upstream

| | Original | This fork |
|---|---|---|
| Target RAM | 64–128 GB | **16 GB** |
| Default model | Gemma 4 31B / Qwen 122B | **Phi-4 14B** |
| Model lineup | 3 huge models | **3 curated 14B models** |
| KV cache default | Full precision | **Auto + docs for 8-bit** |
| iMessage / Voice / Browser | Bundled / referenced | **Removed** (focus on core coding) |

## Troubleshooting

### "Model uses too much memory" or Mac freezes
- Close Safari/Chrome tabs before starting
- Use `MLX_KV_BITS=8` to quantize the KV cache
- Switch to a smaller model

### "Claude Code asks me to log in"
Your `claude` CLI is too old. Update it:
```bash
npm install -g @anthropic-ai/claude-code
```

### Server won't start
Check the log:
```bash
cat /tmp/mlx-server.log
```

## Credits

- Original concept and server architecture: [Matt Macosko / nicedreamzapp](https://github.com/nicedreamzapp/claude-code-local)
- MLX framework: [Apple](https://github.com/ml-explore/mlx)
- Phi-4: [Microsoft](https://huggingface.co/microsoft/phi-4)
- Qwen3 / Qwen2.5 Coder: [Alibaba](https://qwenlm.github.io/)
- Quantized MLX models: [mlx-community](https://huggingface.co/mlx-community)

## License

MIT — same as the original project.
