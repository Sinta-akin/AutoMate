# AI service (FastAPI)

Owns the AI-specific endpoints and pipelines:
- RAG chatbot: manual upload, text extraction, chunking, embeddings, vector storage, semantic retrieval, prompt construction and grounded response/fallback.
- Recommendations: content-based filtering, collaborative filtering, hybrid scoring, ranking and cold-start recommendations.

Suggested entry point: `app/main.py`.
Keep provider credentials in environment variables; never commit them.
