#!/bin/bash
set -Eeuo pipefail

ENV=$1
BASE_DIR="/var/www/auto-cv-reviewer/$ENV"
SHARED_DIR="$BASE_DIR/shared"
BACKUP_DIR="$BASE_DIR/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo " Running Pre-deploy Backup for $ENV"
echo "=========================================="

mkdir -p "$BACKUP_DIR"

if [ -d "$SHARED_DIR/uploads" ]; then
    # Chỉ backup cấu trúc và metadata (hoặc file nhỏ) nếu thư mục quá lớn, ở đây ta nén toàn bộ
    echo "-> Backing up uploads directory..."
    tar -czf "$BACKUP_DIR/uploads_$TIMESTAMP.tar.gz" -C "$SHARED_DIR" uploads
    
    # Xoá các backup cũ hơn 7 ngày
    find "$BACKUP_DIR" -name "uploads_*.tar.gz" -type f -mtime +7 -delete
    echo "✅ Backup complete."
else
    echo "-> No uploads directory found to backup."
fi
