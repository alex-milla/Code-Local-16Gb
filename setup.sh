#!/bin/bash
# Claude Code Local — 16GB Edition
# Apple Silicon only. Installs MLX, downloads a 16GB-friendly model,
# and creates a desktop launcher that runs Claude Code 100% on-device.
#
# Usage: bash setup.sh

set -e

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║     Claude Code Local — 16GB Edition             ║"
echo "║     Optimized for Mac Mini M4 · 16 GB RAM        ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""

# ── System detection ──────────────────────────────────────────
MEM_GB=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1073741824)}')
CHIP=$(sysctl -n machdep.cpu.brand_string 2>/dev/null || echo 'Apple Silicon')

echo "Detected: $CHIP"
echo "Memory:   ${MEM_GB} GB"
echo ""

if [[ $(uname -m) != "arm64" ]]; then
  echo "ERROR: This requires Apple Silicon (M1 or later)."
  exit 1
fi

# ── Choose deployment mode ────────────────────────────────────
echo ""
echo "How do you want to run Claude Code?"
echo ""
echo "  [1] LOCAL  — Everything on this Mac (Claude Code + models)"
echo "  [2] SERVER — This Mac runs the AI models only; you use Claude Code"
echo "               from another computer (Windows, Linux, another Mac)"
echo ""
read -rp "Choose mode [1/2, default: 1]: " MODE_CHOICE
MODE_CHOICE="${MODE_CHOICE:-1}"

if [ "$MODE_CHOICE" = "2" ]; then
  DEPLOY_MODE="server"
  BIND_HOST="0.0.0.0"
  echo ""
  echo "SERVER mode selected."
  echo "The MLX server will listen on all network interfaces (0.0.0.0:4000)."
  echo "Other devices on your WiFi/Ethernet can connect to this Mac's AI."
  echo ""
else
  DEPLOY_MODE="local"
  BIND_HOST="127.0.0.1"
  echo ""
  echo "LOCAL mode selected."
  echo "Everything runs on this Mac only."
  echo ""
fi

# ── Homebrew ──────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── Python 3.12 + MLX ─────────────────────────────────────────
if ! command -v python3.12 &>/dev/null; then
  echo "Installing Python 3.12 (required for MLX)..."
  brew install python@3.12
fi

MLX_VENV="$HOME/.local/mlx-server"
if [ ! -d "$MLX_VENV" ]; then
  echo "Creating MLX virtualenv at $MLX_VENV..."
  python3.12 -m venv "$MLX_VENV"
fi

echo "Installing mlx-lm into virtualenv..."
"$MLX_VENV/bin/pip" install --quiet --upgrade pip
"$MLX_VENV/bin/pip" install --quiet --upgrade mlx-lm

# ── Pick a model from the 16GB-friendly lineup ────────────────
echo ""
echo "Selecting a model from the 16GB-friendly lineup for your ${MEM_GB} GB Mac..."

if [ "$MEM_GB" -ge 96 ]; then
  MODEL_ID="mlx-community/Qwen3.5-122B-A10B-4bit"
  MODEL_LABEL="Qwen 3.5 122B (THE BEAST — 65 tok/s)"
  MODEL_TIER="🔵 max"
elif [ "$MEM_GB" -ge 64 ]; then
  MODEL_ID="mlx-community/Qwen3-32B-4bit"
  MODEL_LABEL="Qwen 3 32B (great quality, ~12 tok/s)"
  MODEL_TIER="🟢 fast"
elif [ "$MEM_GB" -ge 32 ]; then
  MODEL_ID="mlx-community/Qwen3-14B-4bit"
  MODEL_LABEL="Qwen 3 14B (sweet spot for 32GB)"
  MODEL_TIER="🟢 fast"
elif [ "$MEM_GB" -ge 16 ]; then
  # 16GB Mac — default to Phi-4 for lowest hallucination rate
  MODEL_ID="mlx-community/phi-4-4bit"
  MODEL_LABEL="Phi-4 14B (RECOMMENDED — low hallucinations, ~20 tok/s)"
  MODEL_TIER="🟢 16gb-recommended"
else
  MODEL_ID="mlx-community/Qwen2.5-Coder-7B-Instruct-4bit"
  MODEL_LABEL="Qwen 2.5 Coder 7B (lightweight, 8GB Mac)"
  MODEL_TIER="🟠 small"
fi

echo "Selected: $MODEL_TIER  $MODEL_LABEL"
echo "Model ID: $MODEL_ID"
echo ""

