# Sử dụng base image Node.js bản gọn nhẹ (Alpine) để tối ưu dung lượng
FROM node:20-alpine

# Thiết lập thư mục làm việc bên trong container
WORKDIR /usr/src/app

# Copy package.json và package-lock.json (nếu có) vào trước
COPY package*.json ./

# Cài đặt các thư viện (chỉ cài dependencies dùng cho production)
RUN npm install --production

# Copy toàn bộ mã nguồn vào container
COPY . .

# Tạo thư mục uploads để Multer lưu file tạm (tránh lỗi crash khi thư mục chưa tồn tại)
RUN mkdir -p uploads

# Mở cổng 3000 để giao tiếp ra bên ngoài
EXPOSE 3000

# Lệnh khởi động server
CMD ["node", "src/app.js"]
