#!/bin/bash
# Claude Code — Qwen2.5 Coder 14B (code-specialized)
# Double-click to launch

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/lib/claude-local-common.sh"

CLAUDE_BIN="${CLAUDE_BIN:-$HOME/.local/bin/claude}"
MODEL_NAME="${MLX_MODEL_LABEL:-Qwen2.5 Coder 14B}"

MLX_MODEL_DEFAULT="$(resolve_mlx_model \
  "$HOME/.cache/huggingface/hub/Qwen2.5-Coder-14B-Instruct-4bit" \
  "mlx-community/Qwen2.5-Coder-14B-Instruct-4bit")"

ensure_mlx_server "${MLX_MODEL:-$MLX_MODEL_DEFAULT}" \
  "  Loading $MODEL_NAME on MLX..."

clear
echo ""
echo "  → Claude Code with LOCAL AI ($MODEL_NAME)"
echo "  → Code-optimized model · Good for refactoring and debugging"
echo ""

ANTHROPIC_BASE_URL=http://localhost:4000 \
ANTHROPIC_API_KEY=sk-local \
exec "$CLAUDE_BIN" --model claude-sonnet-4-6 \
  --permission-mode auto \
  --bare