# ── Download model ────────────────────────────────────────────
echo "Downloading $MODEL_ID (one time, ~4-10 GB depending on model)..."
"$MLX_VENV/bin/python3" - <<PY
from mlx_lm.utils import load
load("$MODEL_ID")
print("Done.")
PY

# ── Install MLX server ────────────────────────────────────────
# We install it as a symlink into this repo, not a copy. That way if you edit
# proxy/server.py in the repo (to fix a bug, add a feature, pull a PR), the
# change takes effect on the running server after the next restart — with no
# risk of the running copy silently drifting from the version in git.
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SERVER_DIR="$HOME/.local/mlx-native-server"
mkdir -p "$SERVER_DIR"
ln -sf "$SCRIPT_DIR/proxy/server.py" "$SERVER_DIR/server.py"
echo "MLX server installed (symlink) → $SERVER_DIR/server.py -> $SCRIPT_DIR/proxy/server.py"

# ── Create desktop launcher ───────────────────────────────────
CLAUDE_BIN=$(which claude 2>/dev/null || echo "$HOME/.local/bin/claude")
if [ ! -f "$CLAUDE_BIN" ]; then
  echo ""
  echo "WARNING: Claude Code not found. Install it with:"
  echo "  npm install -g @anthropic-ai/claude-code"
  echo ""
  CLAUDE_BIN="\$HOME/.local/bin/claude"
fi

LAUNCHER="$HOME/Desktop/Claude Local 16GB.command"
cat > "$LAUNCHER" <<LAUNCH
#!/bin/bash
# Claude Code — Local AI 16GB Edition ($MODEL_LABEL)
CLAUDE_BIN="$CLAUDE_BIN"
MLX_PYTHON="$MLX_VENV/bin/python3"
MLX_SERVER="$SERVER_DIR/server.py"

if ! lsof -i :4000 >/dev/null 2>&1; then
  MLX_MODEL="$MODEL_ID" MLX_BIND_HOST="$BIND_HOST" "\$MLX_PYTHON" "\$MLX_SERVER" >/tmp/mlx-server.log 2>&1 &
  echo "  Loading $MODEL_LABEL on MLX..."
  while ! curl -s http://localhost:4000/health 2>/dev/null | grep -q "ok"; do
    sleep 2
  done
fi

clear
echo ""
echo "  → Claude Code with LOCAL AI (16GB Edition)"
echo "  → $MODEL_LABEL"
echo "  → 100% on-device, no cloud, no API fees"
echo ""

ANTHROPIC_BASE_URL=http://localhost:4000 \\
ANTHROPIC_API_KEY=sk-local \\
exec "\$CLAUDE_BIN" --model claude-sonnet-4-6
LAUNCH

chmod +x "$LAUNCHER"

# ── Additional launchers ──────────────────────────────────────
echo ""
# ── Save deployment config ────────────────────────────────────
CONFIG_DIR="$HOME/.config/claude-code-local-16gb"
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/mode.conf" <<CONF
deploy_mode=$DEPLOY_MODE
bind_host=$BIND_HOST
model=$MODEL_ID
CONF

# ── Remote-mode instructions ──────────────────────────────────
if [ "$DEPLOY_MODE" = "server" ]; then
  MAC_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "YOUR_MAC_IP")
  cat > "$HOME/Desktop/REMOTE_SETUP_INSTRUCTIONS.txt" <<REMOTE
========================================
CLAUDE CODE LOCAL — 16GB EDITION
SERVER MODE SETUP INSTRUCTIONS
========================================

This Mac is now running as an AI model server.

1. START THE SERVER
   Double-click "Claude Local 16GB.command" on this Mac.
   (Keep it running.)

2. ON YOUR OTHER COMPUTER (Windows / Linux / Mac)
   Install Claude Code:
     npm install -g @anthropic-ai/claude-code

   Then run:
     set ANTHROPIC_BASE_URL=http://$MAC_IP:4000
     set ANTHROPIC_API_KEY=sk-local
     claude --model claude-sonnet-4-6

   (On PowerShell use $env: instead of set)

3. IMPORTANT
   - Both computers must be on the same WiFi/Ethernet network.
   - This Mac must stay on and the server must keep running.
   - If macOS asks about Firewall, ALLOW Python incoming connections.
   - The IP of this Mac is: $MAC_IP
     (Check System Settings > Network if this changes.)

4. FIREWALL NOTE
   If you want to block the Mac from accessing Anthropic's cloud
   while keeping local mode working, block api.anthropic.com
   in your router or Little Snitch. Claude Code on the remote
   machine will still work because all inference goes to this Mac.

========================================
REMOTE
  echo ""
  echo "  🌐 SERVER mode: created REMOTE_SETUP_INSTRUCTIONS.txt on Desktop"
  echo ""
