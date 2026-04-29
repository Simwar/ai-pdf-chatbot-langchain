/**
 * Astro entry point — wires the LangGraph retrieval graph to Astro messaging.
 *
 * This lets the agent be used via the Astro chat interface in addition to its
 * own Next.js frontend. The existing frontend code is not affected.
 *
 * Required environment variables:
 *   NEXT_PUBLIC_LANGGRAPH_API_URL       — URL of the LangGraph API server
 *   LANGCHAIN_API_KEY                   — LangGraph / LangSmith API key
 *   LANGGRAPH_RETRIEVAL_ASSISTANT_ID    — assistant/graph ID (default: "retrieval_graph")
 */

import {
  serve,
  type AgentAdapter,
  type StreamHooks,
  type StreamOptions,
} from '@astropods/adapter-core';
import { Client } from '@langchain/langgraph-sdk';

const adapter: AgentAdapter = {
  name: 'ai-pdf-chatbot-langchain',

  async stream(prompt: string, hooks: StreamHooks, _options: StreamOptions): Promise<void> {
    try {
      const client = new Client({
        apiUrl: process.env.NEXT_PUBLIC_LANGGRAPH_API_URL ?? 'http://localhost:2024',
        defaultHeaders: process.env.LANGCHAIN_API_KEY
          ? { 'X-Api-Key': process.env.LANGCHAIN_API_KEY }
          : {},
      });

      const assistantId =
        process.env.LANGGRAPH_RETRIEVAL_ASSISTANT_ID ?? 'retrieval_graph';

      const thread = await client.threads.create();

      const streamEvents = client.runs.stream(thread.thread_id, assistantId, {
        input: { query: prompt },
        streamMode: ['messages'],
      });

      for await (const event of streamEvents) {
        if (event.event === 'messages/partial') {
          for (const msg of event.data as any[]) {
            const text = typeof msg.content === 'string' ? msg.content : '';
            if (text) hooks.onChunk(text);
          }
        }
      }

      hooks.onFinish();
    } catch (err) {
      hooks.onError(err instanceof Error ? err : new Error(String(err)));
    }
  },

  getConfig() {
    return {
      name: 'ai-pdf-chatbot-langchain',
      description: 'AI PDF chatbot with LangChain & LangGraph for document Q&A',
      tools: [],
    };
  },
};

serve(adapter);
