#!/bin/bash
set -Eeuo pipefail

# Tham số mặc định
PROJECT_NAME="auto_cv_prod"
BASE_DIR="/opt/auto-cv-reviewer"
RELEASE_DIR="$BASE_DIR/releases"
SHARED_DIR="$BASE_DIR/shared"
CURRENT_LINK="$BASE_DIR/current"

# Thư mục hiện hành (đã được workflow cd vào trước khi gọi script)
NEW_RELEASE_DIR=$(pwd)

echo "Bắt đầu tiến trình deploy tại: $NEW_RELEASE_DIR"

# Link file .env từ thư mục shared
if [ -f "$SHARED_DIR/.env" ]; then
    echo "Symlink .env từ shared folder..."
    ln -sf "$SHARED_DIR/.env" .env
else
    echo "CẢNH BÁO: Không tìm thấy file $SHARED_DIR/.env!"
    echo "Sử dụng .env có sẵn từ repository (nếu có)."
fi

# Đảm bảo shared uploads tồn tại
mkdir -p "$SHARED_DIR/uploads"
# Nếu repository có sẵn uploads thì xóa đi để link ra ngoài
rm -rf uploads
ln -sf "$SHARED_DIR/uploads" uploads

echo "Build docker images..."
docker-compose -p $PROJECT_NAME build

echo "Khởi động ứng dụng bằng docker-compose..."
docker-compose -p $PROJECT_NAME up -d

echo "Cập nhật symlink current..."
ln -sfn "$NEW_RELEASE_DIR" "$CURRENT_LINK"

echo "Gọi script healthcheck..."
# Đợi 5 giây cho services khởi động sơ bộ
sleep 5
bash scripts/healthcheck.sh "$NEW_RELEASE_DIR" "$PROJECT_NAME"

echo "Deploy thành công!"
