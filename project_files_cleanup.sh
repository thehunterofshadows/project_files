#!/usr/bin/env bash
# project_files_cleanup.sh
# Removes legacy root-level project_files tool files from the caller's project.
#
# Use this after adding the new self-contained ./project_files/ directory to a
# project that still has the old root-level tool scripts from this repository.
#
# Usage:
#   ./project_files_cleanup.sh
#   ./project_files_cleanup.sh --dry-run

set -euo pipefail

PROJECT_ROOT="$(pwd)"
DRY_RUN=false

case "${1:-}" in
  -n|--dry-run)
    DRY_RUN=true
    ;;
  "" )
    ;;
  * )
    echo "Usage: $0 [--dry-run]" >&2
    exit 2
    ;;
esac

legacy_scripts=(
  "checkpoint.sh"
  "claude_run.sh"
  "clean.sh"
  "docker_deploy.sh"
  "docker_visual_run.sh"
  "filewatch.sh"
  "git_sync.sh"
  "prod_clean.sh"
  "prod_send.sh"
  "pull_tools.sh"
  "push_clean.sh"
  "restore.sh"
  "setup_git.sh"
  "tmux_start.sh"
)

removed_count=0
skipped_count=0

remove_file() {
  local path="$1"

  if [[ ! -e "$path" ]]; then
    return 0
  fi

  if $DRY_RUN; then
    echo "Would remove: $path"
  else
    rm -f -- "$path"
    echo "Removed: $path"
  fi
  removed_count=$((removed_count + 1))
}

skip_file() {
  local path="$1"
  local reason="$2"

  if [[ -e "$path" ]]; then
    echo "Skipped: $path ($reason)"
    skipped_count=$((skipped_count + 1))
  fi
}

looks_like_project_files_doc() {
  local path="$1"

  [[ -f "$path" ]] || return 1
  grep -Eq 'thehunterofshadows/project_files|project_files repository|project_files repo|AGENTS\.md — Coding Agent Guide' "$path"
}

looks_like_project_files_env_template() {
  local path="$1"

  [[ -f "$path" ]] || return 1
  grep -Eq '^#Project Files$|^TMUX_SESSION_NAME=|^PROD_LOCATION=' "$path"
}

cd "$PROJECT_ROOT"

if [[ ! -d "project_files" ]]; then
  echo "Warning: ./project_files was not found. This cleanup only removes legacy root-level files." >&2
fi

for script in "${legacy_scripts[@]}"; do
  remove_file "$script"
done

if looks_like_project_files_doc "AGENTS.md"; then
  remove_file "AGENTS.md"
else
  skip_file "AGENTS.md" "does not look like the legacy project_files AGENTS.md"
fi

if looks_like_project_files_doc "README.md"; then
  remove_file "README.md"
else
  skip_file "README.md" "does not look like the legacy project_files README.md"
fi

if looks_like_project_files_env_template ".env_temp"; then
  remove_file ".env_temp"
else
  skip_file ".env_temp" "does not look like the legacy project_files env template"
fi

echo
if $DRY_RUN; then
  echo "Dry run complete. Files that would be removed: $removed_count. Skipped: $skipped_count."
else
  echo "Cleanup complete. Files removed: $removed_count. Skipped: $skipped_count."
fi
