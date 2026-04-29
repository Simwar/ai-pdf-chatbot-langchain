# ─── Frontend build ───────────────────────────────────────────────────────────
# Treat the Next.js frontend as a standalone project to avoid triggering
# native module compilation (chromadb → onnxruntime-node) from the backend workspace.
FROM node:20-slim AS frontend-builder

WORKDIR /app/frontend

COPY frontend/package.json ./
RUN npm install
COPY frontend/ ./

# The backend runs co-located on port 8123; bake that URL in at build time.
# Server-side routes (API routes) read this from process.env at runtime so the
# value injected by `ast configure` will override it for the LangGraph URL.
ENV NEXT_PUBLIC_LANGGRAPH_API_URL=http://localhost:8123
ENV LANGGRAPH_RETRIEVAL_ASSISTANT_ID=retrieval_graph
ENV LANGGRAPH_INGESTION_ASSISTANT_ID=ingestion_graph

RUN npm run build

# ─── Backend dependencies ─────────────────────────────────────────────────────
# Install with build tools so that any native modules (onnxruntime-node via chromadb)
# can compile if no pre-built binary is available for this platform.
FROM node:20-slim AS backend-deps

RUN apt-get update && apt-get install -y python3 make g++ && rm -rf /var/lib/apt/lists/*

WORKDIR /app/backend

COPY backend/package.json ./
RUN npm install

# ─── Runtime ─────────────────────────────────────────────────────────────────
FROM node:20-slim

WORKDIR /app

# Frontend
COPY --from=frontend-builder /app/frontend/.next    ./frontend/.next
COPY --from=frontend-builder /app/frontend/public   ./frontend/public
COPY --from=frontend-builder /app/frontend/package.json ./frontend/
COPY --from=frontend-builder /app/frontend/node_modules ./frontend/node_modules

# Backend: deps built above + TypeScript source (langgraph-cli reads .ts directly via tsx)
COPY --from=backend-deps /app/backend/node_modules ./backend/node_modules
COPY backend/ ./backend/

# Backend LangGraph server (co-located, reachable at localhost:8123)
ENV NEXT_PUBLIC_LANGGRAPH_API_URL=http://localhost:8123
ENV LANGGRAPH_RETRIEVAL_ASSISTANT_ID=retrieval_graph
ENV LANGGRAPH_INGESTION_ASSISTANT_ID=ingestion_graph

# Frontend
ENV PORT=3000
ENV NODE_ENV=production

COPY start.sh ./
RUN chmod +x start.sh

EXPOSE 3000
CMD ["./start.sh"]
