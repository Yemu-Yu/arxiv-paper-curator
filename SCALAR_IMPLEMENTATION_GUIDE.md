# Scalar 本地自托管 - 详细实施指南

## 📋 实施概述

**方案**: Scalar 本地自托管（方案 A）
**时间**: 2 周（10 个工作日）
**团队**: 1-2 人
**成本**: $0

**目标架构**:
```
┌─────────────────────────────────────────────────┐
│              用户浏览器                          │
└────────┬────────────────────────────────────────┘
         │
         ├─── http://localhost:8000/docs (原 Swagger UI)
         ├─── http://localhost:7998 (新 Scalar UI) ⭐
         └─── http://localhost:8000/api/v1/* (API 直连)

┌─────────────────────────────────────────────────┐
│           Docker Compose 服务                    │
├─────────────────────────────────────────────────┤
│  Scalar UI (7998) ──► FastAPI (8000)            │
│                       └─ OpenAPI Spec           │
└─────────────────────────────────────────────────┘
```

---

## 📅 10 天详细计划

### Day 1-2: OpenAPI 规范增强

#### 任务清单
- [x] 审计当前 OpenAPI 规范
- [ ] 增强 FastAPI 元数据
- [ ] 修复 `/stream` 端点定义
- [ ] 添加丰富的 examples
- [ ] 验证规范合法性

---

### Day 3-4: Scalar 服务集成

#### 任务清单
- [ ] 添加 Scalar 到 docker-compose
- [ ] 配置环境变量
- [ ] 测试本地访问
- [ ] 优化 UI 主题

---

### Day 5-6: 文档质量提升

#### 任务清单
- [ ] 添加代码示例
- [ ] 完善错误响应
- [ ] 添加认证说明
- [ ] 创建快速开始指南

---

### Day 7-8: 测试和优化

#### 任务清单
- [ ] 端到端测试
- [ ] 性能测试
- [ ] SSE 流式测试
- [ ] 修复发现的问题

---

### Day 9-10: 部署和文档

#### 任务清单
- [ ] 更新 README
- [ ] 编写用户指南
- [ ] 团队培训
- [ ] 上线验收

---

## 🔧 Day 1-2: OpenAPI 规范增强

### 步骤 1.1: 增强 FastAPI 应用元数据

**文件**: `src/main.py`

**当前代码**:
```python
app = FastAPI(
    title="arXiv Paper Curator API",
    description="Personal arXiv CS.AI paper curator with RAG capabilities",
    version=os.getenv("APP_VERSION", "0.1.0"),
    lifespan=lifespan,
)
```

**增强后的代码**:
```python
# src/main.py
import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

# ... existing imports ...

@asynccontextmanager
async def lifespan(app: FastAPI):
    # ... existing lifespan code ...
    yield
    # ... existing cleanup code ...


# 创建 FastAPI 应用（增强版）
app = FastAPI(
    title="arXiv Paper Curator API",
    description="""
# 🎓 Academic Research Assistant with RAG

A production-grade Retrieval-Augmented Generation system for academic papers from arXiv.

## 🌟 Key Features

- **Hybrid Search**: BM25 keyword search + Vector similarity (Jina 1024-dim)
- **Agentic RAG**: Intelligent retrieval with LangGraph decision-making
- **Real-time Monitoring**: Langfuse tracing for every request
- **High Performance**: Redis caching (6-hour TTL)
- **Streaming Support**: Server-Sent Events for real-time responses
- **Mobile Access**: Telegram bot integration

## 🚀 Quick Start

1. **Health Check**: `GET /api/v1/health` - Verify all services are running
2. **Search Papers**: `POST /api/v1/hybrid-search` - Find relevant papers
3. **Ask Questions**: `POST /api/v1/ask-agentic` - Get intelligent answers

## 📊 Architecture

```
User Query → Guardrail → Hybrid Search → Document Grading → Answer Generation
                ↓                              ↓
            Out of Scope?              Not Relevant? → Query Rewriting
```

## 🔗 External Resources

- **Blog Series**: https://jamwithai.substack.com/p/the-mother-of-ai-project
- **GitHub**: https://github.com/jamwithai/arxiv-paper-curator
- **Langfuse Dashboard**: http://localhost:3000
- **Gradio UI**: http://localhost:7861

## 📞 Support

For issues and feature requests, visit our [GitHub Issues](https://github.com/jamwithai/arxiv-paper-curator/issues).
    """,
    version=os.getenv("APP_VERSION", "0.1.0"),
    lifespan=lifespan,

    # 联系信息
    contact={
        "name": "arXiv Paper Curator Team",
        "url": "https://github.com/jamwithai/arxiv-paper-curator",
        "email": "support@jamwithai.com"
    },

    # 许可证
    license_info={
        "name": "MIT License",
        "url": "https://github.com/jamwithai/arxiv-paper-curator/blob/main/LICENSE"
    },

    # 服务器配置
    servers=[
        {
            "url": "http://localhost:8000",
            "description": "🛠️ Development Server (Local)"
        },
        {
            "url": "http://api.arxiv-curator.local",
            "description": "🐳 Docker Internal Network"
        }
    ],

    # Tags 分类（用于 Scalar 分组）
    openapi_tags=[
        {
            "name": "Health",
            "description": "🏥 **System Health & Monitoring**\n\nMonitor the health of all backend services including PostgreSQL, OpenSearch, and Ollama.",
            "externalDocs": {
                "description": "Health Check Best Practices",
                "url": "https://learn.microsoft.com/en-us/azure/architecture/patterns/health-endpoint-monitoring"
            }
        },
        {
            "name": "hybrid-search",
            "description": "🔍 **Hybrid Document Search**\n\nSearch academic papers using BM25 (keyword) and vector similarity. Uses Reciprocal Rank Fusion (RRF) for optimal results.",
            "externalDocs": {
                "description": "Learn about Hybrid Search",
                "url": "https://jamwithai.substack.com/p/chunking-strategies-and-hybrid-rag"
            }
        },
        {
            "name": "ask",
            "description": "💬 **Basic RAG Q&A**\n\nBasic Retrieval-Augmented Generation with caching. Fast responses for repeated queries.",
        },
        {
            "name": "stream",
            "description": "⚡ **Streaming Responses**\n\nReal-time streaming with Server-Sent Events. Ideal for chat interfaces.",
        },
        {
            "name": "agentic-rag",
            "description": "🤖 **Agentic RAG (LangGraph)**\n\n**Intelligent RAG with Decision-Making**\n\n- Query validation (Guardrail)\n- Adaptive retrieval (Document grading)\n- Automatic query rewriting\n- Full reasoning transparency\n\n**Workflow**: Guardrail → Retrieve → Grade → Rewrite/Generate",
            "externalDocs": {
                "description": "Agentic RAG Tutorial",
                "url": "https://jamwithai.substack.com/p/agentic-rag-with-langgraph-and-telegram"
            }
        }
    ],

    # Swagger UI 配置（保留用于对比）
    swagger_ui_parameters={
        "defaultModelsExpandDepth": -1,  # 隐藏 schemas
        "docExpansion": "list",
        "filter": True,
        "syntaxHighlight.theme": "monokai"
    },

    # ReDoc 配置
    redoc_url="/redoc",

    # 响应示例配置
    generate_unique_id_function=lambda route: f"{route.tags[0]}_{route.name}" if route.tags else route.name
)


# 自定义 OpenAPI Schema (添加 Scalar 优化)
def custom_openapi():
    """Generate enhanced OpenAPI schema for Scalar"""
    if app.openapi_schema:
        return app.openapi_schema

    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
        tags=app.openapi_tags,
        servers=app.servers,
        contact=app.contact,
        license_info=app.license_info,
    )

    # 添加 x-logo (Scalar 自定义扩展)
    openapi_schema["info"]["x-logo"] = {
        "url": "https://raw.githubusercontent.com/jamwithai/arxiv-paper-curator/main/static/logo.png",
        "altText": "arXiv Paper Curator Logo"
    }

    # 添加全局安全方案定义（未来使用）
    openapi_schema["components"]["securitySchemes"] = {
        "ApiKeyAuth": {
            "type": "apiKey",
            "in": "header",
            "name": "X-API-Key",
            "description": "API key for authentication (future implementation)"
        },
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
            "description": "JWT bearer token (future implementation)"
        }
    }

    # Scalar 特定扩展
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


# 应用自定义 OpenAPI
app.openapi = custom_openapi

# Include routers (existing code)
app.include_router(ping.router, prefix="/api/v1")
app.include_router(hybrid_search.router, prefix="/api/v1")
app.include_router(ask_router, prefix="/api/v1")
app.include_router(stream_router, prefix="/api/v1")
app.include_router(agentic_ask.router)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, port=8000, host="0.0.0.0")
```

