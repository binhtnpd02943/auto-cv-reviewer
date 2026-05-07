# =============================================================================
# Multi-stage Dockerfile for Auto CV Reviewer
#
# Stage 1 (builder): Cài đặt dependencies, có thể chứa các build-tools nặng.
# Stage 2 (runtime): Copy source code và node_modules từ builder sang, chạy
#                    dưới quyền non-root user để tối đa hóa bảo mật.
# =============================================================================

# ── Stage 1: Builder ─────────────────────────────────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /usr/src/app

# (Tùy chọn) Cài đặt các thư viện hệ thống cần thiết để compile C++ addons
# RUN apk add --no-cache python3 make g++

COPY package*.json ./
# Cài đặt toàn bộ dependencies (chỉ production)
RUN npm ci --omit=dev

# Copy toàn bộ source code
COPY . .

# ── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM node:18-alpine AS runtime

# Cài đặt timezone, curl để phục vụ healthcheck nếu cần
RUN apk add --no-cache curl tzdata

WORKDIR /usr/src/app

# Copy từ builder (chỉ lấy những gì cần thiết)
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/src ./src
COPY --from=builder /usr/src/app/package.json ./package.json

# Cấp quyền cho non-root user (user 'node' có sẵn trong node:alpine)
RUN mkdir -p uploads && chown -R node:node /usr/src/app

# Chuyển sang chạy bằng non-root user để tăng cường bảo mật
USER node

EXPOSE 3000

CMD ["node", "src/app.js"]
