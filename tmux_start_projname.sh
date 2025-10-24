#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# tmux_start_gps_weather.sh  —  Backward-compatible (no tmux 'default-path')
# -----------------------------------------------------------------------------
# Creates/maintains a tmux session "gps_weather" rooted at WORKDIR with:
#   - Left pane: 80% width running: codex --dangerously-bypass-approvals-and-sandbox
#   - Right pane: 20% width interactive shell
#   - New windows automatically start in WORKDIR (via hook; no default-path)
# Also launches ttyd on PORT to expose the tmux session over the web.
#
# Usage:
#   chmod +x ~/tmux_start_gps_weather.sh
#   ~/tmux_start_gps_weather.sh            # start / enforce layout (idempotent)
#   ~/tmux_start_gps_weather.sh status     # show status
#   ~/tmux_start_gps_weather.sh stop       # stop ttyd and tmux session
#   ~/tmux_start_gps_weather.sh restart    # stop then start
# -----------------------------------------------------------------------------
set -euo pipefail

SESSION="urlsum"
WORKDIR="/home/justin/dockerimages/text2speech_future/urlsummary_current"
PORT=9099
LOGFILE="$WORKDIR/ttyd_${SESSION}.log"
CODEX_CMD='codex --dangerously-bypass-approvals-and-sandbox'

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
  # Resize left pane (0) to ~80% of current window width
  local ww
  ww=$(tmux display -p -t "$SESSION:0" '#{window_width}') || true
  [[ -n "${ww:-}" && "$ww" -gt 0 ]] || return 0
  local target_width=$(( ww * 80 / 100 ))
  tmux resize-pane -t "$SESSION:0.0" -x "$target_width" || true
}

set_resize_hook() {
  # Keep 80/20 when the window is resized
  tmux set-hook -t "$SESSION" window-resized \
    'run-shell "WW=$(tmux display -p -t #{window_id} \"#{window_width}\"); tmux resize-pane -t #{window_id}.0 -x $(( WW * 80 / 100 ))"' || true
}

set_new_window_hook() {
  # Ensure every new window starts in WORKDIR on older tmux (no default-path)
  tmux set-environment -t "$SESSION" WORKDIR "$WORKDIR" || true
  tmux set-hook -t "$SESSION" after-new-window \
    'run-shell "tmux send-keys -t #{session_name}:#{window_index}.0 \"cd $WORKDIR\" C-m"' || true
}

start_tmux_session() {
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"

  if ! tmux has-session -t "$SESSION" 2>/dev/null; then
    # Create detached session with one window named 'main' in WORKDIR
    tmux new-session -d -s "$SESSION" -c "$WORKDIR" -n main

    # Pane split: create right pane, leaving left as pane 0
    tmux split-window -h -t "$SESSION:0" -c "$WORKDIR"

    # Force 80/20 layout and keep it on resize
    enforce_80_20
    set_resize_hook

    # Ensure new windows open in WORKDIR (back-compat method)
    set_new_window_hook

    # Start Codex on the left pane
    tmux send-keys -t "$SESSION:0.0" "$CODEX_CMD" C-m
  else
    # Session exists — ensure 2 panes, enforce layout, hooks
    local pane_count
    pane_count=$(tmux list-panes -t "$SESSION:0" | wc -l | tr -d ' ')
    if [ "$pane_count" -lt 2 ]; then
      tmux split-window -h -t "$SESSION:0" -c "$WORKDIR"
    fi
    enforce_80_20
    set_resize_hook
    set_new_window_hook
  fi
}

start_ttyd() {
  mkdir -p "$(dirname "$LOGFILE")"
  if ! is_port_listening; then
    nohup ttyd -p "$PORT" tmux attach -t "$SESSION" >>"$LOGFILE" 2>&1 &
    sleep 0.2
  fi
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

main() {
  require_cmd tmux
  require_cmd ttyd
  require_cmd ss

  case "${1:-start}" in
    start)
      start_tmux_session
      start_ttyd
      echo "✅ tmux session '$SESSION' ready.";
      echo "   Left: codex (80%) | Right: shell (20%)";
      echo "   New windows auto-cd to: $WORKDIR";
      echo "🌐 Web: http://<host>:$PORT (log: $LOGFILE)";
      ;;
    status)
      status
      ;;
    stop)
      stop_all
      echo "🛑 Stopped ttyd on $PORT and tmux session '$SESSION' (if running)."
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

