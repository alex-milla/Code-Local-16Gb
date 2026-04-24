#!/usr/bin/env bash
# Install MLX Manager on macOS Apple Silicon.
# Run this on your Mac Mini after cloning the repository.

set -euo pipefail

echo "=========================================="
echo "  Installing MLX Manager"
echo "=========================================="
echo ""

# 1. Check macOS and Apple Silicon
if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "ERROR: This script is for macOS only."
    exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
    echo "WARNING: MLX Manager is optimized for Apple Silicon (M1/M2/M3/M4)."
    echo "Your Mac appears to be Intel. Proceed at your own risk."
fi

# 2. Ensure Python 3.11+ is available
PYTHON=""
for cmd in python3.12 python3.11 python3; do
    if command -v "$cmd" &>/dev/null; then
        ver=$("$cmd" -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
        if (( $(echo "$ver >= 3.11" | bc -l) )); then
            PYTHON="$cmd"
            break
        fi
    fi
done

if [[ -z "$PYTHON" ]]; then
    echo "ERROR: Python 3.11+ is required. Install via Homebrew:"
    echo "  brew install python@3.12"
    exit 1
fi

echo "Using Python: $PYTHON ($($PYTHON --version))"

# 3. Create virtual environment for MLX Manager
VENV_DIR="$HOME/.local/mlx-manager-venv"
if [[ ! -d "$VENV_DIR" ]]; then
    echo "Creating virtual environment at $VENV_DIR ..."
    "$PYTHON" -m venv "$VENV_DIR"
fi

source "$VENV_DIR/bin/activate"

# 4. Upgrade pip and install MLX Manager
echo "Installing mlx-manager ..."
pip install --upgrade pip
pip install mlx-manager

# 5. Verify installation
if command -v mlx-manager &>/dev/null; then
    echo ""
    echo "✓ MLX Manager installed successfully!"
    mlx-manager --version
else
    echo "ERROR: mlx-manager command not found after installation."
    exit 1
fi

# 6. Create config directory
CONFIG_DIR="$HOME/.config/mlx-manager"
mkdir -p "$CONFIG_DIR"

# 7. Print next steps
echo ""
echo "=========================================="
echo "  Next Steps"
echo "=========================================="
echo ""
echo "1. Start MLX Manager manually:"
echo "   mlx-manager serve --host 0.0.0.0 --port 4000"
echo ""
echo "2. Or install auto-start:"
echo "   mlx-manager install-service"
echo ""
echo "3. Open the web UI:"
echo "   http://$(ipconfig getifaddr en0):4000"
echo ""
echo "4. From your Windows PC, connect Open WebUI to:"
echo "   http://$(ipconfig getifaddr en0):4000/v1"
echo ""
