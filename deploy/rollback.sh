#!/bin/bash
set -Eeuo pipefail

ENV=$1
BASE_DIR="/var/www/auto-cv-reviewer/$ENV"
SOURCE_DIR="$BASE_DIR/source"
COMPOSE_FILE=$([ "$ENV" == "production" ] && echo "docker-compose.prod.yml" || echo "docker-compose.stage.yml")

echo "=========================================="
echo " Initiating Rollback for $ENV"
echo "=========================================="

cd "$SOURCE_DIR"

# Lấy tag của image đang chạy hiện tại
CURRENT_TAG=$(grep "^RELEASE_ID=" .env | cut -d '=' -f 2 || echo "")

# Tìm kiếm tag của version liền trước (dựa trên docker images cho cv-reviewer-$ENV)
# Bỏ qua image hiện tại và image có tag 'latest'
PREVIOUS_TAG=$(docker images --format "{{.Tag}}" cv-reviewer-$ENV | grep -v -E "latest|^$CURRENT_TAG$" | head -n 1 || true)

if [ -z "$PREVIOUS_TAG" ]; then
    echo "❌ Rollback failed: Could not find a previous Docker image tag."
    exit 1
fi

echo "-> Rolling back from $CURRENT_TAG to image tag: $PREVIOUS_TAG"

# Sửa lại .env để trỏ về tag cũ
sed -i '/^RELEASE_ID=/d' .env
echo "RELEASE_ID=$PREVIOUS_TAG" >> .env

# Locate Docker Compose robustly
if [ -x "$(command -v docker-compose)" ]; then
    DOCKER_COMPOSE_CMD="docker-compose"
elif [ -x "/usr/local/bin/docker-compose" ]; then
    DOCKER_COMPOSE_CMD="/usr/local/bin/docker-compose"
elif [ -x "/usr/bin/docker-compose" ]; then
    DOCKER_COMPOSE_CMD="/usr/bin/docker-compose"
elif docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
else
    echo "❌ FATAL ERROR: Cannot find docker-compose!"
    exit 1
fi

# Chạy lại docker compose với tag cũ
$DOCKER_COMPOSE_CMD -f "$COMPOSE_FILE" -p "cv-reviewer-$ENV" up -d

# Kiểm tra lại Healthcheck sau khi rollback
echo "-> Verifying Rollback..."
bash deploy/healthcheck.sh "$ENV" || {
    echo "❌ CRITICAL: Rollback also failed healthcheck. Manual intervention required."
    exit 1
}

echo "✅ Rollback completed successfully."
