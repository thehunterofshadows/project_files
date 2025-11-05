#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# tmux_start.sh  —  Configurable tmux session starter with .env support
# -----------------------------------------------------------------------------
# Creates/maintains a tmux session rooted at WORKDIR with:
#   - Left pane: 80% width running configurable command (TMUX_COMMAND)
#   - Right pane: 20% width interactive shell
#   - New windows AND panes automatically start in WORKDIR (via hooks)
# Also launches ttyd on PORT to expose the tmux session over the web.
#
# Configuration via .env file (place in same directory as script):
#   WORKDIR=/path/to/your/project
#   TMUX_PORT=9099
#   TMUX_SESSION_NAME=your_session_name
#   TMUX_COMMAND="opencode"
#
# Usage:
#   chmod +x ./tmux_start.sh
#   ./tmux_start.sh            # start / enforce layout (idempotent)
#   ./tmux_start.sh status     # show status
#   ./tmux_start.sh stop       # stop ttyd and tmux session
#   ./tmux_start.sh restart    # stop then start
# -----------------------------------------------------------------------------
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# Default values (fallback if .env doesn't exist or values are missing)
DEFAULT_SESSION="urlsum"
DEFAULT_PORT=9099
DEFAULT_COMMAND='codex --dangerously-bypass-approvals-and-sandbox'

# Load .env file if it exists
if [[ -f "$ENV_FILE" ]]; then
    echo "Loading configuration from $ENV_FILE"
    set -a  # automatically export all variables
    source "$ENV_FILE"
    set +a
else
    echo "No .env file found at $ENV_FILE, using default values"
fi

# Set variables with .env values or defaults (handle both WORKDIR and WORKDDIR)
SESSION="${TMUX_SESSION_NAME:-$DEFAULT_SESSION}"
PORT="${TMUX_PORT:-$DEFAULT_PORT}"
MAIN_CMD="${TMUX_COMMAND:-$DEFAULT_COMMAND}"

# WORKDIR is required - exit if not set
if [[ -z "${WORKDIR:-${WORKDDIR:-}}" ]]; then
    echo "Error: WORKDIR must be set in .env file" >&2
    echo "Example .env file:" >&2
    echo "WORKDIR=/path/to/your/project" >&2
    exit 1
fi

WORKDIR="${WORKDIR:-$WORKDDIR}"

# Derived variables
LOGFILE="$WORKDIR/ttyd_${SESSION}.log"

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: '$1' is required but not installed/in PATH." >&2
    exit 1
  }
}

is_port_listening() {
  ss -lnt "( sport = :$PORT )" 2>/dev/null | grep -q ":$PORT" || return 1
}

enforce_80_20() {
  local ww
  ww=$(tmux display -p -t "$SESSION:0" '#{window_width}') || true
  [[ -n "${ww:-}" && "$ww" -gt 0 ]] || return 0
  local target_width=$(( ww * 80 / 100 ))
  tmux resize-pane -t "$SESSION:0.0" -x "$target_width" || true
}

set_resize_hook() {
  tmux set-hook -t "$SESSION" window-resized \
    'run-shell "WW=$(tmux display -p -t #{window_id} \"#{window_width}\"); tmux resize-pane -t #{window_id}.0 -x $(( WW * 80 / 100 ))"' || true
}

set_new_window_hook() {
  tmux set-environment -t "$SESSION" WORKDIR "$WORKDIR" || true
  tmux set-hook -t "$SESSION" after-new-window \
    'run-shell "tmux send-keys -t #{session_name}:#{window_index}.0 \"cd $WORKDIR\" C-m"' || true
}

set_new_pane_hook() {
  tmux set-hook -t "$SESSION" after-split-window \
    'run-shell "tmux send-keys -t #{session_name}:#{window_index}.#{pane_index} \"cd $WORKDIR\" C-m"' || true
}

set_default_path() {
  tmux set-option -t "$SESSION" default-path "$WORKDIR" 2>/dev/null || true
}

stop_all() {
  pkill -f "ttyd -p $PORT" 2>/dev/null || true
  tmux kill-session -t "$SESSION" 2>/dev/null || true
}

status() {
  echo "Session: $SESSION"
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "  tmux: RUNNING"
    tmux list-windows -t "$SESSION" | sed 's/^/    /'
  else
    echo "  tmux: NOT RUNNING"
  fi
  if is_port_listening; then
    echo "  ttyd: LISTENING on $PORT (log: $LOGFILE)"
  else
    echo "  ttyd: NOT LISTENING on $PORT"
  fi
}

start_tmux_session() {
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  # NEW BEHAVIOR: If session exists, stop it before recreating
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    echo "Session '$SESSION' already running — stopping and reloading..."
    stop_all
    # small delay to let processes exit cleanly
    sleep 0.2
  fi

  # Create detached session with one window named 'main' in WORKDIR
  tmux new-session -d -s "$SESSION" -c "$WORKDIR" -n main

  # Pane split: create right pane, leaving left as pane 0
  tmux split-window -h -t "$SESSION:0" -c "$WORKDIR"

  # Force 80/20 layout and keep it on resize
  enforce_80_20
  set_resize_hook

  # Ensure new windows and panes open in WORKDIR
  set_new_window_hook
  set_new_pane_hook
  set_default_path

  # Start the configured command on the left pane
  tmux send-keys -t "$SESSION:0.0" "$MAIN_CMD" C-m
}

start_ttyd() {
  mkdir -p "$(dirname "$LOGFILE")"
  if ! is_port_listening; then
    nohup ttyd -p "$PORT" tmux attach -t "$SESSION" >>"$LOGFILE" 2>&1 &
    sleep 0.2
  fi
}

main() {
  require_cmd tmux
  require_cmd ttyd
  require_cmd ss

  case "${1:-start}" in
    start)
      start_tmux_session
      start_ttyd
      echo "✅ tmux session '$SESSION' reloaded and ready.";
      echo "   Left: $MAIN_CMD (80%) | Right: shell (20%)";
      echo "   New windows AND panes auto-cd to: $WORKDIR";
      echo "🌐 Web: http://<host>:$PORT (log: $LOGFILE)";
      ;;
    status)
      status
      ;;
    stop)
      stop_all
      echo "🛑 Stopped ttyd on $PORT and tmux session '$SESSION' (if running).";
      ;;
    restart)
      stop_all
      main start
      ;;
    *)
      echo "Usage: $0 [start|status|stop|restart]" >&2
      exit 2
      ;;
  esac
}

main "$@"