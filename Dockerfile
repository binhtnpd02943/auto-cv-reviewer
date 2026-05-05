FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Install dependencies first for better caching
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Ensure uploads directory exists
RUN mkdir -p uploads && chown -R node:node uploads

# Switch to non-root user
USER node

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["npm", "start"]
