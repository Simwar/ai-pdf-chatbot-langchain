# Multi-stage build for monorepo
FROM oven/bun:1 AS builder

WORKDIR /app

# Copy root package files
COPY package.json yarn.lock turbo.json ./

# Copy workspace package files
COPY backend/package.json ./backend/
COPY frontend/package.json ./frontend/

# Install all dependencies
RUN bun install --frozen-lockfile

# Copy all source code
COPY . .

# Build both workspaces
RUN bun run build

# Runtime stage
FROM oven/bun:1-slim

WORKDIR /app

# Copy built artifacts and dependencies
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/backend ./backend
COPY --from=builder /app/frontend ./frontend
COPY --from=builder /app/package.json ./
COPY --from=builder /app/turbo.json ./

ENV PORT=80
EXPOSE 80

# Start both frontend and backend
# Adjust this command based on the actual start scripts in package.json
CMD ["bun", "run", "start"]
