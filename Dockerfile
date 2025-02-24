FROM node:20-bullseye-slim AS builder

WORKDIR /app

# Install dependencies required for building
RUN apt-get update && \
    apt-get install -y python3 build-essential git && \
    rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package.json yarn.lock ./

# Install dependencies
RUN yarn install --frozen-lockfile

# Copy the rest of the application
COPY . .

# Build both frontend and backend
RUN yarn tsc
RUN yarn build:backend
RUN yarn build

# Stage 2 - Production image
FROM node:20-bullseye-slim

WORKDIR /app

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y libsqlite3-dev python3 curl && \
    rm -rf /var/lib/apt/lists/*

# Copy built application
COPY --from=builder /app/packages/backend/dist ./dist
COPY --from=builder /app/packages/backend/package.json ./
COPY --from=builder /app/yarn.lock ./
COPY --from=builder /app/app-config.yaml ./
COPY --from=builder /app/packages/app/dist ./dist/packages/app/dist

# Install production dependencies
RUN yarn install --frozen-lockfile --production

# Fix permissions
RUN chmod -R 755 /app

EXPOSE 3000

CMD ["node", "dist/index.js"] 