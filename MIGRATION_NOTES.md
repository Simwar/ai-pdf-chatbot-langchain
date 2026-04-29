# Astro Migration Notes

## What Was Added

1. **astropods.yml** - Astro package configuration
   - Declares OpenAI model provider
   - Declares Supabase integration for vector storage
   - Enables frontend interface (serves on port 80)
   - Enables messaging interface (web chat)
   - Includes skeleton ingestion pipeline

2. **Dockerfile** - Multi-stage production build
   - Uses Bun runtime for faster TypeScript execution
   - Builds both backend and frontend workspaces
   - Exposes port 80 as required by Astro spec

3. **backend/astro-adapter.ts** - Adapter stub
   - Template for wiring your LangChain agent to Astro
   - Implements AgentAdapter interface
   - **NEEDS CUSTOMIZATION** - see TODO comments

## Next Steps

### 1. Wire the LangChain Agent

Edit `backend/astro-adapter.ts` and:
- Import your existing chat chain/agent
- Implement `processMessage()` to invoke your chain
- Implement `streamMessage()` if you want streaming responses

### 2. Update the Dockerfile CMD

The current Dockerfile uses `CMD ["bun", "run", "start"]`. You need to:
- Check your `package.json` scripts
- Ensure the `start` script runs both frontend + backend
- Or update the CMD to run the correct command

### 3. Configure Environment Variables

Before deploying to Astro, you'll need:

**OpenAI:**
- `OPENAI_API_KEY`

**Supabase:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY` or `SUPABASE_SERVICE_ROLE_KEY`

**Other:**
- Any other environment variables your agent needs

### 4. Test Locally

```bash
# Build the Docker image
docker build -t ai-pdf-chatbot .

# Run with environment variables
docker run -p 80:80 \
  -e OPENAI_API_KEY=your-key \
  -e SUPABASE_URL=your-url \
  -e SUPABASE_ANON_KEY=your-key \
  ai-pdf-chatbot
```

Visit http://localhost to test the UI.

### 5. Deploy to Astro

Once the adapter is wired and tested:

```bash
astro deploy
```

The Astro CLI will:
- Build your Docker image
- Push to Astro registry
- Provision OpenAI + Supabase integrations
- Deploy your agent with the web messaging interface

## Architecture Notes

This is a **monorepo migration** - the agent keeps its existing structure:
- **Backend**: LangChain agent + API (unchanged, just wired to Astro)
- **Frontend**: Existing chat UI (served on port 80)
- **No rewriting required**: Your LangChain code stays exactly as-is

The Astro adapter is a thin integration layer that connects your agent to Astro's messaging system while preserving your original architecture.

## Questions?

Check the generated `ASTRO.md` for deployment details, or refer to the Astro documentation at https://docs.astropods.ai
