#!/usr/bin/env bash
# prod_clean.sh
# Production variant of clean.sh.
#
# Before starting the stack it finds every .env.production file in the repo
# and copies it over .env in the same directory.  This ensures Vite bakes
# the correct production values at build time.
#
# Reusable: works for any project that follows the convention:
#   <dir>/.env.production  →  <dir>/.env

set -euo pipefail

# ── Inject .env.production → .env everywhere it exists ───────────────────────
echo "🔍 Scanning for .env.production files..."
found=0
while IFS= read -r -d '' env_prod_file; do
    target_dir="$(dirname "$env_prod_file")"
    target_env="${target_dir}/.env"
    cp "$env_prod_file" "$target_env"
    echo "  ✅ ${env_prod_file}  →  ${target_env}"
    found=$((found + 1))
done < <(find . -name ".env.production" -not -path "*/node_modules/*" -not -path "*/.git/*" -print0)

if [[ $found -eq 0 ]]; then
    echo "  ⚠️  No .env.production files found — continuing without env injection"
else
    echo "  Injected ${found} env file(s)"
fi
echo

# ── Stop stack ────────────────────────────────────────────────────────────────
if [[ -f docker-compose.yml || -f compose.yaml || -f compose.yml ]]; then
    echo "Stopping containers via: docker compose down"
    docker compose down || true
else
    echo "No compose file found. Skipping docker compose down."
fi

# ── Prune Docker ──────────────────────────────────────────────────────────────
echo "Pruning unused Docker data..."
docker system prune -f

echo "Removing all Docker images (if any)..."
IMGS="$(docker images -q)"
if [[ -n "$IMGS" ]]; then
    # shellcheck disable=SC2086
    docker rmi $IMGS || true
else
    echo "No images to remove."
fi

# ── Rebuild and start ─────────────────────────────────────────────────────────
if [[ -f docker-compose.yml || -f compose.yaml || -f compose.yml ]]; then
    echo "Pulling images (docker compose pull)..."
    docker compose pull

    echo "Building and starting stack (docker compose up -d --build)..."
    docker compose up -d --build
else
    echo "No compose file found, skipping pull/up."
fi

