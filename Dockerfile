# Build stage — uses Node.js to match the yarn monorepo toolchain
FROM node:20-slim AS builder

WORKDIR /app

# Install dependencies (yarn.lock drives resolution in this monorepo)
COPY package.json yarn.lock turbo.json ./
COPY frontend/package.json ./frontend/
COPY backend/package.json ./backend/
RUN yarn install --frozen-lockfile

# Build the Next.js frontend
COPY . .
RUN yarn workspace frontend build

# Runtime stage
FROM node:20-slim

WORKDIR /app

# next is hoisted to the root node_modules
COPY --from=builder /app/node_modules ./node_modules
# Only copy what next start needs
COPY --from=builder /app/frontend/.next ./frontend/.next
COPY --from=builder /app/frontend/public ./frontend/public
COPY --from=builder /app/frontend/package.json ./frontend/package.json

# The Astro spec requires interfaces.frontend agents to serve on port 80
ENV PORT=80
ENV NODE_ENV=production
EXPOSE 80

WORKDIR /app/frontend
CMD ["/app/node_modules/.bin/next", "start"]
