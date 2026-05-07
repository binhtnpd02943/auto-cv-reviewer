#!/bin/bash
set -Eeuo pipefail

# Usage: ./deploy.sh <staging|production> <release-id>

ENV=$1
RELEASE_ID=$2
BASE_DIR="/var/www/auto-cv-reviewer/$ENV"
SOURCE_DIR="$BASE_DIR/source"
SHARED_DIR="$BASE_DIR/shared"
TAR_FILE="/tmp/release-$RELEASE_ID.tar.gz"

echo "=========================================="
echo " Starting Docker Deployment for $ENV"
echo " Release ID: $RELEASE_ID"
echo "=========================================="

if [ -z "$ENV" ] || [ -z "$RELEASE_ID" ]; then
    echo "Usage: $0 <environment> <release-id>"
    exit 1
fi

# 1. Setup directories if missing
mkdir -p "$SOURCE_DIR"
mkdir -p "$SHARED_DIR/uploads"
touch "$SHARED_DIR/.env"

# 2. Extract release
echo "-> Extracting source code..."
rm -rf "$SOURCE_DIR"/*
tar -xzf "$TAR_FILE" -C "$SOURCE_DIR"
rm "$TAR_FILE"

# 3. Backup current state
echo "-> Running backup..."
bash "$SOURCE_DIR/deploy/backup.sh" "$ENV"

# 4. Prepare Compose File & Env
cd "$SOURCE_DIR"
COMPOSE_FILE=$([ "$ENV" == "production" ] && echo "docker-compose.prod.yml" || echo "docker-compose.stage.yml")
cp "$SHARED_DIR/.env" "$SOURCE_DIR/.env"
# Inject RELEASE_ID into .env so docker-compose can use it
sed -i '/^RELEASE_ID=/d' "$SOURCE_DIR/.env"
echo "RELEASE_ID=$RELEASE_ID" >> "$SOURCE_DIR/.env"

# 5. Build Docker Image
echo "-> Building Docker Image cv-reviewer-$ENV:$RELEASE_ID..."
docker build -t cv-reviewer-$ENV:$RELEASE_ID .

# Lựa chọn lệnh docker-compose tương thích với hệ thống
DOCKER_COMPOSE_CMD=$(command -v docker-compose >/dev/null 2>&1 && echo "docker-compose" || echo "docker compose")

# 6. Deploy with Docker Compose
echo "-> Starting containers..."
$DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" -p "cv-reviewer-$ENV" up -d

# 7. Healthcheck
echo "-> Running Healthcheck..."
bash deploy/healthcheck.sh "$ENV" || {
    echo "❌ Healthcheck failed! Attempting automatic rollback..."
    bash deploy/rollback.sh "$ENV"
    exit 1
}

# 8. Cleanup old images (keep last 3)
echo "-> Pruning old images..."
docker image prune -a --filter "until=24h" -f || true

echo "=========================================="
echo " ✅ Deployment Successful!"
echo "=========================================="
