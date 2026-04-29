# Build stage
FROM oven/bun:1 AS builder

WORKDIR /app

COPY package.json ./
RUN bun install --frozen-lockfile

COPY . .

# Enable Next.js standalone output (add output: 'standalone' to next.config.js if not present)
RUN bun run build

# Runtime stage
FROM oven/bun:1-slim

WORKDIR /app

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public

# The spec requires the agent to serve on port 80
ENV PORT=80
EXPOSE 80

CMD ["bun", "run", "start"]