#!/bin/bash
set -Eeuo pipefail

NEW_RELEASE_DIR=$1
PROJECT_NAME=$2

# Đọc APP_PORT từ file .env nếu có, hoặc dùng 3000 làm mặc định
APP_PORT=3000
if [ -f "$NEW_RELEASE_DIR/.env" ]; then
    # Lấy port từ .env
    ENV_PORT=$(grep '^APP_PORT=' "$NEW_RELEASE_DIR/.env" | cut -d '=' -f2)
    if [ ! -z "$ENV_PORT" ]; then
        APP_PORT=$ENV_PORT
    fi
fi

echo "Healthcheck: Đang kiểm tra cổng $APP_PORT..."

# Thử ping local port (hoặc endpoint thực tế nếu có như /api/health)
MAX_RETRIES=6
RETRY_INTERVAL=5
SUCCESS=false

for i in $(seq 1 $MAX_RETRIES); do
    if curl -s -f http://127.0.0.1:$APP_PORT/ > /dev/null || curl -s http://127.0.0.1:$APP_PORT/ > /dev/null; then
        echo "Healthcheck thành công!"
        SUCCESS=true
        break
    else
        echo "Thử lại lần $i/$MAX_RETRIES sau $RETRY_INTERVAL giây..."
        sleep $RETRY_INTERVAL
    fi
done

if [ "$SUCCESS" = false ]; then
    echo "CẢNH BÁO: Healthcheck thất bại! Bắt đầu rollback..."
    cd "$NEW_RELEASE_DIR"
    bash scripts/rollback.sh "$PROJECT_NAME"
    exit 1
fi
