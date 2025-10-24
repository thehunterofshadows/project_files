#!/usr/bin/env bash
# restore.sh
# Lists checkpoints, prompts for version, docker compose down, backs up current folder (with 'b'),
# clears current folder, and restores the selected version.
# Excludes checkpoint.sh, restore.sh, clean.sh from backups and from being overwritten on restore.

set -euo pipefail

CUR_DIR="$(basename "$PWD")"
CHECK_PARENT="$(cd .. && pwd -P)"
CHECK_BASE="$CHECK_PARENT/checkpoint"
CHECK_DIR="$CHECK_BASE/checkpoint_${CUR_DIR}"

[[ -d "$CHECK_DIR" ]] || { echo "No checkpoint dir: $CHECK_DIR"; exit 1; }

echo "== Checkpoints in $CHECK_DIR =="
shopt -s nullglob
found_any=false
for f in "$CHECK_DIR"/*.tar.gz; do
  found_any=true
  base="$(basename "$f")"
  if [[ "$base" =~ ^([0-9]+\.[0-9]b?)_(.+)\.tar\.gz$ ]]; then
    printf "  %-6s %s\n" "${BASH_REMATCH[1]}" "$base"
  else
    echo "        $base"
  fi
done
$found_any || { echo "No checkpoint archives found."; exit 1; }
echo

read -rp "Enter version to restore (e.g., 1.3 or 1.3b): " WANT_VER
WANT_VER="$(printf '%s' "$WANT_VER" | tr -d '[:space:]')"
[[ "$WANT_VER" =~ ^[0-9]+\.[0-9]b?$ ]] || { echo "Use x.y or x.yb"; exit 1; }

mapfile -t CANDIDATES < <(ls -1t "$CHECK_DIR"/"${WANT_VER}"_*.tar.gz 2>/dev/null || true)
(( ${#CANDIDATES[@]} > 0 )) || { echo "No archive for $WANT_VER"; exit 1; }
RESTORE_FILE="${CANDIDATES[0]}"
echo "Selected: $(basename "$RESTORE_FILE")"
echo

# Find next numeric version (ignoring 'b')
max_val=-1
for f in "$CHECK_DIR"/*_*; do
  base="$(basename "$f")"
  if [[ "$base" =~ ^([0-9]+)\.([0-9])b?_ ]]; then
    major="${BASH_REMATCH[1]}"; minor="${BASH_REMATCH[2]}"
    val=$((10*major + minor))
    (( val > max_val )) && max_val=$val
  fi
done
if (( max_val < 0 )); then next_val=10; else next_val=$((max_val + 1)); fi
next_major=$(( next_val / 10 ))
next_minor=$(( next_val % 10 ))
NEXT_VERSION="${next_major}.${next_minor}"

read -rp "Enter message for backup BEFORE restore (default: pre_restore): " B_MSG
B_MSG="${B_MSG:-pre_restore}"
B_MSG_SAFE="$(printf '%s' "$B_MSG" | tr ' ' '_' | tr -cd '[:alnum:]_.-_' || true)"
[[ -z "$B_MSG_SAFE" ]] && B_MSG_SAFE="pre_restore"

# Stop docker compose if present
if command -v docker >/dev/null 2>&1; then
  if [[ -f docker-compose.yml || -f compose.yaml || -f compose.yml ]]; then
    echo "Stopping containers via: docker compose down"
    docker compose down || echo "Warning: docker compose down failed; continuing."
  else
    echo "No compose file found. Skipping docker compose down."
  fi
else
  echo "Docker not found. Skipping docker compose down."
fi

echo
# Backup current folder with 'b' (exclude the three scripts)
BACK_BASE="${NEXT_VERSION}b_${B_MSG_SAFE}"
BACK_ARCHIVE="$CHECK_DIR/${BACK_BASE}.tar.gz"
i=1
while [[ -e "$BACK_ARCHIVE" ]]; do
  BACK_ARCHIVE="$CHECK_DIR/${BACK_BASE}_$i.tar.gz"; ((i++))
done

echo "Creating backup of current folder as:"
echo "  $BACK_ARCHIVE"
tar \
  --exclude="${CUR_DIR}/checkpoint.sh" \
  --exclude="${CUR_DIR}/restore.sh" \
  --exclude="${CUR_DIR}/clean.sh" \
  -czf "$BACK_ARCHIVE" -C .. "$CUR_DIR"
echo "Backup complete."
BACK_ARCHIVE_HUMAN="$(du -h "$BACK_ARCHIVE" | cut -f1)"
CHECK_DIR_HUMAN="$(du -sh "$CHECK_DIR" | cut -f1)"
echo "Backup archive size: $BACK_ARCHIVE_HUMAN"
echo "Checkpoint folder total: $CHECK_DIR_HUMAN"
echo

# Clear current folder contents but protect the three scripts
echo "Clearing current folder contents: $PWD"
shopt -s dotglob nullglob
PROTECT=("checkpoint.sh" "restore.sh" "clean.sh")
for item in *; do
  skip=false
  for p in "${PROTECT[@]}"; do
    [[ "$item" == "$p" ]] && { skip=true; break; }
  done
  $skip && continue
  rm -rf -- "$item"
done

# Restore selected archive WITHOUT overwriting our three scripts
echo "Restoring from: $(basename "$RESTORE_FILE")"
tar \
  --exclude="${CUR_DIR}/checkpoint.sh" \
  --exclude="${CUR_DIR}/restore.sh" \
  --exclude="${CUR_DIR}/clean.sh" \
  --overwrite -xzf "$RESTORE_FILE" -C ..
echo "✅ Restored: $(basename "$RESTORE_FILE")"
echo "Backup saved: $BACK_ARCHIVE"