---

### 步骤 1.2: 修复 `/stream` 端点的 OpenAPI 定义

**问题**: SSE 响应没有明确的 schema

**文件**: `src/routers/ask.py`

**添加 SSE Schema 定义**:
```python
# src/routers/ask.py
from typing import Optional, List
from pydantic import BaseModel, Field

# ... existing imports ...

# 新增: SSE 事件 Schema
class SSEMetadataEvent(BaseModel):
    """First SSE event with metadata"""
    sources: List[str] = Field(..., description="List of source PDF URLs")
    chunks_used: int = Field(..., description="Number of chunks retrieved")
    search_mode: str = Field(..., description="Search mode: bm25 or hybrid")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "sources": ["https://arxiv.org/pdf/1706.03762.pdf"],
                "chunks_used": 3,
                "search_mode": "hybrid"
            }
        }
    )


class SSEChunkEvent(BaseModel):
    """Streaming text chunk event"""
    chunk: str = Field(..., description="Text fragment from LLM")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {"chunk": "Based on "}
        }
    )


class SSEDoneEvent(BaseModel):
    """Final completion event"""
    answer: str = Field(..., description="Complete generated answer")
    done: bool = Field(True, description="Stream completion flag")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "answer": "Transformers are neural network architectures...",
                "done": True
            }
        }
    )


class SSEErrorEvent(BaseModel):
    """Error event"""
    error: str = Field(..., description="Error message")

    model_config = ConfigDict(
        json_schema_extra={
            "example": {"error": "Search service unavailable"}
        }
    )


# 修改 /stream 端点
@stream_router.post(
    "/stream",
    responses={
        200: {
            "description": "Server-Sent Events stream with JSON payloads",
            "content": {
                "text/event-stream": {
                    "schema": {
                        "type": "string",
                        "format": "binary",
                        "description": "SSE stream with newline-delimited JSON events"
                    },
                    "examples": {
                        "complete_flow": {
                            "summary": "Complete SSE Flow",
                            "value": """data: {"sources": ["https://arxiv.org/pdf/1706.03762.pdf"], "chunks_used": 3, "search_mode": "hybrid"}

data: {"chunk": "Based on "}

data: {"chunk": "the research "}

data: {"chunk": "papers, "}

data: {"answer": "Based on the research papers, transformers...", "done": true}
"""
                        }
                    }
                }
            }
        },
        500: {
            "description": "Server error during streaming",
            "content": {
                "text/event-stream": {
                    "example": 'data: {"error": "Internal server error"}\n\n'
                }
            }
        }
    },
    summary="Stream RAG answer in real-time",
    description="""
## Real-time Streaming RAG

Get RAG answers with **Server-Sent Events (SSE)** for a better user experience.

### Event Sequence

1. **Metadata Event** (first):
   ```json
   {"sources": [...], "chunks_used": 3, "search_mode": "hybrid"}
   ```

2. **Chunk Events** (multiple):
   ```json
   {"chunk": "text fragment "}
   ```

3. **Done Event** (last):
   ```json
   {"answer": "complete answer text", "done": true}
   ```

4. **Error Event** (if failed):
   ```json
   {"error": "error message"}
   ```

### Usage Examples

#### JavaScript (Browser)
```javascript
const response = await fetch('/api/v1/stream', {
    method: 'POST',
    headers: {'Content-Type': 'application/json'},
    body: JSON.stringify({
        query: "What are transformers?",
        top_k: 3
    })
});

const reader = response.body.getReader();
const decoder = new TextDecoder();

while (true) {
    const {done, value} = await reader.read();
    if (done) break;

    const text = decoder.decode(value);
    const lines = text.split('\\n');

    for (const line of lines) {
        if (line.startsWith('data: ')) {
            const data = JSON.parse(line.slice(6));

            if (data.chunk) {
                console.log(data.chunk);  // Display chunk
            }
            if (data.done) {
                console.log('Complete:', data.answer);
            }
        }
    }
}
```

#### Python (httpx)
```python
import httpx
import json

async with httpx.AsyncClient() as client:
    async with client.stream(
        "POST",
        "http://localhost:8000/api/v1/stream",
        json={"query": "What are transformers?", "top_k": 3}
    ) as response:
        async for line in response.aiter_lines():
            if line.startswith("data: "):
                data = json.loads(line[6:])
                if "chunk" in data:
                    print(data["chunk"], end="", flush=True)
                if data.get("done"):
                    print(f"\\n\\nComplete: {data['answer']}")
```

### Cache Behavior

- ✅ Exact cache hit: Streams cached response (simulated)
- ❌ Cache miss: Real-time LLM generation

### Performance

- First byte latency: < 500ms
- Chunk frequency: 10-50 chunks/second
- Total time: 2-8 seconds (depends on answer length)
    """,
    operation_id="stream_rag_answer",
    tags=["stream"]
)
async def ask_question_stream(
    request: AskRequest,
    opensearch_client: OpenSearchDep,
    embeddings_service: EmbeddingsDep,
    ollama_client: OllamaDep,
    langfuse_tracer: LangfuseDep,
    cache_client: CacheDep,
) -> StreamingResponse:
    # ... existing implementation ...
    pass
```

---

### 步骤 1.3: 增强所有 Schema 的 Examples

**文件**: `src/schemas/api/ask.py`

