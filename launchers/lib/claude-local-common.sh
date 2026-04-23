#!/bin/bash
# Shared helpers for the claude-code-local-16gb launchers.

MLX_SERVER="${MLX_SERVER:-$HOME/.local/mlx-native-server/server.py}"
MLX_PYTHON="${MLX_PYTHON:-$HOME/.local/mlx-server/bin/python3}"

# Read the running server's /health and extract the "model" field. Prints the
# model path/id on stdout, or nothing if the server isn't up.
_get_running_mlx_model() {
  curl -sf http://127.0.0.1:4000/health 2>/dev/null | python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get("model", ""))
except Exception:
    pass
' 2>/dev/null
}

# Compare desired vs running model. The running server reports either an HF
# id (e.g. "mlx-community/phi-4-4bit") or a resolved local path.
# We compare the *basename* (last path component) case-insensitively.
_mlx_model_matches() {
  local desired="$1"
  local running="$2"
  [ -z "$running" ] && return 1
  local desired_base="${desired##*/}"
  local running_base="${running##*/}"
  local dl rl
  dl="$(printf '%s' "$desired_base" | tr '[:upper:]' '[:lower:]')"
  rl="$(printf '%s' "$running_base" | tr '[:upper:]' '[:lower:]')"
  [ "$dl" = "$rl" ]
}

_wait_for_mlx_health() {
  # 180 attempts × 2s = 6 minutes.
  local attempts="${1:-180}"
  local i
  for i in $(seq 1 "$attempts"); do
    if curl -s http://localhost:4000/health 2>/dev/null | grep -q '"status": "ok"'; then
      return 0
    fi
    sleep 2
  done
  return 1
}

# Resolve a model reference to something mlx-lm will load without triggering
# a HuggingFace download. Prefers the local flat-folder path if it exists.
resolve_mlx_model() {
  local local_path="$1"
  local hf_id="$2"
  if [ -d "$local_path" ] && [ -f "$local_path/config.json" ]; then
    printf '%s\n' "$local_path"
  else
    printf '%s\n' "$hf_id"
  fi
}

_stop_mlx_server() {
  pkill -f "mlx-native-server/server.py" 2>/dev/null || true
  local i
  for i in $(seq 1 15); do
    if ! lsof -i :4000 >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

# Start the MLX server with the given model, or confirm an already-running
# server is loaded with that model. If the wrong model is running, stop it
# and restart with the desired one.
ensure_mlx_server() {
  local desired="$1"
  local msg="$2"

  if lsof -i :4000 >/dev/null 2>&1; then
    local running
    running="$(_get_running_mlx_model)"
    if _mlx_model_matches "$desired" "$running"; then
      return 0
    fi
    echo "  Different model is loaded (${running:-unknown}) — restarting MLX server..."
    _stop_mlx_server || echo "  Warning: existing MLX server didn't exit cleanly, continuing anyway"
  fi

  echo "$msg"
  MLX_MODEL="$desired" "$MLX_PYTHON" "$MLX_SERVER" >/tmp/mlx-server.log 2>&1 &
  if ! _wait_for_mlx_health; then
    echo "  ERROR: MLX server failed to respond on port 4000 within 120s"
    echo "  Check /tmp/mlx-server.log for details"
    exit 1
  fi
}

# Force a fresh MLX server start regardless of what's already running.
force_restart_mlx_server() {
  local desired="$1"
  local msg="$2"

  if lsof -i :4000 >/dev/null 2>&1; then
    echo "  Stopping existing MLX server so new env vars take effect..."
    _stop_mlx_server || echo "  Warning: existing MLX server didn't exit cleanly, continuing anyway"
  fi

  echo "$msg"
  MLX_MODEL="$desired" "$MLX_PYTHON" "$MLX_SERVER" >/tmp/mlx-server.log 2>&1 &
  if ! _wait_for_mlx_health; then
    echo "  ERROR: MLX server failed to respond on port 4000 within 120s"
    echo "  Check /tmp/mlx-server.log for details"
    exit 1
  fi
}
