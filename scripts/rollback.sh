#!/bin/bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

echo "Initiating rollback process..."

# Rollback strategy: Bring down current containers, revert git to previous commit, rebuild and restart
COMPOSE_FILE="docker-compose.yml"

echo "Bringing down current containers..."
docker compose -f "$COMPOSE_FILE" down

echo "Reverting git repository to previous commit..."
# This will hard reset to the previous commit (HEAD~1)
# Note: Use with caution. Only suitable if rollback logic is isolated per deployment attempt.
git reset --hard HEAD~1

echo "Rebuilding and starting containers with previous code..."
docker compose -f "$COMPOSE_FILE" up -d --build

echo "Rollback completed. Please verify the service health."
