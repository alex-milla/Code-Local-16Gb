#!/usr/bin/env bash
# Uninstall the macOS LaunchAgent.

set -euo pipefail

PLIST_NAME="com.code-local-16gb.server.plist"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"

if [[ -f "$PLIST_PATH" ]]; then
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
    rm "$PLIST_PATH"
    echo "✓ Auto-start removed. Server will no longer start on boot."
else
    echo "LaunchAgent not found. Nothing to uninstall."
fi
