#!/usr/bin/env bash
# Start the MLX server manually (foreground).
# Usage:
#   bash scripts/start-mlx-server.sh                    # default phi-4
#   MLX_MODEL=mlx-community/Qwen3-14B-4bit bash scripts/start-mlx-server.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_SCRIPT="$PROJECT_ROOT/proxy/server.py"

# Load user config if it exists (created by install-auto-start.sh)
CONFIG_FILE="$HOME/.config/claude-code-local-16gb/server.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
fi

# Defaults: bind to all interfaces so other devices on the network can connect
MODEL="${MLX_MODEL:-mlx-community/phi-4-4bit}"
PORT="${MLX_PORT:-4000}"
BIND="${MLX_BIND_HOST:-0.0.0.0}"

# Detect virtual environment
PYTHON=""
if [[ -f "$PROJECT_ROOT/.venv/bin/python" ]]; then
    PYTHON="$PROJECT_ROOT/.venv/bin/python"
elif [[ -f "$HOME/.local/mlx-server/bin/python" ]]; then
    PYTHON="$HOME/.local/mlx-server/bin/python"
else
    PYTHON="python3"
fi

echo "=========================================="
echo "  Starting MLX Server"
echo "=========================================="
echo "  Model: $MODEL"
echo "  Port:  $PORT"
echo "  Bind:  $BIND"
echo ""
echo "  Press Ctrl-C to stop"
echo "=========================================="
echo ""

MLX_MODEL="$MODEL" MLX_PORT="$PORT" MLX_BIND_HOST="$BIND" exec "$PYTHON" "$SERVER_SCRIPT"
