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

# Capture list of .sh files before download
before=$(ls ./*.sh 2>/dev/null | xargs -n1 basename || true)

# Download and extract all .sh files from the repository
curl -fsSL "https://codeload.github.com/$repo/tar.gz/refs/heads/$branch" \
  | tar -xz --wildcards --strip-components=1 '*/*.sh'

# Make all shell scripts executable
chmod +x ./*.sh 2>/dev/null || true

echo "✅ Tools updated successfully!"
echo "📁 Available tools in current directory:"
ls -1 ./*.sh 2>/dev/null | sed 's|^\./|  - |' || echo "  (no .sh files found)"

# --- Add pulled tool filenames to .gitignore if not already present ---
echo ""
echo "📝 Checking .gitignore for tool entries..."

gitignore_file=".gitignore"
added_count=0

for script in ./*.sh; do
  filename=$(basename "$script")
  # Skip pull_tools.sh itself — you likely want to track that one
  if [[ "$filename" == "pull_tools.sh" ]]; then
    continue
  fi
  if [[ -f "$gitignore_file" ]] && grep -qxF "$filename" "$gitignore_file"; then
    echo "  ✔ $filename already in .gitignore"
  else
    echo "$filename" >> "$gitignore_file"
    echo "  ➕ Added $filename to .gitignore"
    ((added_count++))
  fi
done

if [[ $added_count -gt 0 ]]; then
  echo "✅ Added $added_count new entr$([ $added_count -eq 1 ] && echo 'y' || echo 'ies') to .gitignore"
else
  echo "✅ .gitignore already up to date — nothing added"
fi