**增强后的代码**:
```python
# src/schemas/api/ask.py
from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict

class AskRequest(BaseModel):
    """Request model for RAG question answering."""

    query: str = Field(
        ...,
        description="User's question about academic research papers",
        min_length=1,
        max_length=1000,
        examples=[
            "What are the key differences between transformers and RNNs?",
            "Explain the attention mechanism in BERT",
            "What are the latest developments in quantum computing?",
            "How do vision transformers work?",
            "What is federated learning?"
        ]
    )

    top_k: int = Field(
        3,
        description="Number of top document chunks to retrieve for context",
        ge=1,
        le=10,
        examples=[3, 5, 10]
    )

    use_hybrid: bool = Field(
        True,
        description="Enable hybrid search (BM25 + vector similarity). Falls back to BM25 if embedding fails.",
        examples=[True, False]
    )

    model: str = Field(
        "llama3.2:1b",
        description="Ollama model name for answer generation. Available: llama3.2:1b, llama3.2:3b, qwen2.5:7b",
        examples=["llama3.2:1b", "llama3.2:3b", "qwen2.5:7b"]
    )

    categories: Optional[List[str]] = Field(
        None,
        description="Filter papers by arXiv categories. Leave empty for all categories.",
        examples=[
            ["cs.AI", "cs.LG"],
            ["cs.CV"],
            ["cs.CL", "cs.AI", "cs.LG"]
        ]
    )

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "query": "What are transformers in machine learning?",
                    "top_k": 3,
                    "use_hybrid": True,
                    "model": "llama3.2:1b"
                },
                {
                    "query": "Explain self-attention mechanism in detail",
                    "top_k": 5,
                    "use_hybrid": True,
                    "model": "llama3.2:3b",
                    "categories": ["cs.AI", "cs.LG"]
                },
                {
                    "query": "Latest research on quantum machine learning",
                    "top_k": 10,
                    "use_hybrid": False,
                    "model": "qwen2.5:7b",
                    "categories": ["quant-ph", "cs.LG"]
                }
            ]
        }
    )


class AskResponse(BaseModel):
    """Response model for RAG question answering."""

    query: str = Field(
        ...,
        description="Original user question (echoed back)"
    )

    answer: str = Field(
        ...,
        description="Generated answer from LLM based on retrieved context"
    )

    sources: List[str] = Field(
        ...,
        description="List of source paper PDF URLs cited in the answer"
    )

    chunks_used: int = Field(
        ...,
        description="Number of document chunks used for context",
        ge=0
    )

    search_mode: str = Field(
        ...,
        description="Search mode used: 'bm25' (keyword only) or 'hybrid' (BM25 + vector)"
    )

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "query": "What are transformers in machine learning?",
                    "answer": "Based on the research papers, transformers are neural network architectures that rely entirely on attention mechanisms, eliminating the need for recurrence and convolutions. The key innovation is the self-attention mechanism that allows the model to weigh the importance of different words in the input when processing each word.\n\nKey advantages:\n1. Parallelization during training\n2. Better handling of long-range dependencies\n3. State-of-the-art performance on NLP tasks\n\nSource: Attention is All You Need (Vaswani et al., 2017)",
                    "sources": [
                        "https://arxiv.org/pdf/1706.03762.pdf",
                        "https://arxiv.org/pdf/1810.04805.pdf"
                    ],
                    "chunks_used": 3,
                    "search_mode": "hybrid"
                },
                {
                    "query": "What is quantum computing?",
                    "answer": "I couldn't find any relevant information in the papers to answer your question. The available papers focus on CS and AI topics. Please try a question related to machine learning, NLP, or computer vision.",
                    "sources": [],
                    "chunks_used": 0,
                    "search_mode": "bm25"
                }
            ]
        }
    )


# 类似地增强其他 schemas...
class AgenticAskResponse(AskResponse):
    """Response model for agentic RAG question answering."""

    reasoning_steps: List[str] = Field(
        ...,
        description="Step-by-step reasoning process of the agent",
        examples=[
            [
                "✓ Query validation: Academic research scope confirmed (score: 85/100)",
                "✓ Document retrieval: Retrieved 3 candidate chunks",
                "✓ Relevance grading: All 3 chunks marked as relevant",
                "✓ Answer generation: Generated response from context"
            ],
            [
                "✓ Query validation: Passed (score: 78/100)",
                "✓ Document retrieval (Attempt 1): Retrieved 3 chunks",
                "✗ Relevance grading: 0/3 chunks relevant",
                "⟳ Query rewriting: Optimized query for better retrieval",
                "✓ Document retrieval (Attempt 2): Retrieved 3 chunks",
                "✓ Relevance grading: 2/3 chunks relevant",
                "✓ Answer generation: Generated response from 2 relevant chunks"
            ]
        ]
    )

    retrieval_attempts: int = Field(
        ...,
        description="Number of document retrieval attempts (1-2)",
        ge=1,
        le=2
    )

    trace_id: Optional[str] = Field(
        None,
        description="Langfuse trace ID for feedback submission and debugging"
    )

    model_config = ConfigDict(
        json_schema_extra={
            "examples": [
                {
                    "query": "What are the key innovations in GPT-3?",
                    "answer": "Based on recent research, GPT-3 introduced several key innovations:\n\n1. **Scale**: 175 billion parameters, significantly larger than GPT-2\n2. **Few-shot learning**: Can perform tasks with minimal examples\n3. **In-context learning**: Adapts to tasks via prompts without fine-tuning\n\nThese innovations demonstrate that language models can achieve strong performance through scale and appropriate prompting strategies.\n\nSources: Language Models are Few-Shot Learners (Brown et al., 2020)",
                    "sources": ["https://arxiv.org/pdf/2005.14165.pdf"],
                    "chunks_used": 3,
                    "search_mode": "hybrid",
                    "reasoning_steps": [
                        "✓ Query validation: Academic research scope confirmed (score: 92/100)",
                        "✓ Document retrieval: Retrieved 3 candidate chunks about GPT-3",
                        "✓ Relevance grading: All 3 chunks highly relevant",
                        "✓ Answer generation: Synthesized response from context"
                    ],
                    "retrieval_attempts": 1,
                    "trace_id": "langfuse-trace-abc123-def456-ghi789"
                }
            ]
        }
    )
```

---

### 步骤 1.4: 验证 OpenAPI 规范

**创建验证脚本**: `scripts/validate_openapi.sh`

```bash
#!/bin/bash
# scripts/validate_openapi.sh

set -e

echo "🔍 Validating OpenAPI Specification..."

# 1. Start API if not running
if ! curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "⚠️  API not running, starting docker-compose..."
    docker compose up -d api
    echo "⏳ Waiting for API to be ready..."
    sleep 10
fi

# 2. Download OpenAPI spec
echo "📥 Downloading OpenAPI spec..."
curl -s http://localhost:8000/openapi.json > openapi.json

# 3. Validate with Scalar CLI
echo "✅ Validating with Scalar CLI..."
npx @scalar/cli validate openapi.json --strict

# 4. Check required fields
echo "🔎 Checking required fields..."

# Check all endpoints have operation_id
MISSING_OP_ID=$(jq '.paths | to_entries[] | select(.value | to_entries[] | select(.value.operationId == null)) | .key' openapi.json)
if [ -n "$MISSING_OP_ID" ]; then
    echo "❌ Missing operation_id in endpoints: $MISSING_OP_ID"
    exit 1
fi

# Check all endpoints have examples
MISSING_EXAMPLES=$(jq '[.paths[][] | select(.requestBody.content."application/json".schema.examples == null and .requestBody.content."application/json".examples == null)] | length' openapi.json)
if [ "$MISSING_EXAMPLES" -gt 0 ]; then
    echo "⚠️  Warning: $MISSING_EXAMPLES endpoints missing examples"
fi

# Check all responses have descriptions
MISSING_DESC=$(jq '[.paths[][] | .responses[] | select(.description == null or .description == "")] | length' openapi.json)
if [ "$MISSING_DESC" -gt 0 ]; then
    echo "⚠️  Warning: $MISSING_DESC responses missing descriptions"
fi

echo "✅ OpenAPI specification is valid!"

# 5. Generate summary
echo ""
echo "📊 OpenAPI Summary:"
echo "  Total endpoints: $(jq '.paths | length' openapi.json)"
echo "  Total schemas: $(jq '.components.schemas | length' openapi.json)"
echo "  OpenAPI version: $(jq -r '.openapi' openapi.json)"

# 6. Save validated spec
cp openapi.json openapi.validated.json
echo "💾 Saved validated spec to openapi.validated.json"
```

