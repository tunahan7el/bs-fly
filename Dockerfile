# Stage 1 - Build the application
FROM node:18-bullseye-slim AS builder

WORKDIR /app

# Install dependencies required for building
RUN apt-get update && \
    apt-get install -y python3 build-essential git && \
    rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package.json ./

# Install dependencies and generate lockfile
RUN yarn install

# Copy the rest of the application
COPY . .

# Build
RUN yarn tsc && \
    yarn build

# Stage 2 - Create the production image
FROM node:18-bullseye-slim

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y libsqlite3-dev python3 curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled production files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
COPY --from=builder /app/yarn.lock ./
COPY --from=builder /app/app-config.yaml ./

# Install production dependencies
RUN yarn install --production

# The fix-permissions script is needed to ensure correct file permissions
RUN chmod -R 755 /app

EXPOSE 3000

CMD ["node", "dist/index.js", "--config", "app-config.yaml"] 