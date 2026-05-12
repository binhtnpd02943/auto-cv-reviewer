#!/bin/bash
set -Eeuo pipefail

ENV=${1:-staging}
RELEASE_ID=${2:-latest}
APP_DIR=${APP_DIR:-$(pwd)}

echo "=========================================="
echo " 🚀 DEPLOYMENT STARTING ($ENV)"
echo " 🆔 RELEASE: $RELEASE_ID"
echo "=========================================="

# 1. Kiểm tra biến môi trường
if [ -z "${IMAGE_URI:-}" ]; then
    echo "❌ LỖI: Không tìm thấy IMAGE_URI trong môi trường!"
    exit 1
fi

cd "$APP_DIR"

# Xác định file compose
COMPOSE_FILE="docker-compose.$([ "$ENV" == "production" ] && echo "prod" || echo "stage").yml"

# 2. Xử lý file .env và Backup
echo "-> Cấu hình môi trường..."
# FIX: Backup đúng đuôi .bak để lát nữa có cái mà khôi phục
[ -f .env ] && cp .env .env.bak

# Nạp Secret từ GitHub Action / AWS xuống (nếu có)
if [ -n "${ENV_CONTENT:-}" ]; then
    printf '%s\n' "$ENV_CONTENT" > .env
fi

# Chèn/Cập nhật các biến build
sed -i '/^IMAGE_URI=/d;/^RELEASE_ID=/d' .env || touch .env
echo "IMAGE_URI=$IMAGE_URI" >> .env
echo "RELEASE_ID=$RELEASE_ID" >> .env

# 3. Tối ưu OS (Fix lỗi Memory Overcommit của Redis)
if [ "$(cat /proc/sys/vm/overcommit_memory)" != "1" ]; then
    echo "-> Bật Overcommit Memory cho Redis..."
    sudo sysctl vm.overcommit_memory=1 || true
fi

# 4. Pull image mới
echo "-> Đang tải image: $IMAGE_URI"
docker compose -f "$COMPOSE_FILE" pull

# 5. Khởi động & Đợi Healthcheck (Native Docker)
echo "-> Thực thi docker compose (Đang chờ Healthcheck xác nhận)..."

# Dùng --wait để Docker tự check, nếu App không trả về 200 OK, nó sẽ fail lệnh này
if ! docker compose -f "$COMPOSE_FILE" -p "cv-$ENV" up -d --wait --remove-orphans; then
    echo "❌ Healthcheck thất bại! Container không ổn định."
    echo "📋 Log lỗi từ App:"
    docker compose -f "$COMPOSE_FILE" -p "cv-$ENV" logs --tail 30

    echo "🔄 Đang tự động khôi phục (Rollback) về bản trước đó..."
    if [ -f .env.bak ]; then
        mv .env.bak .env
        docker compose -f "$COMPOSE_FILE" -p "cv-$ENV" up -d --wait --remove-orphans
        echo "⚠️ Đã rollback thành công. Pipeline sẽ báo đỏ!"
    fi
    exit 1
fi

# 6. Dọn dẹp rác
echo "-> Dọn dẹp image cũ..."
docker image prune -f --filter "until=24h"

echo "=========================================="
echo " ✅ DEPLOY $ENV THÀNH CÔNG!"
echo "=========================================="