**运行验证**:
```bash
chmod +x scripts/validate_openapi.sh
./scripts/validate_openapi.sh
```

---

## 🐳 Day 3-4: Scalar 服务集成

### 步骤 3.1: 更新 Docker Compose

**文件**: `compose.yml`

**在现有服务后添加 Scalar**:
```yaml
# compose.yml (添加到文件末尾)

  # ===================================================================
  # Scalar API Documentation UI
  # ===================================================================
  scalar:
    image: scalar/scalar-api-reference:latest
    container_name: arxiv-scalar-ui
    ports:
      - "7998:8080"
    environment:
      # OpenAPI Spec URL (从 FastAPI 动态获取)
      - SPEC_URL=http://api:8000/openapi.json

      # Scalar UI 配置
      - SCALAR_THEME=purple              # purple, blue, green, default
      - SCALAR_LAYOUT=modern              # modern, classic
      - SCALAR_SHOW_SIDEBAR=true
      - SCALAR_HIDE_MODELS=false          # 显示 Schema 模型
      - SCALAR_HIDE_DOWNLOAD_BUTTON=false
      - SCALAR_HIDE_TEST_REQUEST_BUTTON=false

      # 代理配置（允许直接从 Scalar UI 调用 API）
      - SCALAR_PROXY_ENABLED=true
      - SCALAR_PROXY_URL=http://api:8000

      # 自定义配置
      - SCALAR_DEFAULT_OPEN_ALL_TAGS=false
      - SCALAR_SHOW_OPERATIONS_ORDER=path  # path 或 method

    depends_on:
      api:
        condition: service_healthy
    networks:
      - rag-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    labels:
      - "com.arxiv-curator.description=Scalar API Documentation UI"
      - "com.arxiv-curator.service=scalar"

networks:
  rag-network:
    # ... existing network config ...
```

**更新 API 健康检查**（如果没有）:
```yaml
# compose.yml - 修改 api 服务
  api:
    # ... existing config ...
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/api/v1/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

---

### 步骤 3.2: 创建 Scalar 配置文件

**文件**: `.scalar/config.yml`

```yaml
# .scalar/config.yml
# Scalar API Reference 自定义配置

# UI 主题
theme: purple  # purple, blue, green, default

# 布局
layout: modern  # modern, classic

# 侧边栏
sidebar:
  enabled: true
  defaultOpen: true
  showOperations: true

# 顶部导航
navbar:
  logo:
    url: /static/logo.png
    alt: arXiv Paper Curator
  title: arXiv Paper Curator API
  links:
    - text: GitHub
      url: https://github.com/jamwithai/arxiv-paper-curator
    - text: Blog
      url: https://jamwithai.substack.com
    - text: Gradio UI
      url: http://localhost:7861

# 代码示例
codeExamples:
  languages:
    - shell  # cURL
    - python
    - javascript
    - go
    - php
  defaultLanguage: shell

# 搜索
search:
  enabled: true
  hotkey: "/"

# 操作排序
operations:
  sortBy: path  # path, method, alpha

# 模型显示
models:
  show: true
  defaultExpanded: false

# Try It Out 功能
tryItOut:
  enabled: true
  proxy: http://api:8000
  corsProxy: false

# 自定义CSS（可选）
customCss: |
  /* 自定义样式 */
  .scalar-api-reference {
    --scalar-color-1: #8b5cf6;  /* 紫色主题 */
  }

# 自定义JavaScript（可选）
customJs: |
  // 自定义行为
  console.log('Scalar API Reference loaded');

# 认证（未来使用）
authentication:
  type: apiKey
  in: header
  name: X-API-Key
  placeholder: sk-xxxxxxxxxxxxxxxx

# 服务器选择
servers:
  - url: http://localhost:8000
    description: Development (Local)
  - url: http://api:8000
    description: Development (Docker)
```

---

### 步骤 3.3: 启动 Scalar 服务

**脚本**: `scripts/start_scalar.sh`

```bash
#!/bin/bash
# scripts/start_scalar.sh

set -e

echo "🚀 Starting Scalar API Documentation..."

# 1. 确保 API 服务运行
echo "📡 Checking API service..."
if docker compose ps api | grep -q "Up"; then
    echo "✅ API service is running"
else
    echo "🔄 Starting API service..."
    docker compose up -d api
    echo "⏳ Waiting for API to be healthy..."
    sleep 15
fi

# 2. 验证 OpenAPI 规范可访问
echo "🔍 Verifying OpenAPI spec..."
if curl -f -s http://localhost:8000/openapi.json > /dev/null; then
    echo "✅ OpenAPI spec is accessible"
else
    echo "❌ Cannot access OpenAPI spec at http://localhost:8000/openapi.json"
    exit 1
fi

# 3. 启动 Scalar 服务
echo "🐳 Starting Scalar UI..."
docker compose up -d scalar

# 4. 等待 Scalar 健康检查
echo "⏳ Waiting for Scalar to be ready..."
for i in {1..30}; do
    if curl -f -s http://localhost:7998 > /dev/null 2>&1; then
        echo "✅ Scalar UI is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ Scalar UI failed to start"
        docker compose logs scalar
        exit 1
    fi
    sleep 1
done

# 5. 检查服务状态
echo ""
echo "📊 Service Status:"
docker compose ps | grep -E "api|scalar"

echo ""
echo "✨ Scalar API Documentation is now available at:"
echo "   🌐 http://localhost:7998"
echo ""
echo "📚 Other Documentation:"
echo "   📖 Swagger UI: http://localhost:8000/docs"
echo "   📘 ReDoc:      http://localhost:8000/redoc"
echo ""
echo "🎯 Quick Test:"
echo "   curl http://localhost:7998"
```

**运行脚本**:
```bash
chmod +x scripts/start_scalar.sh
./scripts/start_scalar.sh
```

---

### 步骤 3.4: 验证 Scalar 集成

**测试清单**: `scripts/test_scalar.sh`

```bash
#!/bin/bash
# scripts/test_scalar.sh

echo "🧪 Testing Scalar Integration..."

# Test 1: Scalar UI 可访问
echo "Test 1: Scalar UI accessibility..."
if curl -f -s http://localhost:7998 > /dev/null; then
    echo "✅ PASS: Scalar UI is accessible"
else
    echo "❌ FAIL: Scalar UI is not accessible"
    exit 1
fi

# Test 2: OpenAPI spec 可访问
echo "Test 2: OpenAPI spec accessibility..."
if curl -f -s http://localhost:8000/openapi.json > /dev/null; then
    echo "✅ PASS: OpenAPI spec is accessible"
else
    echo "❌ FAIL: OpenAPI spec is not accessible"
    exit 1
fi

# Test 3: Scalar 可以获取 spec
echo "Test 3: Scalar fetches OpenAPI spec..."
SPEC_URL=$(docker compose exec -T scalar env | grep SPEC_URL)
if [ -n "$SPEC_URL" ]; then
    echo "✅ PASS: SPEC_URL is configured: $SPEC_URL"
