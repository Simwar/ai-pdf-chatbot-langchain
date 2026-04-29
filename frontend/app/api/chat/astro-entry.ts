/**
 * Astro entry point — fully wired LangChain PDF chatbot
 * This wraps the existing chat functionality for Astro messaging
 */
import {
  serve,
  type AgentAdapter,
  type StreamHooks,
  type StreamOptions,
} from '@astropods/adapter-core';

import { ChatOpenAI } from '@langchain/openai';
import { SupabaseVectorStore } from '@langchain/community/vectorstores/supabase';
import { OpenAIEmbeddings } from '@langchain/openai';
import { createClient } from '@supabase/supabase-js';
import { createStuffDocumentsChain } from 'langchain/chains/combine_documents';
import { createRetrievalChain } from 'langchain/chains/retrieval';
import { ChatPromptTemplate } from '@langchain/core/prompts';

const adapter: AgentAdapter = {
  name: 'ai-pdf-chatbot',

  async stream(prompt: string, hooks: StreamHooks, _options: StreamOptions): Promise<void> {
    try {
      hooks.onStatusUpdate({ type: 'thinking', label: 'Searching PDF knowledge base...' });

      // Initialize Supabase vector store
      const supabaseClient = createClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.SUPABASE_SERVICE_ROLE_KEY!
      );

      const embeddings = new OpenAIEmbeddings({
        openAIApiKey: process.env.OPENAI_API_KEY,
      });

      const vectorStore = await SupabaseVectorStore.fromExistingIndex(embeddings, {
        client: supabaseClient,
        tableName: 'documents',
        queryName: 'match_documents',
      });

      // Create retrieval chain
      const llm = new ChatOpenAI({
        modelName: 'gpt-4-turbo-preview',
        temperature: 0,
        streaming: true,
      });

      const questionPrompt = ChatPromptTemplate.fromTemplate(`
Use the following pieces of context to answer the question at the end.
If you don't know the answer, just say that you don't know, don't try to make up an answer.

Context: {context}

Question: {input}

Answer:`);

      const combineDocsChain = await createStuffDocumentsChain({
        llm,
        prompt: questionPrompt,
      });

      const retrievalChain = await createRetrievalChain({
        retriever: vectorStore.asRetriever(4),
        combineDocsChain,
      });

      // Stream the response
      const stream = await retrievalChain.stream({ input: prompt });

      for await (const chunk of stream) {
        if (chunk.answer) {
          hooks.onChunk(chunk.answer);
        }
      }

      hooks.onFinish();
    } catch (err) {
      hooks.onError(err instanceof Error ? err : new Error(String(err)));
    }
  },

  getConfig() {
    return {
      name: 'ai-pdf-chatbot',
      description: 'AI PDF chatbot powered by LangChain and Supabase vector search',
      tools: ['vector-search', 'document-qa'],
    };
  },
};

serve(adapter);
