#!/usr/bin/env bash
# checkpoint.sh
# Compress current folder into ../checkpoint/checkpoint_<foldername>/<x.y>_<message>.tar.gz
# Increments version by 0.1 and prints sizes. Excludes checkpoint.sh, restore.sh, clean.sh.

set -euo pipefail

CUR_DIR="$(basename "$PWD")"
CHECK_PARENT="$(cd .. && pwd -P)"
CHECK_BASE="$CHECK_PARENT/checkpoint"
CHECK_DIR="$CHECK_BASE/checkpoint_${CUR_DIR}"
mkdir -p "$CHECK_DIR"

read -rp "Enter message for this checkpoint: " USER_MSG
SANITIZED_MSG="$(printf '%s' "$USER_MSG" | tr ' ' '_' | tr -cd '[:alnum:]_.-_' || true)"
[[ -z "$SANITIZED_MSG" ]] && SANITIZED_MSG="no_msg"

shopt -s nullglob
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
VERSION="${next_major}.${next_minor}"

BASENAME="${VERSION}_${SANITIZED_MSG}"
ARCHIVE="$CHECK_DIR/${BASENAME}.tar.gz"
i=1
while [[ -e "$ARCHIVE" ]]; do
  ARCHIVE="$CHECK_DIR/${BASENAME}_$i.tar.gz"; ((i++))
done

# Exclude these scripts when archiving (note paths include top-level CUR_DIR/)
tar \
  --exclude="${CUR_DIR}/checkpoint.sh" \
  --exclude="${CUR_DIR}/restore.sh" \
  --exclude="${CUR_DIR}/clean.sh" \
  -czf "$ARCHIVE" -C .. "$CUR_DIR"

echo "✅ Created: $ARCHIVE"
ARCHIVE_HUMAN="$(du -h "$ARCHIVE" | cut -f1)"
CHECK_DIR_HUMAN="$(du -sh "$CHECK_DIR" | cut -f1)"
echo "Archive size: $ARCHIVE_HUMAN"
echo "Checkpoint folder total: $CHECK_DIR_HUMAN"
