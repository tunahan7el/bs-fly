FROM node:20-bullseye-slim AS builder

WORKDIR /app

# Install dependencies required for building and clean up in the same layer
RUN apt-get update && \
    apt-get install -y python3 build-essential git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    yarn cache clean

# Copy package files
COPY package.json yarn.lock ./
COPY packages/app/package.json ./packages/app/
COPY packages/backend/package.json ./packages/backend/

# Install dependencies and clean up
RUN yarn install --frozen-lockfile && \
    yarn cache clean

# Copy the rest of the application
COPY . .

# Build frontend and backend
RUN yarn workspace app build && \
    yarn workspace backend build && \
    yarn workspace backend tsc && \
    rm -rf node_modules/.cache

# Verify frontend build
RUN ls -la packages/app/dist

# Stage 2 - Production image
FROM node:20-bullseye-slim

WORKDIR /app

# Install runtime dependencies and clean up in the same layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends libsqlite3-dev python3 curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    yarn cache clean

# Copy workspace setup
COPY package.json yarn.lock ./
COPY packages/backend/package.json ./packages/backend/
COPY packages/app/package.json ./packages/app/

# Create necessary directories
RUN mkdir -p packages/backend/dist packages/app/dist

# Copy built application
COPY --from=builder /app/packages/backend/dist/ ./packages/backend/dist/
COPY --from=builder /app/packages/backend/package.json ./packages/backend/
COPY --from=builder /app/packages/app/dist/ ./packages/app/dist/
COPY --from=builder /app/app-config.yaml ./

# Verify frontend files
RUN ls -la packages/app/dist

# Install production dependencies and clean up
RUN yarn install --frozen-lockfile --production && \
    yarn cache clean && \
    rm -rf /tmp/* /var/tmp/*

# Fix permissions
RUN chmod -R 755 /app

# Expose backend port
EXPOSE 7007

WORKDIR /app/packages/backend

CMD ["node", "dist/index.js"] 