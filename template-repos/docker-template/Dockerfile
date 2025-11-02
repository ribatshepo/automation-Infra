# Multi-stage production Dockerfile

# Build stage
FROM node:18.17.0-alpine3.18 AS builder

# Set working directory
WORKDIR /app

# Create app user and group
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production && \
    npm cache clean --force

# Copy application code
COPY --chown=appuser:appgroup . .

# Build application (if needed)
RUN npm run build 2>/dev/null || echo "No build script found"

# Production stage
FROM node:18.17.0-alpine3.18 AS production

# Install security updates and minimal tools
RUN apk update && \
    apk upgrade && \
    apk add --no-cache curl && \
    rm -rf /var/cache/apk/*

# Create app user and group
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

# Set working directory
WORKDIR /app

# Copy node_modules from builder
COPY --from=builder --chown=appuser:appgroup /app/node_modules ./node_modules

# Copy built application (conditionally)
COPY --from=builder --chown=appuser:appgroup /app/dist/ ./dist/
COPY --from=builder --chown=appuser:appgroup /app/build/ ./build/
COPY --from=builder --chown=appuser:appgroup /app/public/ ./public/
COPY --from=builder --chown=appuser:appgroup /app/src/ ./src/

# Copy package.json for npm start
COPY --chown=appuser:appgroup package*.json ./

# Create health check endpoint
RUN echo '#!/bin/sh\ncurl -f http://localhost:${PORT:-3000}/health || exit 1' > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Add health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

# Start application
CMD ["npm", "start"]