fi

echo "Installing additional model launchers to Desktop..."

# Phi-4 launcher (explicit)
cat > "$HOME/Desktop/Phi-4 14B.command" <<'LAUNCH'
#!/bin/bash
# Claude Code — Phi-4 14B (lowest hallucinations, recommended)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/claude-local-common.sh"

CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
MODEL="mlx-community/phi-4-4bit"

ensure_mlx_server "$MODEL" "  Loading Phi-4 14B on MLX..."

clear
echo ""
echo "  → Claude Code with LOCAL AI (Phi-4 14B)"
echo "  → Lowest hallucination rate · MIT license · ~20 tok/s"
echo ""

ANTHROPIC_BASE_URL=http://localhost:4000 \
ANTHROPIC_API_KEY=sk-local \
exec "$CLAUDE_BIN" --model claude-sonnet-4-6 \
  --permission-mode auto \
  --bare
LAUNCH
chmod +x "$HOME/Desktop/Phi-4 14B.command"

# Qwen3 14B launcher
cat > "$HOME/Desktop/Qwen3 14B.command" <<'LAUNCH'
#!/bin/bash
# Claude Code — Qwen3 14B (great long-context handling)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/claude-local-common.sh"

CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
MODEL="mlx-community/Qwen3-14B-4bit"

ensure_mlx_server "$MODEL" "  Loading Qwen3 14B on MLX..."

clear
echo ""
echo "  → Claude Code with LOCAL AI (Qwen3 14B)"
echo "  → Excellent context length · Great for large codebases"
echo ""

ANTHROPIC_BASE_URL=http://localhost:4000 \
ANTHROPIC_API_KEY=sk-local \
exec "$CLAUDE_BIN" --model claude-sonnet-4-6 \
  --permission-mode auto \
  --bare
LAUNCH
chmod +x "$HOME/Desktop/Qwen3 14B.command"

# Qwen2.5 Coder 14B launcher
cat > "$HOME/Desktop/Qwen2.5 Coder 14B.command" <<'LAUNCH'
#!/bin/bash
# Claude Code — Qwen2.5 Coder 14B (code-specialized)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/claude-local-common.sh"

CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
MODEL="mlx-community/Qwen2.5-Coder-14B-Instruct-4bit"

ensure_mlx_server "$MODEL" "  Loading Qwen2.5 Coder 14B on MLX..."

clear
echo ""
echo "  → Claude Code with LOCAL AI (Qwen2.5 Coder 14B)"
echo "  → Code-optimized · Good for refactoring and debugging"
echo ""

ANTHROPIC_BASE_URL=http://localhost:4000 \
ANTHROPIC_API_KEY=sk-local \
exec "$CLAUDE_BIN" --model claude-sonnet-4-6 \
  --permission-mode auto \
  --bare
LAUNCH
chmod +x "$HOME/Desktop/Qwen2.5 Coder 14B.command"

echo ""
echo "╔══════════════════════════════════════════════════╗"
echo "║     Setup complete!                              ║"
echo "╠══════════════════════════════════════════════════╣"
echo "║                                                  ║"
echo "║  Model:    $MODEL_ID"
echo "║  Server:   $SERVER_DIR/server.py"
echo "║  Mode:     $(echo "$DEPLOY_MODE" | tr '[:lower:]' '[:upper:]')"
echo "║  Bind:     $BIND_HOST:4000"
echo "║                                                  ║"
if [ "$DEPLOY_MODE" = "server" ]; then
  echo "║  🌐  SERVER MODE                                 ║"
  echo "║                                                  ║"
  echo "║  This Mac is the AI brain.                       ║"
  echo "║  See REMOTE_SETUP_INSTRUCTIONS.txt on Desktop    ║"
  echo "║  for how to connect from your other computer.    ║"
  echo "║                                                  ║"
fi
echo "║  Launchers:                                        ║"
echo "║    ~/Desktop/Claude Local 16GB.command           ║"
echo "║    ~/Desktop/Phi-4 14B.command                   ║"
echo "║    ~/Desktop/Qwen3 14B.command                   ║"
echo "║    ~/Desktop/Qwen2.5 Coder 14B.command           ║"
echo "║                                                  ║"
echo "║  Double-click any launcher on your Desktop       ║"
echo "║  to start coding with local AI.                  ║"
echo "║                                                  ║"
echo "║  TIP: For 16GB Macs, enable KV-cache quant       ║"
echo "║  on long conversations:                            ║"
echo "║    MLX_KV_BITS=8 bash setup.sh                   ║"
echo "║                                                  ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