else
    echo "❌ FAIL: SPEC_URL is not configured"
    exit 1
fi

# Test 4: 所有端点在 Scalar 中可见
echo "Test 4: All endpoints visible in Scalar..."
ENDPOINTS_COUNT=$(curl -s http://localhost:8000/openapi.json | jq '.paths | length')
if [ "$ENDPOINTS_COUNT" -eq 6 ]; then
    echo "✅ PASS: All 6 endpoints are defined"
else
    echo "⚠️  WARNING: Expected 6 endpoints, found $ENDPOINTS_COUNT"
fi

# Test 5: Scalar 代理功能（可选）
echo "Test 5: Testing Scalar proxy (if enabled)..."
if curl -f -s -X POST http://localhost:7998/proxy/api/v1/health > /dev/null 2>&1; then
    echo "✅ PASS: Scalar proxy is working"
else
    echo "⚠️  INFO: Scalar proxy not enabled or not working (OK if disabled)"
fi

echo ""
echo "✅ All critical tests passed!"
echo "🌐 Open http://localhost:7998 to view Scalar UI"
```

---

## 📚 Day 5-6: 文档质量提升

### 步骤 5.1: 添加代码示例到端点

**文件**: `src/routers/hybrid_search.py`

**增强端点文档**:
```python
# src/routers/hybrid_search.py

@router.post(
    "/",
    response_model=SearchResponse,
    operation_id="hybrid_search_papers",
    summary="Search papers with hybrid retrieval",
    description="""
## 🔍 Hybrid Search

Search academic papers using **BM25 (keyword)** + **Vector Similarity** with Reciprocal Rank Fusion.

### How It Works

1. **BM25 Search**: Traditional keyword matching on paper text
2. **Vector Search**: Semantic similarity using Jina embeddings (1024-dim)
3. **RRF Fusion**: Combines both results using Reciprocal Rank Fusion algorithm

### Search Modes

- `use_hybrid=true`: BM25 + Vector (recommended for best results)
- `use_hybrid=false`: BM25 only (faster, good for exact keyword matching)

### Filtering

- **Categories**: Filter by arXiv categories (e.g., `["cs.AI", "cs.LG"]`)
- **Latest Papers**: Sort by publication date instead of relevance
- **Min Score**: Set minimum relevance threshold

### Examples

#### Basic Search
```json
{
  "query": "transformer attention mechanism",
  "size": 10,
  "use_hybrid": true
}
```

#### Advanced Filtering
```json
{
  "query": "few-shot learning",
  "size": 20,
  "categories": ["cs.AI", "cs.LG"],
  "latest_papers": true,
  "min_score": 0.5
}
```

### Response Structure

Each hit contains:
- Paper metadata (title, authors, abstract)
- Matched chunk text (with highlights)
- Relevance score
- Section name
- PDF URL

### Performance

- Average latency: 200-500ms
- Supports pagination (use `from` parameter)
- Cached at OpenSearch level

### Use Cases

✅ Literature review preparation
✅ Finding similar papers
✅ Topic exploration
✅ Citation discovery
    """,
    responses={
        200: {
            "description": "Successful search with results",
            "content": {
                "application/json": {
                    "examples": {
                        "hybrid_search": {
                            "summary": "Hybrid Search Results",
                            "value": {
                                "query": "transformer attention mechanism",
                                "total": 45,
                                "hits": [
                                    {
                                        "arxiv_id": "1706.03762",
                                        "title": "Attention is All You Need",
                                        "authors": "Ashish Vaswani, Noam Shazeer, Niki Parmar, Jakob Uszkoreit, Llion Jones, Aidan N. Gomez, Lukasz Kaiser, Illia Polosukhin",
                                        "abstract": "The dominant sequence transduction models...",
                                        "published_date": "2017-06-12",
                                        "pdf_url": "https://arxiv.org/pdf/1706.03762.pdf",
                                        "score": 15.234,
                                        "chunk_text": "The Transformer uses multi-head self-attention to allow the model to jointly attend to information from different representation subspaces.",
                                        "chunk_id": "1706.03762_chunk_42",
                                        "section_name": "3.2 Multi-Head Attention",
                                        "highlights": {
                                            "chunk_text": ["The <em>Transformer</em> uses multi-head self-<em>attention</em>"]
                                        }
                                    }
                                ],
                                "size": 10,
                                "from": 0,
                                "search_mode": "hybrid"
                            }
                        },
                        "no_results": {
                            "summary": "No Results Found",
                            "value": {
                                "query": "quantum entanglement in cooking",
                                "total": 0,
                                "hits": [],
                                "size": 10,
                                "from": 0,
                                "search_mode": "bm25"
                            }
                        }
                    }
                }
            }
        },
        503: {
            "description": "Search service unavailable",
            "content": {
                "application/json": {
                    "example": {
                        "detail": "Search service is currently unavailable"
                    }
                }
            }
        }
    },
    tags=["hybrid-search"]
)
async def hybrid_search(...):
    # ... implementation ...
```

---

### 步骤 5.2: 创建快速开始指南

**文件**: `docs/QUICKSTART.md`

```markdown
# 🚀 Quick Start Guide

Get started with the arXiv Paper Curator API in 5 minutes.

## Prerequisites

- Docker Desktop running
- API services started: `docker compose up -d`
- Scalar UI available at http://localhost:7998

## Step 1: Health Check

Verify all services are running:

\`\`\`bash
curl http://localhost:8000/api/v1/health | jq
\`\`\`

Expected response:
\`\`\`json
{
  "status": "ok",
  "services": {
    "database": {"status": "healthy"},
    "opensearch": {"status": "healthy"},
    "ollama": {"status": "healthy"}
  }
}
\`\`\`

## Step 2: Search Papers

Find papers about transformers:

\`\`\`bash
curl -X POST http://localhost:8000/api/v1/hybrid-search/ \\
  -H "Content-Type: application/json" \\
  -d '{
    "query": "transformer architecture",
    "size": 5,
    "use_hybrid": true
  }' | jq '.hits[0].title'
\`\`\`

## Step 3: Ask a Question (Basic RAG)

Get a quick answer:

\`\`\`bash
curl -X POST http://localhost:8000/api/v1/ask \\
  -H "Content-Type: application/json" \\
  -d '{
    "query": "What are transformers?",
    "top_k": 3,
    "use_hybrid": true
  }' | jq '.answer'
\`\`\`

## Step 4: Streaming Response

Real-time answer generation:

\`\`\`bash
curl -N -X POST http://localhost:8000/api/v1/stream \\
  -H "Content-Type: application/json" \\
  -d '{
    "query": "Explain attention mechanism",
    "top_k": 3
  }'
\`\`\`

## Step 5: Agentic RAG (Advanced)

Intelligent retrieval with reasoning:

\`\`\`bash
curl -X POST http://localhost:8000/api/v1/ask-agentic \\
  -H "Content-Type: application/json" \\
  -d '{
    "query": "Latest developments in vision transformers",
    "top_k": 5,
    "use_hybrid": true
  }' | jq '{answer, reasoning_steps, trace_id}'
\`\`\`

## Step 6: Submit Feedback

Rate the answer quality:

\`\`\`bash
# Get trace_id from Step 5 response
curl -X POST http://localhost:8000/api/v1/feedback \\
  -H "Content-Type: application/json" \\
  -d '{
    "trace_id": "YOUR_TRACE_ID_HERE",
    "score": 1.0,
    "comment": "Excellent answer!"
  }'
\`\`\`

## Next Steps

- 📖 Explore Scalar UI: http://localhost:7998
- 🎨 Try Gradio interface: http://localhost:7861
- 📊 View Langfuse traces: http://localhost:3000
- 📚 Read full API docs: [API_DOCUMENTATION.md](../API_DOCUMENTATION.md)

## Python Client Example

\`\`\`python
import httpx
import asyncio

async def main():
    async with httpx.AsyncClient() as client:
        # Ask a question
        response = await client.post(
            "http://localhost:8000/api/v1/ask-agentic",
            json={
                "query": "What is self-attention?",
                "top_k": 3
            }
        )
        result = response.json()

        print(f"Answer: {result['answer']}")
        print(f"\\nReasoning:")
        for step in result['reasoning_steps']:
            print(f"  - {step}")

asyncio.run(main())
\`\`\`

## Troubleshooting

### API not responding
\`\`\`bash
docker compose ps
docker compose logs api
\`\`\`

### OpenSearch connection failed
\`\`\`bash
curl http://localhost:9200/_cluster/health
\`\`\`

### Ollama model not loaded
\`\`\`bash
docker compose exec ollama ollama list
\`\`\`

## Support

- GitHub Issues: https://github.com/jamwithai/arxiv-paper-curator/issues
- Blog: https://jamwithai.substack.com
\`\`\`

---

### 步骤 5.3: 添加错误响应文档

**通用错误处理器**: `src/main.py`

```python
# src/main.py (添加到 app 创建后)

from fastapi import Request, status
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from pydantic import BaseModel

class ErrorResponse(BaseModel):
    """Standard error response model"""
    error: str = Field(..., description="Error type")
    message: str = Field(..., description="Human-readable error message")
    detail: Optional[dict] = Field(None, description="Additional error details")
    trace_id: Optional[str] = Field(None, description="Trace ID for debugging")

# 422 Validation Error Handler
@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Handle Pydantic validation errors"""
    return JSONResponse(
        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
        content={
            "error": "ValidationError",
            "message": "Request validation failed",
            "detail": exc.errors(),
            "body": exc.body
        }
    )

# 500 Internal Server Error Handler
@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle unexpected errors"""
    logger.error(f"Unexpected error: {exc}", exc_info=True)
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content={
            "error": "InternalServerError",
            "message": "An unexpected error occurred",
            "detail": str(exc) if app.state.settings.debug else "Contact support"
        }
    )
