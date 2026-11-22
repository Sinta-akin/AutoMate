# AutoMate

A Flutter/Dart peer-to-peer vehicle rental and automotive servicing platform with an AI automotive assistant and personalized vehicle recommendations.

## Repository layout

- `frontend/mobile` — Flutter Android application.
- `backend/core-api` — main REST API for platform/business workflows (Node.js service, as described in the AutoMate proposal).
- `backend/ai-service` — Python FastAPI service for RAG chatbot and recommendation endpoints.
- `database` — Firebase configuration, Firestore rules/indexes, Storage rules, emulator setup and seed data.
- `docs` — architecture, API, database, AI, design, sprint and testing documentation.
- `infra` — Docker and development scripts.
- `.github/workflows` — CI workflows.

## Planned technology

- Mobile: Flutter + Dart
- Core API: Node.js (implementation framework to be agreed by the team)
- Authentication/data/files: Firebase Authentication, Cloud Firestore and Firebase Storage
- AI API: Python + FastAPI
- AI: RAG pipeline, embeddings, vector search, LLM integration
- Recommendations: content-based, collaborative and hybrid filtering
- Local cache: Hive or SQLite

## Getting started

1. Install Flutter and the Android toolchain.
2. Create the Flutter project inside `frontend/mobile` (or move the generated Flutter project there).
3. Configure Firebase for the Android application. Do not commit service-account keys or private credentials.
4. Set up the core API and AI service independently; see their respective README files.
5. Copy `.env.example` files to local `.env` files and provide local credentials.

## Important

The submitted documents describe two slightly different backend arrangements: the AutoMate proposal describes a Node.js REST backend alongside Firebase, while the detailed implementation plan specifies FastAPI for the AI API. This scaffold keeps both responsibilities separate: the core API owns platform workflows, and FastAPI owns RAG/recommendation processing. Confirm this division with the team before implementation.

Never commit real API keys, Firebase service-account JSON files, signing keys, passwords or production credentials.
