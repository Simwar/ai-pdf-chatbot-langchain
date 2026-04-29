# Build stage — treat the Next.js frontend as a standalone project.
# The backend workspace is not needed in this container (it connects to an
# external LangGraph API at runtime via NEXT_PUBLIC_LANGGRAPH_API_URL).
FROM node:20-slim AS builder

WORKDIR /app

COPY frontend/package.json ./
RUN npm install

COPY frontend/ ./
RUN npm run build

# Runtime stage
FROM node:20-slim

WORKDIR /app

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules

# The Astro spec requires interfaces.frontend agents to serve on port 80
ENV PORT=80
ENV NODE_ENV=production
EXPOSE 80

CMD ["node_modules/.bin/next", "start"]
