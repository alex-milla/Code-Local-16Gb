#!/usr/bin/env bash
# Download all available models upfront so they're cached locally.
# This avoids long waits the first time a model is requested via the API.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Load python env
if [[ -f "$PROJECT_ROOT/.venv/bin/activate" ]]; then
    source "$PROJECT_ROOT/.venv/bin/activate"
elif [[ -f "$HOME/.local/mlx-server/bin/activate" ]]; then
    source "$HOME/.local/mlx-server/bin/activate"
else
    echo "ERROR: Virtual environment not found."
    echo "Run setup.sh first or ensure mlx-lm is installed."
    exit 1
fi

MODELS=(
    "mlx-community/phi-4-4bit"
    "mlx-community/Qwen3-14B-4bit"
    "mlx-community/Qwen2.5-Coder-14B-Instruct-4bit"
)

echo "=========================================="
echo "  Pre-downloading MLX models"
echo "=========================================="
echo ""
echo "Models will be cached in:"
echo "  ~/.cache/huggingface/hub/"
echo ""
echo "This may take several minutes depending on your connection."
echo "Total size: ~24-28 GB (3 models × ~8 GB each)"
echo ""

for MODEL in "${MODELS[@]}"; do
    echo "------------------------------------------"
    echo "Downloading: $MODEL"
    echo "------------------------------------------"
    python3 -c "from mlx_lm.utils import load; load('$MODEL')"
    echo "✓ $MODEL ready"
    echo ""
done

echo "=========================================="
echo "  All models downloaded successfully!"
echo "=========================================="
