#!/bin/bash
set -Eeuo pipefail

ENV=${1:-production}
APP_DIR=${APP_DIR:-$(pwd)}
COMPOSE_FILE=$([ "$ENV" == "production" ] && echo "docker-compose.prod.yml" || echo "docker-compose.stage.yml")

echo "=========================================="
echo " Initiating Rollback for $ENV"
echo "=========================================="

cd "$APP_DIR"

if [ ! -f .env.previous ]; then
    echo "❌ Rollback failed: Could not find .env.previous."
    exit 1
fi

echo "-> Restoring previous environment and image reference..."
cp .env.previous .env

PREVIOUS_IMAGE=$(grep "^IMAGE_URI=" .env | cut -d '=' -f 2- || echo "")
if [ -n "$PREVIOUS_IMAGE" ]; then
    docker pull "$PREVIOUS_IMAGE"
fi

# Chạy lại docker compose với tag cũ (Modern V2 Plugin Standard)
docker compose -f "$COMPOSE_FILE" -p "cv-reviewer-$ENV" up -d

# Kiểm tra lại Healthcheck sau khi rollback
echo "-> Verifying Rollback..."
bash deploy/healthcheck.sh "$ENV" || {
    echo "❌ CRITICAL: Rollback also failed healthcheck. Manual intervention required."
    exit 1
}

echo "✅ Rollback completed successfully."