```

**更新端点错误响应**:
```python
# src/routers/agentic_ask.py

@router.post(
    "/ask-agentic",
    response_model=AgenticAskResponse,
    responses={
        200: {"description": "Successful response with answer"},
        422: {
            "description": "Validation error or out-of-scope query",
            "model": ErrorResponse,
            "content": {
                "application/json": {
                    "examples": {
                        "out_of_scope": {
                            "summary": "Out of Scope Query",
                            "value": {
                                "error": "ValidationError",
                                "message": "Query is outside research paper scope",
                                "detail": {
                                    "guardrail_score": 35,
                                    "threshold": 60,
                                    "reason": "Query appears to be about weather, not academic research"
                                }
                            }
                        },
                        "invalid_request": {
                            "summary": "Invalid Request Parameters",
                            "value": {
                                "error": "ValidationError",
                                "message": "Request validation failed",
                                "detail": [
                                    {
                                        "loc": ["body", "top_k"],
                                        "msg": "ensure this value is less than or equal to 10",
                                        "type": "value_error.number.not_le"
                                    }
                                ]
                            }
                        }
                    }
                }
            }
        },
        500: {
            "description": "Internal server error",
            "model": ErrorResponse,
            "content": {
                "application/json": {
                    "example": {
                        "error": "InternalServerError",
                        "message": "LLM service unavailable",
                        "detail": {
                            "service": "ollama",
                            "status": "connection_timeout"
                        }
                    }
                }
            }
        },
        503: {
            "description": "Service unavailable",
            "model": ErrorResponse,
            "content": {
                "application/json": {
                    "example": {
                        "error": "ServiceUnavailable",
                        "message": "OpenSearch cluster is down",
                        "detail": "Retry after 30 seconds"
                    }
                }
            }
        }
    }
)
async def ask_agentic(...):
    ...
```

---

## 🧪 Day 7-8: 测试和优化

### 测试套件

**创建完整测试**: `tests/test_scalar_integration.py`

```python
# tests/test_scalar_integration.py
import pytest
import httpx
import json
from typing import AsyncGenerator

@pytest.fixture
async def api_client() -> AsyncGenerator[httpx.AsyncClient, None]:
    """Async HTTP client for API testing"""
    async with httpx.AsyncClient(base_url="http://localhost:8000") as client:
        yield client

@pytest.fixture
async def scalar_client() -> AsyncGenerator[httpx.AsyncClient, None]:
    """Async HTTP client for Scalar UI testing"""
    async with httpx.AsyncClient(base_url="http://localhost:7998") as client:
        yield client


class TestScalarUI:
    """Test Scalar UI accessibility and configuration"""

    async def test_scalar_ui_accessible(self, scalar_client):
        """Scalar UI should be accessible"""
        response = await scalar_client.get("/")
        assert response.status_code == 200
        assert "scalar" in response.text.lower()

    async def test_scalar_loads_openapi_spec(self, scalar_client):
        """Scalar should load OpenAPI spec from FastAPI"""
        # This tests that Scalar can fetch the spec
        response = await scalar_client.get("/")
        html = response.text
        assert "openapi.json" in html or "specification" in html.lower()


class TestOpenAPISpec:
    """Test OpenAPI specification quality"""

    async def test_openapi_spec_valid(self, api_client):
        """OpenAPI spec should be valid JSON"""
        response = await api_client.get("/openapi.json")
        assert response.status_code == 200
        spec = response.json()
        assert "openapi" in spec
        assert spec["openapi"].startswith("3.")

    async def test_all_endpoints_documented(self, api_client):
        """All 6 endpoints should be in OpenAPI spec"""
        response = await api_client.get("/openapi.json")
        spec = response.json()
        paths = spec["paths"]

        # Expected endpoints
        assert "/api/v1/health" in paths
        assert "/api/v1/hybrid-search/" in paths
        assert "/api/v1/ask" in paths
        assert "/api/v1/stream" in paths
        assert "/api/v1/ask-agentic" in paths
        assert "/api/v1/feedback" in paths

    async def test_all_endpoints_have_examples(self, api_client):
        """All POST endpoints should have request examples"""
        response = await api_client.get("/openapi.json")
        spec = response.json()

        for path, methods in spec["paths"].items():
            for method, details in methods.items():
                if method == "post":
                    # Check for examples in request body
                    if "requestBody" in details:
                        content = details["requestBody"]["content"]["application/json"]
                        assert "examples" in content or "example" in content.get("schema", {}), \
                            f"Missing examples in {method.upper()} {path}"

    async def test_all_endpoints_have_operation_ids(self, api_client):
        """All endpoints should have unique operation IDs"""
        response = await api_client.get("/openapi.json")
        spec = response.json()

        operation_ids = set()
        for path, methods in spec["paths"].items():
            for method, details in methods.items():
                assert "operationId" in details, \
                    f"Missing operationId in {method.upper()} {path}"

                op_id = details["operationId"]
                assert op_id not in operation_ids, \
                    f"Duplicate operationId: {op_id}"
                operation_ids.add(op_id)


