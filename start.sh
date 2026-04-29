#!/bin/bash
set -e

# langgraph-cli requires the .env file declared in langgraph.json to exist.
# In a container env vars come from the runtime (ast configure), so an empty file is enough.
touch /app/backend/.env

# Start the LangGraph backend on port 2024.
# langgraph-cli reads langgraph.json and runs the graphs via tsx (TypeScript-native).
(cd /app/backend && node_modules/.bin/langgraphjs dev --no-browser --host 0.0.0.0 -c /app/backend) &

# Start the Next.js frontend on port 3000 (foreground — keeps the container alive).
cd /app/frontend && exec node node_modules/.bin/next start
