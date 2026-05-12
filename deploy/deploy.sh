#!/bin/bash
set -Eeuo pipefail

ENV=${1:-staging}
RELEASE_ID=${2:-latest}
APP_DIR=${APP_DIR:-$(pwd)}

echo "=========================================="
echo " 🚀 DEPLOYMENT STARTING ($ENV)"
echo " 🆔 RELEASE: $RELEASE_ID"
echo "=========================================="

# 1. Kiểm tra IMAGE_URI (con mẹ nó đây này)
if [ -z "${IMAGE_URI:-}" ]; then
    echo "❌ LỖI: Không tìm thấy IMAGE_URI trong môi trường!"
    exit 1
fi

cd "$APP_DIR"

# 2. Xử lý file .env
echo "-> Cấu hình môi trường..."
[ -f .env ] && cp .env .env.example

# Tạo file .env mới từ Secret nếu có truyền xuống
if [ -n "${ENV_CONTENT:-}" ]; then
    printf '%s\n' "$ENV_CONTENT" > .env
fi

# Chèn/Cập nhật các biến build vào cuối file .env
sed -i '/^IMAGE_URI=/d;/^RELEASE_ID=/d' .env || touch .env
echo "IMAGE_URI=$IMAGE_URI" >> .env
echo "RELEASE_ID=$RELEASE_ID" >> .env

# 3. Pull image mới
echo "-> Đang tải image: $IMAGE_URI"
docker pull "$IMAGE_URI"

# 4. Chạy Docker Compose
COMPOSE_FILE="docker-compose.$([ "$ENV" == "production" ] && echo "prod" || echo "stage").yml"

echo "-> Thực thi docker compose..."
docker compose -f "$COMPOSE_FILE" -p "cv-$ENV" up -d

# 5. Healthcheck (Nếu có)
if [ -f deploy/healthcheck.sh ]; then
    echo "-> Kiểm tra trạng thái hệ thống..."
    bash deploy/healthcheck.sh "$ENV" || {
        echo "❌ Healthcheck thất bại! Đang khôi phục..."
        [ -f .env.bak ] && mv .env.bak .env
        docker compose -f "$COMPOSE_FILE" -p "cv-$ENV" up -d
        exit 1
    }
fi

# 6. Dọn dẹp rác (Xóa các image cũ không dùng để tránh đầy ổ cứng)
echo "-> Dọn dẹp image cũ..."
docker image prune -f --filter "until=24h"

echo "=========================================="
echo " ✅ DEPLOY $ENV THÀNH CÔNG!"
echo "=========================================="
