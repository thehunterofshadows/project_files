#!/usr/bin/env bash
# clean.sh
# Stops compose stack, prunes Docker, removes all images, pulls latest, and brings stack up detached.

set -euo pipefail

# Stop stack if a compose file exists here
if [[ -f docker-compose.yml || -f compose.yaml || -f compose.yml ]]; then
  echo "Stopping containers via: docker compose down"
  docker compose down || true
else
  echo "No compose file found (docker-compose.yml/compose.yaml/compose.yml). Skipping docker compose down."
fi

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

# Pull and start (only if compose file exists)
if [[ -f docker-compose.yml || -f compose.yaml || -f compose.yml ]]; then
  echo "Pulling images (docker compose pull)..."
  docker compose pull
  # docker compose up web-ui
  echo "Starting stack detached (docker compose up -d)..."
  docker compose up -d
else
  echo "No compose file found, skipping pull/up."
fi
