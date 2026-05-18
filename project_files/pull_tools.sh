#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# pull_tools.sh  —  Download fresh copies of all tools from project_files repo
# -----------------------------------------------------------------------------
# Downloads the project_files repository into ./project_files and makes scripts
# executable. Useful for syncing tools across projects.
# Also adds project_files/ to .gitignore if not already present.
#
# Usage:
#   chmod +x project_files/pull_tools.sh
#   ./project_files/pull_tools.sh
# -----------------------------------------------------------------------------
set -euo pipefail

PROJECT_ROOT="$(pwd)"
TOOLS_DIR="${PROJECT_ROOT}/project_files"

echo "🔄 Pulling fresh tools from project_files repository..."

repo="thehunterofshadows/project_files"
branch="main"

mkdir -p "$TOOLS_DIR"

# Download and extract the repository's project_files/ folder into ./project_files.
curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$branch" \
  | tar -xz --wildcards --strip-components=2 -C "$TOOLS_DIR" '*/project_files/*'

# Make all shell scripts executable.
chmod +x "$TOOLS_DIR"/*.sh 2>/dev/null || true

echo "✅ Tools updated successfully!"
echo "📁 Available tools in project_files/:"
ls -1 "$TOOLS_DIR"/*.sh 2>/dev/null | sed "s|^${TOOLS_DIR}/|  - project_files/|" || echo "  (no .sh files found)"

# --- Add fixed list of entries to .gitignore if not already present ---
echo ""
echo "📝 Checking .gitignore for tool entries..."

gitignore_file=".gitignore"
added_count=0

# Fixed list of entries to ensure are in .gitignore.
gitignore_entries=(
  "project_files/"
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
