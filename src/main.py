import logging
import os
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi
from src.config import get_settings
from src.db.factory import make_database
from src.routers import agentic_ask, hybrid_search, ping
from src.routers.ask import ask_router, stream_router
from src.services.arxiv.factory import make_arxiv_client
from src.services.cache.factory import make_cache_client
from src.services.embeddings.factory import make_embeddings_service
from src.services.langfuse.factory import make_langfuse_tracer
from src.services.ollama.factory import make_ollama_client
from src.services.opensearch.factory import make_opensearch_client
from src.services.pdf_parser.factory import make_pdf_parser_service
from src.services.telegram.factory import make_telegram_service

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan for the API.
    """
    logger.info("Starting RAG API...")

    settings = get_settings()
    app.state.settings = settings

    database = make_database()
    app.state.database = database
    logger.info("Database connected")

    # Initialize search service
    opensearch_client = make_opensearch_client()
    app.state.opensearch_client = opensearch_client

    # Verify OpenSearch connectivity and create index if needed
    if opensearch_client.health_check():
        logger.info("OpenSearch connected successfully")

        # Setup hybrid index (supports all search types)
        setup_results = opensearch_client.setup_indices(force=False)
        if setup_results.get("hybrid_index"):
            logger.info("Hybrid index created")
        else:
            logger.info("Hybrid index already exists")

        # Get simple statistics
        try:
            stats = opensearch_client.client.count(index=opensearch_client.index_name)
            logger.info(f"OpenSearch ready: {stats['count']} documents indexed")
        except Exception:
            logger.info("OpenSearch index ready (stats unavailable)")
    else:
        logger.warning("OpenSearch connection failed - search features will be limited")

    # Initialize other services (kept for future endpoints and notebook demos)
    app.state.arxiv_client = make_arxiv_client()
    app.state.pdf_parser = make_pdf_parser_service()
    app.state.embeddings_service = make_embeddings_service()
    app.state.ollama_client = make_ollama_client()
    app.state.langfuse_tracer = make_langfuse_tracer()
    app.state.cache_client = make_cache_client(settings)
    logger.info("Services initialized: arXiv API client, PDF parser, OpenSearch, Embeddings, Ollama, Langfuse, Cache")

    # Initialize Telegram bot (Week 7)
    telegram_service = make_telegram_service(
        opensearch_client=app.state.opensearch_client,
        embeddings_client=app.state.embeddings_service,
        ollama_client=app.state.ollama_client,
        cache_client=app.state.cache_client,
        langfuse_tracer=app.state.langfuse_tracer,
    )

    if telegram_service:
        app.state.telegram_service = telegram_service
        try:
            await telegram_service.start()
            logger.info("Telegram bot started successfully")
        except Exception as e:
            logger.error(f"Failed to start Telegram bot: {e}")
    else:
        logger.info("Telegram bot not configured - skipping initialization")

    logger.info("API ready")
    yield

    # Cleanup
    if hasattr(app.state, "telegram_service") and app.state.telegram_service:
        await app.state.telegram_service.stop()
        logger.info("Telegram bot stopped")

    database.teardown()
    logger.info("API shutdown complete")


app = FastAPI(
    title="arXiv Paper Curator API",
    description="""
# 🎓 Academic Research Assistant with RAG

A production-grade **Retrieval-Augmented Generation** system for academic papers from arXiv.

## ✨ Key Features

- **🔍 Hybrid Search**: BM25 keyword + Vector similarity (Jina 1024-dim)
- **🤖 Agentic RAG**: Intelligent retrieval with LangGraph decision-making
- **📊 Real-time Tracing**: Langfuse observability for every request
- **⚡ High Performance**: Redis caching with 6-hour TTL
- **📡 Streaming Support**: Server-Sent Events for real-time responses
- **📱 Mobile Access**: Telegram bot integration

## 🚀 Quick Start

1. **Health Check**: `GET /api/v1/health` - Verify all services
2. **Search Papers**: `POST /api/v1/hybrid-search/` - Find relevant papers
3. **Ask Questions**: `POST /api/v1/ask-agentic` - Get intelligent answers

## 🏗️ Architecture

```
User Query → Guardrail → Hybrid Search → Document Grading → Answer Generation
                ↓                              ↓
            Out of Scope?              Not Relevant? → Query Rewriting
```

## 🔗 Resources

