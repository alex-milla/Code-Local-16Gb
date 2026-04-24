#!/usr/bin/env bash
# Restart the MLX server: stop any running instance, then start manually.
# This is useful after code updates or config changes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  Restarting MLX Server"
echo "=========================================="
echo ""

# 1. Stop
bash "$SCRIPT_DIR/stop-server.sh"
echo ""

# 2. Start
bash "$SCRIPT_DIR/start-server.sh"
