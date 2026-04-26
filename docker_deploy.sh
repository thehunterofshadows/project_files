#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# docker_deploy.sh — Git sync + Docker rebuild with visual status
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/docker_visual_run.sh"

# Register all steps upfront so the progress bar knows the total
vr_init \
    "🔄:Git Sync" \
    "🚀:Git Push" \
    "🏗️:Docker Build"

# Always call vr_summary on exit (handles unexpected errors too)
trap 'vr_summary' EXIT

# ── Step 1: Pull latest ────────────────────────────────────────────────────
vr_step "Git Sync" \
    git pull --rebase --autostash

# ── Step 2: Push local commits (skips gracefully if nothing to push) ───────
vr_step "Git Push" bash -c '
    AHEAD=$(git rev-list @{u}..HEAD --count 2>/dev/null || echo "0")
    if [ "$AHEAD" -gt 0 ]; then
        echo "Pushing $AHEAD local commit(s)..."
        git push
    else
        echo "Remote is already up to date — nothing to push."
    fi
'

# ── Step 3: Rebuild Docker environment ─────────────────────────────────────
vr_step "Docker Build" \
    docker compose up --build --force-recreate -d

# vr_summary is called automatically by the EXIT trap