class TestAPIThroughScalar:
    """Test API calls through Scalar proxy (if enabled)"""

    async def test_health_check(self, api_client):
        """Health check should work"""
        response = await api_client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] in ["ok", "degraded"]

    async def test_hybrid_search_example(self, api_client):
        """Hybrid search example should work"""
        response = await api_client.post(
            "/api/v1/hybrid-search/",
            json={
                "query": "transformer",
                "size": 5,
                "use_hybrid": True
            }
        )
        assert response.status_code == 200
        data = response.json()
        assert "hits" in data
        assert data["query"] == "transformer"

    async def test_ask_example(self, api_client):
        """Basic RAG example should work"""
        response = await api_client.post(
            "/api/v1/ask",
            json={
                "query": "What is attention?",
                "top_k": 1,
                "use_hybrid": False
            },
            timeout=30.0
        )
        assert response.status_code == 200
        data = response.json()
        assert "answer" in data
        assert "sources" in data

    @pytest.mark.asyncio
    async def test_stream_example(self, api_client):
        """Streaming RAG should work"""
        async with api_client.stream(
            "POST",
            "/api/v1/stream",
            json={"query": "test", "top_k": 1},
            timeout=30.0
        ) as response:
            assert response.status_code == 200
            assert response.headers["content-type"] == "text/plain; charset=utf-8"

            chunks_received = 0
            async for line in response.aiter_lines():
                if line.startswith("data: "):
                    chunks_received += 1
                    data = json.loads(line[6:])
                    assert isinstance(data, dict)

            assert chunks_received > 0, "No SSE events received"


class TestErrorResponses:
    """Test error handling and responses"""

    async def test_invalid_query_length(self, api_client):
        """Too short query should return 422"""
        response = await api_client.post(
            "/api/v1/ask",
            json={"query": "", "top_k": 3}
        )
        assert response.status_code == 422

    async def test_invalid_top_k(self, api_client):
        """Invalid top_k should return 422"""
        response = await api_client.post(
            "/api/v1/ask",
            json={"query": "test", "top_k": 100}  # max is 10
        )
        assert response.status_code == 422

    async def test_feedback_without_langfuse(self, api_client):
        """Feedback without trace_id should return error"""
        response = await api_client.post(
            "/api/v1/feedback",
            json={
                "trace_id": "invalid-trace",
                "score": 1.0
            }
        )
        # Should either work or return 503 if Langfuse disabled
        assert response.status_code in [200, 503, 500]


# Performance Tests
class TestPerformance:
    """Performance benchmarks"""

    async def test_health_check_latency(self, api_client):
        """Health check should be fast"""
        import time
        start = time.time()
        response = await api_client.get("/api/v1/health")
        latency = time.time() - start

        assert response.status_code == 200
        assert latency < 1.0, f"Health check too slow: {latency:.2f}s"

    async def test_openapi_spec_latency(self, api_client):
        """OpenAPI spec generation should be fast"""
        import time
        start = time.time()
        response = await api_client.get("/openapi.json")
        latency = time.time() - start

        assert response.status_code == 200
        assert latency < 0.5, f"OpenAPI spec too slow: {latency:.2f}s"
```

**运行测试**:
```bash
# 运行所有 Scalar 集成测试
uv run pytest tests/test_scalar_integration.py -v

# 运行特定测试类
uv run pytest tests/test_scalar_integration.py::TestOpenAPISpec -v

# 生成测试报告
uv run pytest tests/test_scalar_integration.py --html=report.html
```

---

## 📖 Day 9-10: 部署和文档

### 更新 README

**添加 Scalar 部分到 README.md**:

```markdown
## 📚 API Documentation

We provide **three ways** to explore our API:

### 1. 🎨 Scalar API Reference (Recommended)

Modern, interactive API documentation with beautiful UI.

- **URL**: http://localhost:7998
- **Features**:
  - 🎯 Try It Out with live API calls
  - 📝 Code generation (Python, JavaScript, cURL)
  - 🔍 Powerful search
  - 📱 Mobile-friendly
  - 🎨 Purple theme optimized for readability

### 2. 📖 Swagger UI (FastAPI Default)

Classic OpenAPI documentation.

- **URL**: http://localhost:8000/docs
- **Features**: Interactive API testing, schema viewer

### 3. 📘 ReDoc

Clean, three-panel API documentation.

- **URL**: http://localhost:8000/redoc
- **Features**: Search, deep linking, print-friendly

---

## 🚀 Quick Start with Scalar

1. **Start all services**:
   ```bash
   docker compose up -d
   ```

2. **Open Scalar UI**:
   ```
   http://localhost:7998
   ```

3. **Try your first API call**:
   - Navigate to `/api/v1/health`
   - Click "Try It Out"
   - Click "Send Request"
   - See the live response!

---

## 📊 Service URLs

| Service | URL | Description |
|---------|-----|-------------|
| **Scalar UI** | http://localhost:7998 | Modern API docs ⭐ |
| **API** | http://localhost:8000 | FastAPI application |
| **Swagger UI** | http://localhost:8000/docs | Interactive API docs |
| **ReDoc** | http://localhost:8000/redoc | Clean API docs |
| **Gradio** | http://localhost:7861 | Chat interface |
| **Langfuse** | http://localhost:3000 | Tracing dashboard |
| **OpenSearch** | http://localhost:5601 | Search admin |
| **Airflow** | http://localhost:8080 | Workflow management |
```

---

### 创建用户指南

**文件**: `docs/SCALAR_USER_GUIDE.md`

```markdown
# Scalar UI User Guide

## 🎯 Overview

Scalar provides a beautiful, modern interface for exploring the arXiv Paper Curator API.

## 📍 Navigation

### Sidebar

The left sidebar shows all API endpoints grouped by tags:

- **Health**: System monitoring
- **hybrid-search**: Document search
- **ask**: Basic RAG
- **stream**: Streaming RAG
- **agentic-rag**: Intelligent RAG

### Top Bar

- **Search** (press `/`): Find endpoints, schemas, or text
- **Server**: Select API server (development/production)
- **Theme**: Purple (default), Blue, Green

## 🚀 Making API Calls

### Step 1: Select an Endpoint

Click on any endpoint in the sidebar (e.g., `POST /api/v1/ask`)

### Step 2: View Request Schema

Scroll to "Request Body" section to see:
- Required parameters
- Parameter types
- Descriptions
- Examples

### Step 3: Try It Out

1. Click "Try It Out" button
2. Modify the request JSON (or use provided example)
3. Click "Send Request"
4. View the response below

### Example: Ask a Question

```json
{
  "query": "What are transformers?",
  "top_k": 3,
  "use_hybrid": true,
  "model": "llama3.2:1b"
}
```

## 📝 Code Generation

### Generate Client Code

1. Make a successful API call
2. Click "Code" tab above the request
3. Select language:
   - Shell (cURL)
   - Python
   - JavaScript
   - Go
   - PHP

### Example Generated Code

**Python**:
```python
import httpx

response = httpx.post(
    "http://localhost:8000/api/v1/ask",
    json={
        "query": "What are transformers?",
        "top_k": 3
    }
)
print(response.json())
```

## 🔍 Advanced Features

### Search

Press `/` or click search box:
- Search endpoint names: "health", "search", "ask"
- Search by tag: "agentic-rag"
- Search in descriptions: "streaming"

