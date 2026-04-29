---
description: "Upload PDFs and chat with them using LangChain and LangGraph. Documents are embedded and stored in pgvector for semantic retrieval."
tags: [rag, pdf, langchain, langgraph, document-qa, pgvector]
capabilities:
  - Ingest PDF documents and store them as vector embeddings
  - Answer questions about uploaded documents using semantic search
  - Maintain conversation history across multiple turns
repository: https://github.com/mayooear/ai-pdf-chatbot-langchain
integrations: [openai, postgres]
---

# AI PDF Chatbot

Upload one or more PDF documents and ask questions about their content. The agent retrieves the most relevant passages using vector search and generates grounded answers via GPT-4o.

## How it works

1. **Ingest** — PDFs are parsed, chunked, embedded with `text-embedding-3-small`, and stored in a pgvector database.
2. **Retrieve** — When you ask a question, the top-k most relevant chunks are retrieved using cosine similarity search.
3. **Generate** — The retrieval graph passes the chunks as context to GPT-4o to produce a grounded answer with source citations.

## Usage

Open the frontend at the agent URL, upload up to 5 PDFs (10 MB each), then type your question in the chat box. The agent will answer based on the content of your documents.

## Limitations

- PDF only — other file formats are not supported.
- Max 5 files per upload, 10 MB per file.
- The underlying LangGraph dev server is an in-memory store; ingested documents persist only for the lifetime of the running container unless a persistent volume is attached to the postgres knowledge store.
