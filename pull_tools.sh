#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# pull_tools.sh  —  Download fresh copies of all tools from project_files repo
# -----------------------------------------------------------------------------
# Downloads all .sh scripts from the project_files repository to the current
# directory and makes them executable. Useful for syncing tools across projects.
# Also adds each tool's filename to .gitignore if not already present.
#
# Usage:
#   chmod +x pull_tools.sh
#   ./pull_tools.sh
# -----------------------------------------------------------------------------
set -euo pipefail

echo "🔄 Pulling fresh tools from project_files repository..."

repo="thehunterofshadows/project_files"
branch="main"

# Download and extract all .sh files from the repository
curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$branch" \
  | tar -xz --wildcards --strip-components=1 '*/*.sh'

# Make all shell scripts executable
chmod +x ./*.sh 2>/dev/null || true

echo "✅ Tools updated successfully!"
echo "📁 Available tools in current directory:"
ls -1 ./*.sh 2>/dev/null | sed 's|^\./|  - |' || echo "  (no .sh files found)"

# --- Add fixed list of entries to .gitignore if not already present ---
echo ""
echo "📝 Checking .gitignore for tool entries..."

gitignore_file=".gitignore"
added_count=0

# Fixed list of entries to ensure are in .gitignore
gitignore_entries=(
  "checkpoint.sh"
  "claude_run.sh"
  "clean.sh"
  "filewatch.sh"
  "git_sync.sh"
  "prod_clean.sh"
  "prod_send.sh"
  "pull_tools.sh"
  "push_clean.sh"
  "restore.sh"
  "tmux_start.sh"
  ".env"
  ".env*"
  ".env_temp"
)

for entry in "${gitignore_entries[@]}"; do
  if [[ -f "$gitignore_file" ]] && grep -qxF "$entry" "$gitignore_file"; then
    echo "  ✔ $entry already in .gitignore"
  else
    echo "$entry" >> "$gitignore_file"
    echo "  ➕ Added $entry to .gitignore"
    ((added_count++))
  fi
done

if [[ $added_count -gt 0 ]]; then
  echo "✅ Added $added_count new entr$([ $added_count -eq 1 ] && echo 'y' || echo 'ies') to .gitignore"
else
  echo "✅ .gitignore already up to date — nothing added"
fi
