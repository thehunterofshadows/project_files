#!/usr/bin/env bash
# prod_send.sh
# Deploy selected checkpoint to production server
# Backs up current prod, sends checkpoint to prod, and restores it there

set -euo pipefail

# Load PROD_LOCATION from .env_project_tools file
if [[ ! -f ".env_project_tools" ]]; then
    echo "❌ .env_project_tools file not found. Please create it with PROD_LOCATION variable."
    exit 1
fi

source .env_project_tools

if [[ -z "${PROD_LOCATION:-}" ]]; then
    echo "❌ PROD_LOCATION not set in .env_project_tools file"
    echo "Example: PROD_LOCATION=user@server:~/project/"
    exit 1
fi

# Parse PROD_LOCATION (format: user@server:path or just path for local)
if [[ "$PROD_LOCATION" == *@*:* ]]; then
    REMOTE_USER_HOST="${PROD_LOCATION%:*}"
    REMOTE_PATH="${PROD_LOCATION#*:}"
    IS_REMOTE=true
else
    REMOTE_PATH="$PROD_LOCATION"
    IS_REMOTE=false
fi

# Find checkpoint directory
CUR_DIR="$(basename "$PWD")"
CHECK_PARENT="$(cd .. && pwd -P)"
CHECK_BASE="$CHECK_PARENT/checkpoint"
CHECK_DIR="$CHECK_BASE/checkpoint_${CUR_DIR}"

[[ -d "$CHECK_DIR" ]] || { echo "❌ No checkpoint dir: $CHECK_DIR"; exit 1; }

# List available checkpoints
echo "== Available Checkpoints =="
shopt -s nullglob
found_any=false
for f in "$CHECK_DIR"/*.tar.gz; do
    found_any=true
    base="$(basename "$f")"
    if [[ "$base" =~ ^([0-9]+\.[0-9]b?)_(.+)\.tar\.gz$ ]]; then
        printf "  %-8s %s\n" "${BASH_REMATCH[1]}" "$base"
    else
        echo "          $base"
    fi
done
$found_any || { echo "❌ No checkpoint archives found."; exit 1; }
echo

# Get user selection
read -rp "Enter version to deploy (e.g., 1.3 or 1.3b): " WANT_VER
WANT_VER="$(printf '%s' "$WANT_VER" | tr -d '[:space:]')"
[[ "$WANT_VER" =~ ^[0-9]+\.[0-9]b?$ ]] || { echo "❌ Use format x.y or x.yb"; exit 1; }

# Find matching checkpoint
mapfile -t CANDIDATES < <(ls -1t "$CHECK_DIR"/"${WANT_VER}"_*.tar.gz 2>/dev/null || true)
(( ${#CANDIDATES[@]} > 0 )) || { echo "❌ No archive for $WANT_VER"; exit 1; }
SELECTED_CHECKPOINT="${CANDIDATES[0]}"
echo "✅ Selected: $(basename "$SELECTED_CHECKPOINT")"
echo

# Generate timestamp for backup
TIMESTAMP=$(date +"%y%m%d_%H%M%S")

# Function to run command (remote or local)
run_cmd() {
    if $IS_REMOTE; then
        ssh "$REMOTE_USER_HOST" "$1"
    else
        bash -c "$1"
    fi
}

# Function to copy files (remote or local)
copy_file() {
    local src="$1"
    local dst="$2"
    if $IS_REMOTE; then
        scp "$src" "$REMOTE_USER_HOST:$dst"
    else
        cp "$src" "$dst"
    fi
}

echo "🚀 Starting production deployment..."
echo "Target: $PROD_LOCATION"
echo

# Create backup directory on remote
echo "📁 Creating backup directory..."
run_cmd "mkdir -p ${REMOTE_PATH%/}/../prod_backup"

# Backup current production (if exists)
echo "💾 Backing up current production..."
BACKUP_NAME="prod_backup_${TIMESTAMP}.tar.gz"
BACKUP_PATH="${REMOTE_PATH%/}/../prod_backup/$BACKUP_NAME"

run_cmd "if [ -d '$REMOTE_PATH' ] && [ '\$(ls -A '$REMOTE_PATH' 2>/dev/null)' ]; then 
    cd '$REMOTE_PATH' && tar -czf '$BACKUP_PATH' . && echo '✅ Backup created: $BACKUP_NAME'; 
else 
    echo '⚠️  No existing files to backup'; 
fi"

# Stop docker compose on remote
echo "🛑 Stopping Docker containers..."
run_cmd "cd '$REMOTE_PATH' && if [ -f docker-compose.yml ] || [ -f compose.yaml ] || [ -f compose.yml ]; then 
    docker compose down || echo '⚠️  Docker compose down failed'; 
else 
    echo '⚠️  No compose file found'; 
fi"

# Clear production directory
echo "🗑️  Clearing production directory..."
run_cmd "rm -rf ${REMOTE_PATH}/* ${REMOTE_PATH}/.[!.]*" || echo "⚠️  Some files couldn't be removed"

# Copy checkpoint to remote temp location
echo "📤 Copying checkpoint to production server..."
TEMP_CHECKPOINT="/tmp/checkpoint_${TIMESTAMP}.tar.gz"
copy_file "$SELECTED_CHECKPOINT" "$TEMP_CHECKPOINT"

# Extract checkpoint on remote (strip-components=1 removes the nested folder structure)
echo "📦 Extracting checkpoint..."
run_cmd "cd '$REMOTE_PATH' && tar -xzf '$TEMP_CHECKPOINT' --strip-components=1 && rm '$TEMP_CHECKPOINT'"

# Download fresh copies of all .sh scripts
echo "📥 Downloading fresh script copies..."
run_cmd "cd '$REMOTE_PATH' && 
repo='thehunterofshadows/project_files'
branch='main'
curl -fsSL \"https://codeload.github.com/\$repo/tar.gz/refs/heads/\$branch\" \\
  | tar -xz --wildcards --strip-components=1 '*/*.sh'
chmod +x ./*.sh 2>/dev/null || true
echo '✅ Fresh scripts downloaded and made executable'"

# Run clean.sh to handle Docker restart and cleanup
echo "🧹 Running clean.sh for final setup..."
run_cmd "cd '$REMOTE_PATH' && if [ -f clean.sh ]; then 
    ./clean.sh && echo '✅ Clean script completed'; 
else 
    echo '⚠️  clean.sh not found, skipping'; 
fi"

echo
echo "✅ Deployment completed successfully!"
echo "📍 Deployed: $(basename "$SELECTED_CHECKPOINT")"
echo "💾 Backup saved: $BACKUP_NAME"
echo "🎯 Production location: $PROD_LOCATION"
echo "🧹 Clean script executed for final setup"
echo
echo "🎉 Your production environment is ready!"