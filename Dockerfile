# Build stage — uses Node.js to match the yarn monorepo toolchain
FROM node:20-slim AS builder

WORKDIR /app

# Install ONLY frontend deps.
# Stub the backend workspace with an empty package.json so yarn doesn't attempt to
# build its native modules (chromadb → onnxruntime-node) — they aren't needed here.
COPY package.json yarn.lock turbo.json ./
COPY frontend/package.json ./frontend/
RUN mkdir -p backend && echo '{"name":"backend","version":"1.0.0","private":true}' > backend/package.json
RUN npm install -g yarn && yarn install --frozen-lockfile

# Build the Next.js frontend (COPY . . restores the real backend/package.json, which is fine
# since the packages are already installed and yarn workspace build doesn't re-install)
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
