import { VectorStoreRetriever } from '@langchain/core/vectorstores';
import { OpenAIEmbeddings } from '@langchain/openai';
import { PGVectorStore } from '@langchain/community/vectorstores/pgvector';
import { Pool } from 'pg';
import { RunnableConfig } from '@langchain/core/runnables';
import {
  BaseConfigurationAnnotation,
  ensureBaseConfiguration,
} from './configuration.js';

export async function makePostgresRetriever(
  configuration: typeof BaseConfigurationAnnotation.State,
): Promise<VectorStoreRetriever> {
  const embeddings = new OpenAIEmbeddings({
    model: 'text-embedding-3-small',
  });

  // POSTGRES_HOST/PORT are injected by the platform's knowledge provider.
  // Credentials are hardcoded to the postgres superuser defaults — the platform
  // does not propagate knowledge input values to the agent container (see memory-box pattern).
  const pool = new Pool({
    host: process.env.POSTGRES_HOST ?? 'localhost',
    port: parseInt(process.env.POSTGRES_PORT ?? '5432'),
    database: 'postgres',
    user: 'postgres',
    password: 'postgres',
  });

  // Creates the pgvector extension and documents table if they don't exist yet.
  const vectorStore = await PGVectorStore.initialize(embeddings, {
    pool,
    tableName: 'documents',
    columns: {
      idColumnName: 'id',
      vectorColumnName: 'embedding',
      contentColumnName: 'content',
      metadataColumnName: 'metadata',
    },
  });

  return vectorStore.asRetriever({
    k: configuration.k,
    filter: configuration.filterKwargs,
  });
}

export async function makeRetriever(
  config: RunnableConfig,
): Promise<VectorStoreRetriever> {
  const configuration = ensureBaseConfiguration(config);
  switch (configuration.retrieverProvider) {
    case 'postgres':
      return makePostgresRetriever(configuration);
    default:
      throw new Error(
        `Unsupported retriever provider: ${configuration.retrieverProvider}`,
      );
  }
}
