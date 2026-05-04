#!/bin/bash
set -Eeuo pipefail

PROJECT_NAME=$1
BASE_DIR="/opt/auto-cv-reviewer"
RELEASE_DIR="$BASE_DIR/releases"
CURRENT_LINK="$BASE_DIR/current"

echo "Bắt đầu tiến trình rollback..."

# Lấy danh sách các thư mục release, sắp xếp theo thời gian giảm dần
RELEASES=($(ls -dt "$RELEASE_DIR"/*/))

if [ ${#RELEASES[@]} -lt 2 ]; then
    echo "LỖI: Không tìm thấy bản release cũ nào để rollback!"
    exit 1
fi

PREVIOUS_RELEASE=${RELEASES[1]}
PREVIOUS_RELEASE=${PREVIOUS_RELEASE%/}

echo "Bản release trước đó: $PREVIOUS_RELEASE"

# Khôi phục symlink
echo "Khôi phục symlink current trỏ về bản cũ..."
ln -sfn "$PREVIOUS_RELEASE" "$CURRENT_LINK"

echo "Stop phiên bản lỗi..."
docker-compose -p $PROJECT_NAME down

echo "Khởi động lại bản release cũ..."
cd "$PREVIOUS_RELEASE"
docker-compose -p $PROJECT_NAME up -d

echo "Rollback hoàn tất. Vui lòng kiểm tra lại hệ thống."
