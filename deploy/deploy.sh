#!/bin/bash
set -Eeuo pipefail

# Usage: ./deploy.sh <staging|production> <release-id>

ENV=${1:-production}
RELEASE_ID=${2:-${IMAGE_TAG:-latest}}
APP_DIR=${APP_DIR:-$(pwd)}

echo "=========================================="
echo " Starting Docker Deployment for $ENV"
echo " Release ID: $RELEASE_ID"
echo "=========================================="

if [ -z "$ENV" ] || [ -z "$RELEASE_ID" ] || [ -z "${IMAGE_URI:-}" ]; then
    echo "Usage: $0 <environment> <release-id>"
    echo "Required env: IMAGE_URI"
    exit 1
fi

cd "$APP_DIR"
COMPOSE_FILE=$([ "$ENV" == "production" ] && echo "docker-compose.prod.yml" || echo "docker-compose.stage.yml")

# 1. Setup runtime files if missing
mkdir -p uploads
touch .env
cp .env .env.previous
if [ -n "${ENV_PROD:-}" ]; then
    printf '%s\n' "$ENV_PROD" > .env
fi

# 2. Backup current state
echo "-> Running backup..."
bash deploy/backup.sh "$ENV"

# 3. Prepare Compose env
sed -i '/^RELEASE_ID=/d;/^IMAGE_URI=/d' .env
echo "RELEASE_ID=$RELEASE_ID" >> .env
echo "IMAGE_URI=$IMAGE_URI" >> .env

# 4. Pull immutable image built by CI
echo "-> Pulling Docker image $IMAGE_URI..."
docker pull "$IMAGE_URI"

# 5. Deploy with Docker Compose (Modern V2 Plugin Standard)
echo "-> Starting containers using modern 'docker compose'..."
docker compose -f "$COMPOSE_FILE" -p "cv-reviewer-$ENV" up -d

# 6. Healthcheck
echo "-> Running Healthcheck..."
bash deploy/healthcheck.sh "$ENV" || {
    echo "❌ Healthcheck failed! Attempting automatic rollback..."
    bash deploy/rollback.sh "$ENV"
    exit 1
}

# 7. Cleanup old images
echo "-> Pruning old images..."
docker image prune -a --filter "until=24h" -f || true

echo "=========================================="
echo " ✅ Deployment Successful!"
echo "=========================================="
