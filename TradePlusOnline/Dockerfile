# Build stage
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Production stage with nginx
FROM nginx:alpine

# Copy static files
COPY --from=builder /app/*.html /usr/share/nginx/html/
COPY --from=builder /app/assets /usr/share/nginx/html/assets/

# Copy custom nginx config (local without SSL)
COPY nginx-local.conf /etc/nginx/nginx.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"] 