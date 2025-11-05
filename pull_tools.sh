#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# pull_tools.sh  —  Download fresh copies of all tools from project_files repo
# -----------------------------------------------------------------------------
# Downloads all .sh scripts from the project_files repository to the current
# directory and makes them executable. Useful for syncing tools across projects.
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