#!/usr/bin/env bash
# Recursive file watcher with color-coded recency.
# Skips node_modules, .git, logs, work log, __pycache__, .pyc/.pyo, ttyd*, and itself.

# ─────────────────────────────────────────────
REFRESH_TIME=10   # seconds between refreshes
MAX_FILES=15      # number of most recently modified files to display
# ─────────────────────────────────────────────

# Detect OS (mac uses -r instead of -d for date)
if [[ "$OSTYPE" == "darwin"* ]]; then
  date_cmd() { date -r "$1" +"%s"; }   # macOS epoch only
else
  date_cmd() { date -d @"$1" +"%s"; }  # Linux epoch only
fi

while true; do
  clear
  echo -e "\033[1mRecently Modified Files\033[0m"
  echo "-----------------------------------"

  now=$(date +%s)

  find . -type f \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/logs/*" \
    ! -ipath "*/work log/*" \
    ! -path "*/__pycache__/*" \
    ! -name "*.pyc" \
    ! -name "*.pyo" \
    ! -name "ttyd*" \
    ! -iname "filewatch.sh" \
    ! -iname "file_watch.sh" \
    -printf "%T@ %p\n" 2>/dev/null \
    | sort -nr | head -n "$MAX_FILES" | while read -r line; do

      mod_epoch=$(echo "$line" | awk '{print $1}')
      file=$(echo "$line" | cut -d' ' -f2-)
      diff=$(( now - ${mod_epoch%.*} ))

      # Color by recency
      if   [ $diff -le 60 ]; then      color="\033[1;31m"  # red <1 min
      elif [ $diff -le 600 ]; then     color="\033[1;33m"  # orange <10 min
      elif [ $diff -le 3600 ]; then    color="\033[1;32m"  # green <1 hr
      else                             color="\033[1;34m"  # blue older
      fi

      printf "${color}%s\033[0m\n" "$file"
  done

  sleep "$REFRESH_TIME"
done