### Schemas

View data models:
1. Scroll to "Schemas" section (bottom of sidebar)
2. Click on any schema (e.g., `AskRequest`)
3. See all fields with types and descriptions

### Request History

Scalar remembers your recent requests in browser localStorage.

## 🎨 Customization

### Change Theme

Click theme selector (top right):
- Purple (default)
- Blue
- Green
- Default

### Change Server

Click server dropdown (top):
- Development (http://localhost:8000)
- Docker Internal (http://api:8000)

## 💡 Tips & Tricks

### 1. Use Examples

Every endpoint has pre-filled examples. Click "Use Example" to autofill.

### 2. Keyboard Shortcuts

- `/` - Open search
- `Esc` - Close modals
- `Ctrl/Cmd + K` - Command palette

### 3. Copy Response

Click "Copy" icon in response section to copy JSON.

### 4. Authentication (Future)

When API authentication is enabled:
1. Click "Auth" button (top right)
2. Enter your API key
3. Key is saved for all requests

## 🐛 Troubleshooting

### Can't Send Requests

**Problem**: "Try It Out" doesn't work

**Solutions**:
1. Check API is running: `curl http://localhost:8000/health`
2. Check CORS settings
3. Try direct API call with cURL to isolate issue

### No Endpoints Visible

**Problem**: Sidebar is empty

**Solutions**:
1. Check OpenAPI spec loads: `curl http://localhost:8000/openapi.json`
2. Refresh browser (Ctrl+F5)
3. Clear browser cache
4. Check Scalar container logs: `docker compose logs scalar`

### Slow Response Times

**Problem**: API calls take too long

**Solutions**:
1. Use smaller `top_k` (e.g., 3 instead of 10)
2. Disable hybrid search for faster results
3. Check service health: GET `/api/v1/health`

## 📞 Support

- GitHub Issues: https://github.com/jamwithai/arxiv-paper-curator/issues
- Documentation: [API_DOCUMENTATION.md](../API_DOCUMENTATION.md)
- Blog: https://jamwithai.substack.com
```

---

## ✅ 验收清单

**完整验收**: `scripts/acceptance_test.sh`

```bash
#!/bin/bash
# scripts/acceptance_test.sh

echo "🎯 Running Acceptance Tests for Scalar Integration..."

PASS=0
FAIL=0

function test_case() {
    echo ""
    echo "Testing: $1"
    if eval "$2"; then
        echo "✅ PASS"
        ((PASS++))
    else
        echo "❌ FAIL"
        ((FAIL++))
    fi
}

# Test 1: Scalar UI Accessible
test_case "Scalar UI accessible at :7998" \
    "curl -f -s http://localhost:7998 > /dev/null"

# Test 2: OpenAPI Spec Valid
test_case "OpenAPI spec is valid JSON" \
    "curl -s http://localhost:8000/openapi.json | jq . > /dev/null"

# Test 3: All 6 Endpoints Present
test_case "All 6 endpoints documented" \
    "[[ \$(curl -s http://localhost:8000/openapi.json | jq '.paths | length') -eq 6 ]]"

# Test 4: All Endpoints Have Examples
test_case "All POST endpoints have examples" \
    "curl -s http://localhost:8000/openapi.json | jq '[.paths[][] | select(.requestBody) | .requestBody.content.\"application/json\" | select(.examples == null and .schema.examples == null)] | length' | grep -q '^0$'"

# Test 5: All Endpoints Have Operation IDs
test_case "All endpoints have operation IDs" \
    "curl -s http://localhost:8000/openapi.json | jq '[.paths[][] | select(.operationId == null)] | length' | grep -q '^0$'"

# Test 6: SSE Endpoint Defined
test_case "/stream endpoint has SSE documentation" \
    "curl -s http://localhost:8000/openapi.json | jq '.paths[\"/api/v1/stream\"].post.responses.\"200\".content.\"text/event-stream\"' | grep -q 'example'"

# Test 7: Error Responses Documented
test_case "Error responses (422, 500) documented" \
    "curl -s http://localhost:8000/openapi.json | jq '[.paths[][] | select(.responses.\"422\" or .responses.\"500\")] | length' | grep -qv '^0$'"

# Test 8: Tags Defined
test_case "OpenAPI tags defined" \
    "[[ \$(curl -s http://localhost:8000/openapi.json | jq '.tags | length') -ge 5 ]]"

# Test 9: Servers Defined
test_case "Servers section defined" \
    "[[ \$(curl -s http://localhost:8000/openapi.json | jq '.servers | length') -ge 1 ]]"

# Test 10: API Health Check Works
test_case "API health check returns 200" \
    "curl -f -s http://localhost:8000/api/v1/health > /dev/null"

# Summary
echo ""
echo "======================================"
echo "Acceptance Test Results"
echo "======================================"
echo "✅ Passed: $PASS"
echo "❌ Failed: $FAIL"
echo "Total: $((PASS + FAIL))"
echo "======================================"

if [ $FAIL -eq 0 ]; then
    echo "🎉 All acceptance tests passed!"
    exit 0
else
    echo "⚠️  Some acceptance tests failed!"
    exit 1
fi
```

**运行验收测试**:
```bash
chmod +x scripts/acceptance_test.sh
./scripts/acceptance_test.sh
```

---

## 📦 完整文件清单

### 新增文件

```
13 arxiv-paper-curator/
├── scripts/
│   ├── validate_openapi.sh         # OpenAPI 验证脚本
│   ├── start_scalar.sh              # Scalar 启动脚本
│   ├── test_scalar.sh               # Scalar 测试脚本
│   └── acceptance_test.sh           # 验收测试脚本
├── .scalar/
│   └── config.yml                   # Scalar 配置文件
├── tests/
│   └── test_scalar_integration.py   # 集成测试
├── docs/
│   ├── QUICKSTART.md                # 快速开始指南
│   └── SCALAR_USER_GUIDE.md         # 用户指南
└── SCALAR_IMPLEMENTATION_GUIDE.md   # 本文件
```

### 修改文件

```
├── src/
│   ├── main.py                      # 增强 FastAPI 元数据
│   ├── routers/
│   │   ├── ask.py                   # 修复 /stream 定义
│   │   ├── hybrid_search.py         # 增强文档
│   │   └── agentic_ask.py           # 增强文档
│   └── schemas/
│       └── api/
│           ├── ask.py               # 增强 examples
│           └── search.py            # 增强 examples
├── compose.yml                      # 添加 Scalar 服务
└── README.md                        # 添加 Scalar 说明
```

---

## 🎯 成功标准

### 技术指标

- ✅ OpenAPI 验证: 0 errors
- ✅ Scalar UI 访问延迟: < 1s
- ✅ 所有 6 个端点可见
- ✅ SSE 流式文档完整
- ✅ 所有端点有 examples
- ✅ 所有测试通过

### 用户体验

- ✅ 5 分钟内完成首次 API 调用
- ✅ 文档易于搜索
- ✅ 代码生成功能可用
- ✅ 移动端可访问

---

## 📞 支持

如有问题，请：
1. 查看 [SCALAR_MIGRATION_PLAN.md](SCALAR_MIGRATION_PLAN.md) 的风险分析
2. 运行诊断脚本: `./scripts/test_scalar.sh`
3. 查看日志: `docker compose logs scalar`
4. 提交 Issue: GitHub Issues

---

**实施愉快！🚀**
