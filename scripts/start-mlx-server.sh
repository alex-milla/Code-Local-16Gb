#!/bin/bash
# MLX Native Anthropic Server — start helper
# Speaks the Anthropic Messages API directly. No proxy. No translation layer.
#
# Usage:
#   bash scripts/start-mlx-server.sh                              # default Phi-4 14B
#   MLX_MODEL=mlx-community/Qwen3-14B-4bit bash scripts/start-mlx-server.sh
#   bash scripts/start-mlx-server.sh mlx-community/phi-4-4bit

MODEL="${1:-${MLX_MODEL:-mlx-community/phi-4-4bit}}"
PORT="${MLX_PORT:-4000}"
PYTHON="${MLX_PYTHON:-$HOME/.local/mlx-server/bin/python3}"
SERVER="${MLX_SERVER:-$HOME/.local/mlx-native-server/server.py}"

echo "Starting MLX Native Anthropic Server"
echo "  model: $MODEL"
echo "  port:  $PORT"

MLX_MODEL="$MODEL" MLX_PORT="$PORT" exec "$PYTHON" "$SERVER"