- **Blog Series**: [The Mother of AI Projects](https://jamwithai.substack.com/p/the-mother-of-ai-project)
- **Source Code**: [GitHub Repository](https://github.com/Yemu-Yu/arxiv-paper-curator)
- **Gradio UI**: http://localhost:7861
- **Langfuse Dashboard**: http://localhost:3001

## 📞 Support

For issues and feature requests, visit [GitHub Issues](https://github.com/Yemu-Yu/arxiv-paper-curator/issues).
    """,
    version=os.getenv("APP_VERSION", "0.1.0"),
    lifespan=lifespan,

    # Contact information
    contact={
        "name": "arXiv Paper Curator Team",
        "url": "https://github.com/Yemu-Yu/arxiv-paper-curator",
        "email": "contact@example.com"
    },

    # License
    license_info={
        "name": "MIT License",
        "url": "https://github.com/Yemu-Yu/arxiv-paper-curator/blob/main/LICENSE"
    },

    # Server configuration (displayed in Scalar UI)
    servers=[
        {
            "url": "http://localhost:8000",
            "description": "🛠️ Development Server (Local)"
        },
        {
            "url": "http://api:8000",
            "description": "🐳 Docker Internal Network"
        }
    ],

    # Tags grouping (for Scalar sidebar)
    openapi_tags=[
        {
            "name": "Health",
            "description": """
## 🏥 System Health & Monitoring

Monitor the health of all backend services including:
- PostgreSQL database
- OpenSearch search engine
- Ollama LLM service
- Redis cache
- Langfuse tracing

**Use Case**: Include this endpoint in your monitoring/alerting system.
            """,
            "externalDocs": {
                "description": "Health Check Pattern",
                "url": "https://microservices.io/patterns/observability/health-check-api.html"
            }
        },
        {
            "name": "hybrid-search",
            "description": """
## 🔍 Hybrid Document Search

Search academic papers using **BM25** (keyword) + **Vector Similarity** (semantic).

### How It Works

1. **BM25 Search**: Traditional keyword matching on paper text
2. **Vector Search**: Semantic similarity using Jina embeddings (1024-dim)
3. **RRF Fusion**: Combines both using Reciprocal Rank Fusion

### Best Practices

- Use `use_hybrid=true` for best results (combines keyword + semantic)
- Use `categories` filter to narrow down to specific arXiv categories
- Set `min_score` to filter low-relevance results

**Performance**: 200-500ms average latency.
            """,
            "externalDocs": {
                "description": "Hybrid Search Tutorial",
                "url": "https://jamwithai.substack.com/p/chunking-strategies-and-hybrid-rag"
            }
        },
        {
            "name": "ask",
            "description": """
## 💬 Basic RAG Q&A

Simple Retrieval-Augmented Generation with **Redis caching**.

### Features

- Fast responses for repeated queries (6-hour cache TTL)
- Configurable retrieval (`top_k`)
- Support for BM25-only or hybrid search
- Multiple LLM models (llama3.2:1b, llama3.2:3b, qwen2.5:7b)

### When to Use

- Quick prototyping
- Non-streaming responses needed
- Cache-friendly workloads

**Average Latency**: 2-4 seconds for cache miss, <50ms for cache hit.
            """
        },
        {
            "name": "stream",
            "description": """
## 📡 Streaming RAG (Server-Sent Events)

Real-time streaming responses using **SSE protocol**.

### How It Works

1. **Metadata Event**: Sources and search metadata
2. **Chunk Events**: Real-time answer chunks as LLM generates
3. **Completion**: Empty `data: [DONE]` event

### Integration

```javascript
const eventSource = new EventSource('/api/v1/stream', {
    method: 'POST',
    body: JSON.stringify({query: "What is RAG?", top_k: 5})
});

eventSource.onmessage = (event) => {
    const data = JSON.parse(event.data);
    if (data.chunk) console.log(data.chunk);
};
```

**Recommended For**: Interactive UIs, chatbots, real-time applications.
            """
        },
        {
            "name": "agentic-rag",
            "description": """
## 🤖 Agentic RAG (Intelligent Retrieval)

Advanced RAG with **LangGraph** decision-making engine.

### Agent Capabilities

- **Guardrail**: Filters out-of-scope queries (non-academic topics)
- **Document Grading**: Evaluates chunk relevance (binary: relevant/not relevant)
- **Query Rewriting**: Rewrites ambiguous queries for better retrieval
- **Adaptive Retrieval**: Iterates up to 3 times if initial chunks are irrelevant

### Workflow

```
Input Query → Guardrail Check → Hybrid Search → Grade Chunks
                                        ↓
                                Not Relevant? → Rewrite Query → Retry (max 3x)
                                        ↓
                                   Relevant → Generate Answer
```

**Best For**: Complex academic questions requiring intelligent document selection.
            """,
            "externalDocs": {
                "description": "LangGraph Tutorial",
                "url": "https://langchain-ai.github.io/langgraph/"
            }
        }
    ]
)

# Custom OpenAPI schema with Scalar enhancements
def custom_openapi():
    """
    Enhanced OpenAPI schema with Scalar extensions.
    """
    if app.openapi_schema:
        return app.openapi_schema

    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
        servers=app.servers,
        tags=app.openapi_tags,
    )

    # Add security schemes (future feature)
    if "securitySchemes" not in openapi_schema.get("components", {}):
        openapi_schema.setdefault("components", {})["securitySchemes"] = {
            "ApiKeyAuth": {
                "type": "apiKey",
                "in": "header",
                "name": "X-API-Key",
                "description": "API key for authentication (future feature)"
            }
        }

    # Scalar Tag Groups (grouped display)
    openapi_schema["x-tagGroups"] = [
        {
            "name": "Core Services",
            "tags": ["Health", "hybrid-search"]
        },
        {
            "name": "RAG Endpoints",
            "tags": ["ask", "stream", "agentic-rag"]
        }
    ]

    app.openapi_schema = openapi_schema
    return app.openapi_schema


# Apply custom OpenAPI
app.openapi = custom_openapi

# Include routers
app.include_router(ping.router, prefix="/api/v1")  # Health check endpoint
app.include_router(hybrid_search.router, prefix="/api/v1")  # Search chunks with BM25/hybrid
app.include_router(ask_router, prefix="/api/v1")  # RAG question answering with LLM
app.include_router(stream_router, prefix="/api/v1")  # Streaming RAG responses
app.include_router(agentic_ask.router)  # Agentic RAG with intelligent retrieval


if __name__ == "__main__":
    uvicorn.run(app, port=8000, host="0.0.0.0")
