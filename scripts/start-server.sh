#!/usr/bin/env bash
# Start the MLX server manually (foreground).
# Use this if you DON'T have the auto-start LaunchAgent installed,
# or if you want to run the server manually for debugging.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_SCRIPT="$PROJECT_ROOT/proxy/server.py"

# Default model if not set
MODEL="${MLX_MODEL:-mlx-community/phi-4-4bit}"
PORT="${MLX_PORT:-4000}"
BIND="${MLX_BIND_HOST:-127.0.0.1}"

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
