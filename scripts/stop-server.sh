#!/usr/bin/env bash
# Stop the MLX server.
# Works whether it's running via LaunchAgent (auto-start) or manually.

set -euo pipefail

PLIST_NAME="com.code-local-16gb.server.plist"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"

# Try to stop the LaunchAgent first (silently ignore if not loaded)
if launchctl list | grep -q "com.code-local-16gb.server"; then
    echo "Stopping LaunchAgent (auto-start) ..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    echo "✓ Auto-start server stopped."
else
    echo "LaunchAgent not running."
fi

# Also kill any manual foreground process
PID=$(pgrep -f "proxy/server.py" || true)
if [[ -n "$PID" ]]; then
    echo "Killing manual server process (PID: $PID) ..."
    kill "$PID" 2>/dev/null || true
    sleep 1
    # Force kill if still running
    if kill -0 "$PID" 2>/dev/null; then
        kill -9 "$PID" 2>/dev/null || true
    fi
    echo "✓ Manual server stopped."
else
    echo "No manual server process found."
fi
