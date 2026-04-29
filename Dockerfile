# Build stage — treat the Next.js frontend as a standalone project.
# The backend workspace is not needed in this container (it connects to an
# external LangGraph API at runtime via NEXT_PUBLIC_LANGGRAPH_API_URL).
FROM node:20-slim AS builder

WORKDIR /app

COPY frontend/package.json ./
RUN npm install

COPY frontend/ ./

# langgraph-client.ts and langgraph-server.ts both call createClient() / createServerClient()
# at module level, which throw immediately if these vars are missing — and Next.js evaluates
# them at build time. Set placeholders here so the build succeeds; real values are injected
# at runtime via `ast configure`.
ENV NEXT_PUBLIC_LANGGRAPH_API_URL=http://placeholder
ENV LANGCHAIN_API_KEY=placeholder
ENV LANGGRAPH_RETRIEVAL_ASSISTANT_ID=retrieval_graph
ENV LANGGRAPH_INGESTION_ASSISTANT_ID=ingestion_graph

RUN npm run build

# Runtime stage
FROM node:20-slim

WORKDIR /app

COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/package.json ./
COPY --from=builder /app/node_modules ./node_modules

# Default env vars — langgraph-server.ts calls createServerClient() at module load time
# and throws immediately if these are missing. Provide defaults so the server starts;
# real values are injected by `ast configure` and override these at runtime.
ENV NEXT_PUBLIC_LANGGRAPH_API_URL=http://placeholder
ENV LANGCHAIN_API_KEY=placeholder
ENV LANGGRAPH_RETRIEVAL_ASSISTANT_ID=retrieval_graph
ENV LANGGRAPH_INGESTION_ASSISTANT_ID=ingestion_graph

# Port must match dev.interfaces.frontend.port in astropods.yml (3000).
# ast dev forwards container:3000 → localhost:3000; the platform proxies 80 → 3000 in production.
ENV PORT=3000
ENV NODE_ENV=production
EXPOSE 3000

CMD ["node_modules/.bin/next", "start"]
