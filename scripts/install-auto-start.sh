#!/usr/bin/env bash
# Install a macOS LaunchAgent to auto-start the MLX server on login/boot.
# Run this once; the server will start automatically on every reboot.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SERVER_SCRIPT="$PROJECT_ROOT/proxy/server.py"
CONFIG_DIR="$HOME/.config/claude-code-local-16gb"
PLIST_NAME="com.code-local-16gb.server.plist"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_NAME"
VENV_PATH=""

# Detect virtual environment
if [[ -f "$PROJECT_ROOT/.venv/bin/activate" ]]; then
    VENV_PATH="$PROJECT_ROOT/.venv"
elif [[ -f "$HOME/.local/mlx-server/bin/activate" ]]; then
    VENV_PATH="$HOME/.local/mlx-server"
else
    echo "ERROR: Virtual environment not found."
    echo "Run setup.sh first."
    exit 1
fi

# Read or create config file
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/server.conf"

if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    echo "Using existing config: $CONFIG_FILE"
else
    echo "Creating default server config..."
    cat > "$CONFIG_FILE" << 'EOF'
# MLX Server configuration
# Edit this file to change the default model, then run:
#   launchctl unload ~/Library/LaunchAgents/com.code-local-16gb.server.plist
#   launchctl load ~/Library/LaunchAgents/com.code-local-16gb.server.plist

MLX_MODEL=mlx-community/phi-4-4bit
MLX_PORT=4000
MLX_BIND_HOST=0.0.0.0
MLX_KV_BITS=0
EOF
    source "$CONFIG_FILE"
fi

echo ""
echo "=========================================="
echo "  Auto-Start Installer for MLX Server"
echo "=========================================="
echo ""
echo "Default model: $MLX_MODEL"
echo "Port: $MLX_PORT"
echo "Bind: $MLX_BIND_HOST"
echo ""
read -p "Press Enter to confirm or edit $CONFIG_FILE first and re-run."

# Create the LaunchAgent plist
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.code-local-16gb.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>$VENV_PATH/bin/python</string>
        <string>$SERVER_SCRIPT</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>MLX_MODEL</key>
        <string>$MLX_MODEL</string>
        <key>MLX_PORT</key>
        <string>$MLX_PORT</string>
        <key>MLX_BIND_HOST</key>
        <string>$MLX_BIND_HOST</string>
        <key>MLX_KV_BITS</key>
        <string>$MLX_KV_BITS</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$CONFIG_DIR/server.log</string>
    <key>StandardErrorPath</key>
    <string>$CONFIG_DIR/server.error.log</string>
    <key>WorkingDirectory</key>
    <string>$PROJECT_ROOT</string>
</dict>
</plist>
EOF

# Load the LaunchAgent
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

echo ""
echo "✓ LaunchAgent installed and loaded."
echo ""
echo "Server will auto-start on every login."
echo "Logs: $CONFIG_DIR/server.log"
echo ""
echo "Useful commands:"
echo "  launchctl unload ~/Library/LaunchAgents/$PLIST_NAME   # stop"
echo "  launchctl load ~/Library/LaunchAgents/$PLIST_NAME     # start"
echo "  launchctl list | grep code-local                        # status"
echo ""
