#!/bin/bash
set -e

# Start the LangGraph backend on port 8123.
# langgraph-cli reads langgraph.json and runs the graphs via tsx (TypeScript-native).
(cd /app/backend && node_modules/.bin/langgraph-cli dev --port 8123) &

# Start the Next.js frontend on port 3000 (foreground — keeps the container alive).
cd /app/frontend && exec node node_modules/.bin/next start
