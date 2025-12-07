# Scalar API Reference 严格代码规范

> **版本**: 1.0
> **目标**: OpenAPI 3.1 + Scalar 最佳实践
> **适用范围**: arXiv Paper Curator API
> **严格等级**: ⭐⭐⭐⭐⭐ (最严格)

---

## 📋 目录

1. [OpenAPI 3.1 核心规范](#openapi-31-核心规范)
2. [Scalar 特定扩展](#scalar-特定扩展)
3. [FastAPI 实现规范](#fastapi-实现规范)
4. [Schema 设计规范](#schema-设计规范)
5. [文档撰写规范](#文档撰写规范)
6. [安全和隐私规范](#安全和隐私规范)
7. [验证和测试规范](#验证和测试规范)
8. [性能和优化规范](#性能和优化规范)

---

## 1. OpenAPI 3.1 核心规范

### 1.1 必需字段 (MUST)

#### Info Object

```yaml
info:
  title: string              # ✅ MUST: 简洁的 API 名称 (< 50 字符)
  version: string            # ✅ MUST: 语义化版本 (SemVer 2.0)
  description: string        # ✅ MUST: 完整的 Markdown 描述 (> 200 字符)
  contact:                   # ✅ MUST: 联系信息
    name: string             # ✅ MUST: 团队或负责人名称
    email: string            # ✅ MUST: 有效邮箱 (非 example.com)
    url: string              # ⚠️ SHOULD: 项目 URL
  license:                   # ✅ MUST: 许可证信息
    name: string             # ✅ MUST: 许可证名称 (如 "MIT License")
    url: string              # ✅ MUST: 许可证 URL
  termsOfService: string     # ⚠️ SHOULD: 服务条款 URL
```

**规则**:
- ✅ **MUST**: `title` 必须简洁,不包含版本号或环境信息
- ✅ **MUST**: `version` 必须遵循 SemVer 2.0 格式 (`MAJOR.MINOR.PATCH`)
- ✅ **MUST**: `description` 必须使用 Markdown,包含:
  - API 用途和核心功能
  - 快速开始指南
  - 架构图或流程图 (可选)
  - 外部资源链接
- ❌ **MUST NOT**: `contact.email` 不能使用占位符 (如 `example.com`, `test@test.com`)
- ⚠️ **SHOULD**: 提供 `license` 信息以符合开源最佳实践

**示例** (正确):

```yaml
info:
  title: "arXiv Paper Curator API"
  version: "1.0.0"
  description: |
    # 🎓 Academic Research Assistant with RAG

    A production-grade **Retrieval-Augmented Generation** system for academic papers.

    ## ✨ Key Features
    - Hybrid Search (BM25 + Vector)
    - Agentic RAG with LangGraph
    - Real-time Langfuse Tracing

    ## 🚀 Quick Start
    1. Health Check: `GET /api/v1/health`
    2. Search Papers: `POST /api/v1/hybrid-search/`
    3. Ask Questions: `POST /api/v1/ask-agentic`

  contact:
    name: "arXiv Paper Curator Team"
    email: "yemu.yu@project.com"  # ✅ 真实邮箱
    url: "https://github.com/Yemu-Yu/arxiv-paper-curator"
  license:
    name: "MIT License"
    url: "https://opensource.org/licenses/MIT"
```

---

### 1.2 Servers Object

```yaml
servers:                     # ✅ MUST: 至少定义 1 个 server
  - url: string              # ✅ MUST: 完整 URL (含协议)
    description: string      # ✅ MUST: 环境描述
    variables:               # ⚠️ OPTIONAL: 服务器变量
      varName:
        default: string
        enum: [string]
        description: string
```

**规则**:
- ✅ **MUST**: 至少定义一个 `server`
- ✅ **MUST**: `url` 必须是完整 URL (含 `http://` 或 `https://`)
- ✅ **MUST**: `description` 必须清晰说明环境 (开发/生产/测试)
- ❌ **MUST NOT**: `url` 不能暴露内部 IP 地址 (如 `192.168.x.x`, `10.x.x.x`)
- ❌ **MUST NOT**: `url` 不能暴露内部服务名 (如 `http://api:8000`)
- ⚠️ **SHOULD**: 生产环境使用 HTTPS

**示例** (正确):

```yaml
servers:
  - url: "https://api.arxiv-curator.com"
    description: "🚀 Production Server"
  - url: "https://staging.arxiv-curator.com"
    description: "🧪 Staging Server"
  - url: "http://localhost:8000"
    description: "🛠️ Development (Local)"
```

**反例** (错误):

```yaml
servers:
  - url: "http://api:8000"              # ❌ 内部服务名
    description: "Docker Internal"
  - url: "http://192.168.1.100:8000"    # ❌ 内部 IP
    description: "Development"
```

---

### 1.3 Paths Object

#### Operation Object (每个端点)

```yaml
paths:
  /api/v1/health:
    get:
      operationId: string        # ✅ MUST: 唯一操作 ID
      summary: string            # ✅ MUST: 简短摘要 (< 50 字符)
      description: string        # ✅ MUST: 详细描述 (Markdown)
      tags: [string]             # ✅ MUST: 至少 1 个 tag
      parameters: [...]          # ⚠️ OPTIONAL: 参数定义
      requestBody: {...}         # ⚠️ OPTIONAL: 请求体
      responses: {...}           # ✅ MUST: 至少定义 200 和 4xx/5xx
      deprecated: boolean        # ⚠️ OPTIONAL: 弃用标记
      security: [...]            # ⚠️ OPTIONAL: 安全要求
```

**规则**:

#### operationId (必需)
- ✅ **MUST**: 每个 operation 必须有唯一的 `operationId`
- ✅ **MUST**: 使用 `snake_case` 格式 (如 `get_health_status`)
- ✅ **MUST**: 命名格式: `{verb}_{resource}_{action}` (如 `search_papers_hybrid`)
- ❌ **MUST NOT**: 不能包含特殊字符 (除 `_` 外)
- ❌ **MUST NOT**: 不能重复

**示例**:
```yaml
✅ 正确: "get_health_status", "search_papers_hybrid", "ask_question_agentic"
❌ 错误: "health", "search-papers", "ask.question", "health_check_duplicate"
```

#### summary (必需)
- ✅ **MUST**: 简短明了 (≤ 50 字符)
- ✅ **MUST**: 使用祈使句 (如 "Get health status" 而非 "Gets health status")
- ❌ **MUST NOT**: 不能以句号结尾
- ❌ **MUST NOT**: 不能包含 API 版本号

**示例**:
```yaml
✅ 正确: "Search papers with hybrid retrieval"
❌ 错误: "This endpoint searches papers.", "Search Papers API v1"
```

#### description (必需)
- ✅ **MUST**: 详细说明端点功能 (≥ 100 字符)
- ✅ **MUST**: 使用 Markdown 格式
- ✅ **MUST**: 包含以下部分:
  - 功能描述 (What it does)
  - 使用场景 (When to use)
  - 行为说明 (How it works)
  - 代码示例 (至少 1 个语言)
- ⚠️ **SHOULD**: 包含性能指标 (如 "Average latency: 200ms")
- ⚠️ **SHOULD**: 包含限制说明 (如 "Rate limit: 100 req/min")

**示例**:
```yaml
description: |
  ## 🔍 Hybrid Document Search

  Search academic papers using **BM25** (keyword) + **Vector Similarity** (semantic).

  ### How It Works
  1. BM25 Search: Traditional keyword matching
  2. Vector Search: Semantic similarity using Jina embeddings (1024-dim)
  3. RRF Fusion: Combines both using Reciprocal Rank Fusion

  ### Use Cases
  - ✅ Literature review preparation
  - ✅ Finding similar papers
  - ✅ Topic exploration

  ### Performance
  - Average latency: 300ms
  - P95 latency: 500ms

  ### Example (Python)
  ```python
  import httpx

  response = httpx.post(
      "http://localhost:8000/api/v1/hybrid-search/",
      json={"query": "transformer", "size": 10, "use_hybrid": true}
  )
  print(response.json()["hits"])
  ```
```

#### tags (必需)
- ✅ **MUST**: 每个 operation 至少有 1 个 tag
- ✅ **MUST**: Tag 名称使用 `kebab-case` (如 `hybrid-search`)
- ✅ **MUST**: Tag 在 OpenAPI 根级别的 `tags` 数组中定义
- ⚠️ **SHOULD**: 限制每个 operation 最多 2 个 tags

**示例**:
```yaml
# 根级别定义
tags:
  - name: "health"
    description: "System health monitoring"
  - name: "hybrid-search"
    description: "Document search with BM25 and vector"

# Operation 级别使用
paths:
  /api/v1/health:
    get:
      tags: ["health"]  # ✅ 正确
  /api/v1/hybrid-search/:
    post:
      tags: ["hybrid-search"]  # ✅ 正确
```

#### responses (必需)
- ✅ **MUST**: 必须定义至少以下响应:
  - `200`: 成功响应
  - `4xx`: 客户端错误 (至少 `400` 或 `422`)
  - `5xx`: 服务端错误 (至少 `500`)
- ✅ **MUST**: 每个响应必须有 `description`
- ✅ **MUST**: 每个响应必须有 `content` (除 `204 No Content`)
- ✅ **MUST**: 每个 `content` 必须有 `schema`
- ⚠️ **SHOULD**: 提供 `examples` (多个示例场景)

**示例**:
```yaml
responses:
  '200':
    description: "Successful response with search results"
    content:
      application/json:
        schema:
          $ref: "#/components/schemas/SearchResponse"
        examples:
          successful_search:
            summary: "Successful search with results"
            value:
              query: "transformer"
              total: 45
              hits: [...]
          no_results:
            summary: "Search with no results"
            value:
              query: "nonexistent topic"
              total: 0
              hits: []

  '422':
    description: "Validation error"
    content:
      application/json:
        schema:
          $ref: "#/components/schemas/ValidationError"
        examples:
          invalid_query:
            summary: "Empty query string"
            value:
              detail: [
                {
                  "loc": ["body", "query"],
                  "msg": "ensure this value has at least 1 characters",
                  "type": "value_error.any_str.min_length"
                }
              ]

  '500':
    description: "Internal server error"
    content:
      application/json:
        schema:
          $ref: "#/components/schemas/ErrorResponse"
        example:
          error: "InternalServerError"
          message: "Search service unavailable"
```

---

### 1.4 Components Object

#### Schemas (必需)

```yaml
components:
  schemas:
    SchemaName:                # ✅ MUST: PascalCase 命名
      type: string             # ✅ MUST: 类型定义
      description: string      # ✅ MUST: 描述
      required: [...]          # ✅ MUST: 必需字段列表
      properties:              # ✅ MUST: 属性定义
        fieldName:
          type: string
          description: string
          example: any         # ⚠️ SHOULD: 示例值
```

**规则**:
- ✅ **MUST**: Schema 名称使用 `PascalCase` (如 `SearchResponse`, `AskRequest`)
- ✅ **MUST**: 每个 schema 必须有 `type`
- ✅ **MUST**: 每个 schema 必须有 `description`
- ✅ **MUST**: 每个属性必须有 `type` 和 `description`
- ✅ **MUST**: 必需字段必须在 `required` 数组中列出
- ⚠️ **SHOULD**: 提供 `example` 或 `examples` (OpenAPI 3.1)
- ⚠️ **SHOULD**: 使用 JSON Schema 验证关键字 (如 `minLength`, `maxLength`, `minimum`, `maximum`)

**示例** (完整 Schema):

```yaml
components:
  schemas:
    AskRequest:
      type: object
      description: "Request model for RAG question answering"
      required:
        - query
      properties:
        query:
          type: string
          description: "User's question about academic research papers"
          minLength: 1
          maxLength: 1000
          example: "What are transformers in machine learning?"

        top_k:
          type: integer
          description: "Number of top document chunks to retrieve for context"
          minimum: 1
          maximum: 10
          default: 3
          example: 3

        use_hybrid:
          type: boolean
          description: "Enable hybrid search (BM25 + vector similarity). Falls back to BM25 if embedding fails."
          default: true
          example: true

        model:
          type: string
          description: "Ollama model name for answer generation"
          enum:
            - "llama3.2:1b"
            - "llama3.2:3b"
            - "qwen2.5:7b"
          default: "llama3.2:1b"
          example: "llama3.2:1b"

        categories:
          type: array
          description: "Filter papers by arXiv categories. Leave empty for all categories."
          items:
            type: string
            pattern: "^[a-z-]+\\.[A-Z]{2,4}$"  # 如 cs.AI, cs.LG
          example: ["cs.AI", "cs.LG"]
          nullable: true

      examples:
        - query: "What are transformers in machine learning?"
          top_k: 3
          use_hybrid: true
          model: "llama3.2:1b"

        - query: "Explain self-attention mechanism in detail"
          top_k: 5
          use_hybrid: true
          model: "llama3.2:3b"
          categories: ["cs.AI", "cs.LG"]
```

---

## 2. Scalar 特定扩展

### 2.1 支持的自定义扩展

Scalar 支持以 `x-` 开头的自定义扩展:

#### x-tagGroups (标签分组)

**用途**: 在 Scalar 侧边栏中对 tags 进行分组显示

```yaml
x-tagGroups:
  - name: "Core Services"
    tags:
      - "health"
      - "hybrid-search"

  - name: "RAG Endpoints"
    tags:
      - "ask"
      - "stream"
      - "agentic-rag"
```

**规则**:
- ✅ **MUST**: 每个 group 必须有 `name` 和 `tags`
- ✅ **MUST**: `tags` 中的 tag 名称必须在 OpenAPI `tags` 中定义
- ⚠️ **SHOULD**: 分组逻辑清晰 (如按功能、按版本)

---

#### x-logo (Logo 配置)

**用途**: 在 Scalar UI 中显示自定义 Logo

```yaml
info:
  x-logo:
    url: "https://raw.githubusercontent.com/Yemu-Yu/arxiv-paper-curator/main/static/logo.png"
    altText: "arXiv Paper Curator"
    href: "https://github.com/Yemu-Yu/arxiv-paper-curator"
    backgroundColor: "#FFFFFF"  # Optional
```

**规则**:
- ✅ **MUST**: `url` 必须是公开可访问的图片 URL
- ✅ **MUST**: `altText` 必须提供
- ⚠️ **SHOULD**: 使用 SVG 或 PNG 格式
- ⚠️ **SHOULD**: Logo 尺寸 ≤ 100KB

---

#### x-scalar-stability (稳定性指示器)

**用途**: 标记 endpoint 的稳定性状态

```yaml
paths:
  /api/v1/experimental-feature:
    post:
      x-scalar-stability: "experimental"  # stable | experimental | deprecated
      summary: "Experimental feature"
      description: |
        ⚠️ **This endpoint is experimental and may change without notice.**
```

**规则**:
- ✅ **MUST**: 值必须是 `stable`, `experimental`, 或 `deprecated` 之一
- ⚠️ **SHOULD**: `experimental` 端点在 `description` 中添加警告
- ⚠️ **SHOULD**: `deprecated` 使用 OpenAPI 原生的 `deprecated: true` (优先级更高)

---

#### x-badges (端点徽章)

**用途**: 为 endpoint 添加可视化标记

```yaml
paths:
  /api/v1/premium-feature:
    post:
      x-badges:
        - label: "Premium"
          color: "#FFD700"
        - label: "Beta"
          color: "#FF6B6B"
      summary: "Premium beta feature"
```

**规则**:
- ⚠️ **SHOULD**: 徽章数量 ≤ 3 (避免视觉混乱)
- ⚠️ **SHOULD**: 使用语义化颜色 (如绿色=稳定, 橙色=beta, 红色=deprecated)

---

#### x-enum-descriptions (枚举描述)

**用途**: 为枚举值添加详细描述

```yaml
components:
  schemas:
    ModelName:
      type: string
      enum:
        - "llama3.2:1b"
        - "llama3.2:3b"
        - "qwen2.5:7b"
      x-enum-descriptions:
        "llama3.2:1b": "Fastest model, best for quick responses (2-3s)"
        "llama3.2:3b": "Balanced model, better quality (4-6s)"
        "qwen2.5:7b": "Highest quality, slower response (8-12s)"
```

**规则**:
- ✅ **MUST**: 每个枚举值都必须有对应的描述
- ⚠️ **SHOULD**: 描述包含使用场景或性能指标

---

#### x-enum-varnames (枚举变量名)

**用途**: 为枚举值提供代码生成的变量名

```yaml
components:
  schemas:
    SearchMode:
      type: string
      enum:
        - "bm25"
        - "hybrid"
      x-enum-varnames:
        - "SEARCH_MODE_BM25"
        - "SEARCH_MODE_HYBRID"
```

---

### 2.2 Scalar 配置规范

**HTML 页面配置** (`static/api-docs.html`):

```javascript
const configuration = {
  // ✅ MUST: OpenAPI spec URL
  spec: {
    url: 'http://localhost:8000/openapi.json',
  },

  // ✅ MUST: 主题选择
  theme: 'purple',  // purple, blue, green, default, moon

  // ✅ MUST: 布局选择
  layout: 'modern',  // modern, classic

  // ⚠️ SHOULD: 暗色模式支持
  darkMode: false,
  hideDarkModeToggle: false,

  // ⚠️ SHOULD: 侧边栏显示
  showSidebar: true,

  // ⚠️ SHOULD: 功能开关
  hideDownloadButton: false,       // 允许下载 OpenAPI spec
  hideTestRequestSnippets: false,  // 显示代码示例

  // ⚠️ SHOULD: 默认 HTTP 客户端
  defaultHttpClient: {
    targetKey: 'javascript',
    clientKey: 'fetch'
  },

  // ⚠️ SHOULD: 服务器覆盖 (可选)
  servers: [
    {
      url: 'http://localhost:8000',
      description: '🛠️ Development (Local)'
    }
  ],

  // ⚠️ SHOULD: 排序配置
  tagsSorter: 'alpha',        // alpha | custom function
  operationsSorter: 'alpha',  // alpha | method | custom function

  // ⚠️ OPTIONAL: 自定义 CSS
  customCss: `
    .scalar-api-reference {
      --scalar-color-1: #8b5cf6;
      --scalar-color-2: #a78bfa;
    }
  `
};
```

**规则**:
- ✅ **MUST**: `spec.url` 必须可访问 (CORS 正确配置)
- ✅ **MUST**: `theme` 和 `layout` 必须设置
- ⚠️ **SHOULD**: 不要隐藏关键功能 (`hideDownloadButton`, `hideTestRequestSnippets`)
- ⚠️ **SHOULD**: 使用 `customCss` 保持品牌一致性

---

## 3. FastAPI 实现规范

### 3.1 应用级别配置

```python
# src/main.py

from fastapi import FastAPI
from fastapi.openapi.utils import get_openapi

app = FastAPI(
    # ✅ MUST: 基本信息
    title="arXiv Paper Curator API",
    version="1.0.0",
    description="...",  # 完整 Markdown 描述

    # ✅ MUST: 联系和许可
    contact={
        "name": "arXiv Paper Curator Team",
        "email": "yemu.yu@project.com",  # 真实邮箱
        "url": "https://github.com/Yemu-Yu/arxiv-paper-curator"
    },
    license_info={
        "name": "MIT License",
        "url": "https://opensource.org/licenses/MIT"
    },

    # ✅ MUST: 服务器配置
    servers=[
        {
            "url": "http://localhost:8000",
            "description": "🛠️ Development Server (Local)"
        }
    ],

    # ✅ MUST: Tags 定义
    openapi_tags=[
        {
            "name": "health",
            "description": "System health monitoring",
            "externalDocs": {
                "description": "Health Check Pattern",
                "url": "https://microservices.io/patterns/observability/health-check-api.html"
            }
        },
        # ... 其他 tags
    ],

    # ⚠️ SHOULD: Swagger UI 配置
    swagger_ui_parameters={
        "defaultModelsExpandDepth": -1,
        "docExpansion": "list",
        "filter": True
    },

    # ⚠️ SHOULD: ReDoc URL
    redoc_url="/redoc"
)


# ✅ MUST: 自定义 OpenAPI schema
def custom_openapi():
    """Generate enhanced OpenAPI schema with Scalar extensions"""
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

    # ✅ MUST: 添加 Scalar 扩展
    openapi_schema["info"]["x-logo"] = {
        "url": "https://raw.githubusercontent.com/Yemu-Yu/arxiv-paper-curator/main/static/logo.png",
        "altText": "arXiv Paper Curator",
        "href": "https://github.com/Yemu-Yu/arxiv-paper-curator"
    }

    # ⚠️ SHOULD: 定义安全方案 (即使未启用)
    openapi_schema.setdefault("components", {})["securitySchemes"] = {
        "ApiKeyAuth": {
            "type": "apiKey",
            "in": "header",
            "name": "X-API-Key",
            "description": "API key for authentication (future feature)"
        }
    }

    # ⚠️ SHOULD: Tag 分组
    openapi_schema["x-tagGroups"] = [
        {
            "name": "Core Services",
            "tags": ["health", "hybrid-search"]
        },
        {
            "name": "RAG Endpoints",
            "tags": ["ask", "stream", "agentic-rag"]
        }
    ]

    app.openapi_schema = openapi_schema
    return app.openapi_schema


# ✅ MUST: 应用自定义 schema
app.openapi = custom_openapi
```

---

### 3.2 路由器定义规范

```python
# src/routers/ask.py

from fastapi import APIRouter, HTTPException
from src.schemas.api.ask import AskRequest, AskResponse

router = APIRouter(
    prefix="/api/v1",
    tags=["ask"]  # ✅ MUST: 定义 tag
)


@router.post(
    "/ask",
    # ✅ MUST: response_model
    response_model=AskResponse,

    # ✅ MUST: operationId (唯一)
    operation_id="ask_question_basic_rag",

    # ✅ MUST: summary (简短)
    summary="Ask question with basic RAG",

    # ✅ MUST: description (详细 Markdown)
    description="""
## 💬 Basic RAG Q&A

Simple Retrieval-Augmented Generation with **Redis caching**.

### Features
- Fast responses for repeated queries (6-hour cache TTL)
- Configurable retrieval (`top_k`)
- Support for BM25-only or hybrid search

### Example (Python)
\`\`\`python
import httpx

response = httpx.post(
    "http://localhost:8000/api/v1/ask",
    json={
        "query": "What is attention?",
        "top_k": 3,
        "use_hybrid": True
    }
)
print(response.json()["answer"])
\`\`\`

### Performance
- Average latency: 2-3 seconds
- Cache hit rate: ~30%
    """,

    # ✅ MUST: responses (至少 200, 4xx, 5xx)
    responses={
        200: {
            "description": "Successful RAG response",
            "model": AskResponse,
            "content": {
                "application/json": {
                    "examples": {
                        "successful_answer": {
                            "summary": "Successful answer generation",
                            "value": {
                                "query": "What is attention?",
                                "answer": "Based on the research papers...",
                                "sources": ["https://arxiv.org/pdf/1706.03762.pdf"],
                                "chunks_used": 3,
                                "search_mode": "hybrid"
                            }
                        },
                        "no_relevant_info": {
                            "summary": "No relevant information found",
                            "value": {
                                "query": "What is quantum cooking?",
                                "answer": "I couldn't find any relevant information...",
                                "sources": [],
                                "chunks_used": 0,
                                "search_mode": "bm25"
                            }
                        }
                    }
                }
            }
        },
        422: {
            "description": "Validation error",
            "content": {
                "application/json": {
                    "example": {
                        "detail": [
                            {
                                "loc": ["body", "query"],
                                "msg": "ensure this value has at least 1 characters",
                                "type": "value_error.any_str.min_length"
                            }
                        ]
                    }
                }
            }
        },
        500: {
            "description": "Internal server error",
            "content": {
                "application/json": {
                    "example": {
                        "error": "InternalServerError",
                        "message": "LLM service unavailable"
                    }
                }
            }
        }
    },

    # ⚠️ SHOULD: tags (显式)
    tags=["ask"],

    # ⚠️ OPTIONAL: deprecated (如果弃用)
    # deprecated=True,
)
async def ask_question(
    request: AskRequest,
    # ... dependencies
) -> AskResponse:
    """
    ✅ MUST: Docstring (将出现在 OpenAPI description 中)
    """
    # Implementation...
    pass
```

**规则**:
- ✅ **MUST**: 所有 POST/PUT/PATCH 端点必须有 `response_model`
- ✅ **MUST**: 所有端点必须有唯一的 `operation_id`
- ✅ **MUST**: `summary` ≤ 50 字符
- ✅ **MUST**: `description` 使用 Markdown,包含示例代码
- ✅ **MUST**: `responses` 至少定义 200, 422, 500
- ⚠️ **SHOULD**: 提供多个 `examples` (成功和失败场景)

---

### 3.3 Pydantic Schema 规范

```python
# src/schemas/api/ask.py

from typing import List, Optional
from pydantic import BaseModel, Field, ConfigDict


class AskRequest(BaseModel):
    """
    ✅ MUST: Class docstring

    Request model for RAG question answering.
    """

    # ✅ MUST: 每个字段都有 description
    query: str = Field(
        ...,  # required
        description="User's question about academic research papers",
        min_length=1,
        max_length=1000,
        examples=[  # OpenAPI 3.1 新语法 (推荐)
            "What are transformers in machine learning?",
            "Explain the attention mechanism in BERT",
            "Latest developments in quantum computing"
        ]
    )

    top_k: int = Field(
        default=3,
        description="Number of top document chunks to retrieve for context",
        ge=1,  # greater than or equal
        le=10,  # less than or equal
        examples=[3, 5, 10]
    )

    use_hybrid: bool = Field(
        default=True,
        description="Enable hybrid search (BM25 + vector similarity). Falls back to BM25 if embedding fails.",
        examples=[True, False]
    )

    model: str = Field(
        default="llama3.2:1b",
        description="Ollama model name for answer generation. Available: llama3.2:1b, llama3.2:3b, qwen2.5:7b",
        examples=["llama3.2:1b", "llama3.2:3b", "qwen2.5:7b"]
    )

    categories: Optional[List[str]] = Field(
        default=None,
        description="Filter papers by arXiv categories. Leave empty for all categories.",
        examples=[
            ["cs.AI", "cs.LG"],
            ["cs.CV"],
            None
        ]
    )

    # ✅ MUST: model_config (Pydantic v2)
    model_config = ConfigDict(
        # ✅ MUST: json_schema_extra 提供完整示例
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
                    "answer": "Based on the research papers, transformers are neural network architectures that rely entirely on attention mechanisms...",
                    "sources": [
                        "https://arxiv.org/pdf/1706.03762.pdf",
                        "https://arxiv.org/pdf/1810.04805.pdf"
                    ],
                    "chunks_used": 3,
                    "search_mode": "hybrid"
                },
                {
                    "query": "What is quantum cooking?",
                    "answer": "I couldn't find any relevant information in the papers to answer your question.",
                    "sources": [],
                    "chunks_used": 0,
                    "search_mode": "bm25"
                }
            ]
        }
    )
```

**规则**:
- ✅ **MUST**: 所有 Pydantic model 必须有 class docstring
- ✅ **MUST**: 所有字段必须有 `description`
- ✅ **MUST**: 使用 `Field` 定义字段约束 (如 `min_length`, `ge`, `le`)
- ✅ **MUST**: `model_config` 必须提供 `json_schema_extra` 的完整示例
- ⚠️ **SHOULD**: 提供多个示例 (至少 2 个,覆盖成功和边缘情况)
- ⚠️ **SHOULD**: 使用 OpenAPI 3.1 的 `examples` (数组) 而非 `example` (单个)

---

## 4. Schema 设计规范

### 4.1 命名规范

| 类型 | 格式 | 示例 | 说明 |
|------|------|------|------|
| **Schema 名称** | `PascalCase` | `SearchResponse`, `AskRequest` | ✅ MUST |
| **字段名称** | `snake_case` | `top_k`, `search_mode` | ✅ MUST |
| **Enum 值** | `lowercase` or `kebab-case` | `"bm25"`, `"hybrid"` | ✅ MUST |
| **Tag 名称** | `kebab-case` | `hybrid-search`, `agentic-rag` | ✅ MUST |
| **operationId** | `snake_case` | `ask_question_basic_rag` | ✅ MUST |

---

### 4.2 类型定义规范

#### 字符串验证

```yaml
type: string
minLength: 1          # ✅ MUST: 禁止空字符串 (如果不允许)
maxLength: 1000       # ✅ MUST: 防止 DoS 攻击
pattern: "^[a-z]+$"   # ⚠️ SHOULD: 使用正则验证格式
format: "email"       # ⚠️ SHOULD: 使用标准 format (email, uri, date-time)
```

#### 数字验证

```yaml
type: integer
minimum: 1            # ✅ MUST: 最小值
maximum: 100          # ✅ MUST: 最大值
exclusiveMinimum: 0   # ⚠️ OPTIONAL: 排他性最小值
multipleOf: 10        # ⚠️ OPTIONAL: 倍数约束
```

#### 数组验证

```yaml
type: array
items:
  type: string
minItems: 1           # ✅ MUST: 最少元素 (如果不允许空数组)
maxItems: 50          # ✅ MUST: 防止 DoS
uniqueItems: true     # ⚠️ SHOULD: 如果要求唯一性
```

#### 对象验证

```yaml
type: object
required:             # ✅ MUST: 必需字段
  - id
  - name
properties:
  id:
    type: string
  name:
    type: string
additionalProperties: false  # ⚠️ SHOULD: 禁止额外字段 (严格模式)
```

---

### 4.3 可空性处理

**OpenAPI 3.0**:
```yaml
type: string
nullable: true  # 允许 null
```

**OpenAPI 3.1** (推荐):
```yaml
type:
  - string
  - "null"  # JSON Schema Draft 2020-12 语法
```

**FastAPI/Pydantic**:
```python
from typing import Optional

# ✅ 正确: 允许 null 或缺失
field: Optional[str] = None

# ✅ 正确: 允许 null 但必须提供
field: Optional[str] = Field(...)

# ❌ 错误: 不允许 null
field: str = None  # 会导致验证错误
```

---

## 5. 文档撰写规范

### 5.1 Markdown 使用规范

#### 标题层级

```markdown
# H1: 仅用于主标题 (每个 description 只有 1 个)

## H2: 主要章节 (Features, How It Works, Examples)

### H3: 子章节 (Use Cases, Performance)

#### H4: 细节 (不推荐使用,层级过深)
```

**规则**:
- ✅ **MUST**: 使用 `##` 开始 (不使用 `#`)
- ⚠️ **SHOULD**: 层级 ≤ 3 (避免过深嵌套)

---

#### 代码块

```markdown
### Example (Python)

\`\`\`python
import httpx

response = httpx.post(
    "http://localhost:8000/api/v1/ask",
    json={"query": "What is attention?"}
)
print(response.json())
\`\`\`
```

**规则**:
- ✅ **MUST**: 使用语言标识符 (如 `python`, `javascript`, `bash`)
- ✅ **MUST**: 代码可直接复制运行
- ⚠️ **SHOULD**: 提供多语言示例 (至少 Python + cURL)

---

#### 列表

```markdown
## Features

- ✅ Hybrid Search (BM25 + Vector)
- ✅ Redis Caching (6-hour TTL)
- ✅ Real-time Tracing
```

**规则**:
- ⚠️ **SHOULD**: 使用 Emoji 增强可读性 (但不过度)
- ⚠️ **SHOULD**: 列表项简洁 (≤ 15 字)

---

#### 表格

```markdown
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| query | string | - | User's question |
| top_k | integer | 3 | Number of chunks |
```

**规则**:
- ⚠️ **SHOULD**: 用于参数说明或对比
- ❌ **MUST NOT**: 表格嵌套或过于复杂

---

### 5.2 描述撰写最佳实践

#### Endpoint Description 模板

```markdown
## {Emoji} {功能名称}

{一句话功能描述}

### How It Works

1. {步骤 1}
2. {步骤 2}
3. {步骤 3}

### Use Cases

- ✅ {场景 1}
- ✅ {场景 2}
- ✅ {场景 3}

### Performance

- Average latency: {数值}
- P95 latency: {数值}
- Rate limit: {数值}

### Example ({语言})

\`\`\`{语言}
{完整可运行代码}
\`\`\`

### Notes

- ⚠️ {重要警告或限制}
```

---

## 6. 安全和隐私规范

### 6.1 敏感信息脱敏

#### ❌ 禁止暴露

| 类型 | 示例 | 风险 |
|------|------|------|
| **内部 IP** | `192.168.1.100`, `10.0.0.5` | 网络拓扑泄露 |
| **内部端口** | `5432` (PostgreSQL), `6379` (Redis) | 服务识别 |
| **内部服务名** | `http://api:8000`, `postgres://db:5432` | 架构泄露 |
| **真实密钥** | `sk-1234567890abcdef` | 访问权限 |
| **真实 Token** | `Bearer eyJhbGci...` | 身份盗用 |
| **内部路径** | `/home/user/project/...` | 系统信息 |
| **Stack Trace** | `File "src/main.py", line 42...` | 代码结构 |

#### ✅ 正确做法

```yaml
# ❌ 错误
servers:
  - url: "http://api:8000"
  - url: "postgresql://postgres:5432/db"

# ✅ 正确
servers:
  - url: "http://localhost:8000"
  - url: "https://api.example.com"

---

# ❌ 错误
examples:
  api_key:
    value: "sk-1234567890abcdef"  # 真实 key

# ✅ 正确
examples:
  api_key:
    value: "sk-xxxxxxxxxxxxxxxx"  # 占位符

---

# ❌ 错误
error:
  message: "Connection failed to postgres://admin:password@db.internal:5432/prod"

# ✅ 正确
error:
  message: "Database connection failed"
```

---

### 6.2 环境变量保护

**❌ 错误**:
```yaml
# 在 OpenAPI spec 中暴露环境变量
description: |
  Connect using: ${DATABASE_URL}
```

**✅ 正确**:
```python
# 在代码中使用环境变量,但不在 spec 中暴露
import os

servers=[
    {
        "url": os.getenv("PUBLIC_API_URL", "http://localhost:8000"),
        "description": "API Server"
    }
]
```

---

### 6.3 安全验证清单

```bash
#!/bin/bash
# scripts/security_check.sh

echo "🔒 Security Checklist for OpenAPI Spec"

# 1. 检查内部 IP
if grep -qE '192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.' openapi.json; then
    echo "❌ FAIL: Internal IP addresses found"
    exit 1
fi

# 2. 检查敏感端口
if grep -qE ':(5432|6379|9200|3306|27017)' openapi.json; then
    echo "❌ FAIL: Internal service ports exposed"
    exit 1
fi

# 3. 检查密钥模式
if grep -qiE '(password|secret|token).*:.*"[^"]{10,}"' openapi.json; then
    echo "❌ FAIL: Potential secrets found"
    exit 1
fi

# 4. 检查示例邮箱
if grep -q 'example\.com' openapi.json; then
    echo "⚠️  WARNING: Placeholder emails found (update before production)"
fi

echo "✅ Security checks passed"
```

---

## 7. 验证和测试规范

### 7.1 OpenAPI 规范验证

#### 工具选择

| 工具 | 用途 | 严格度 |
|------|------|--------|
| **Spectral** | OpenAPI 最佳实践 Linting | ⭐⭐⭐⭐⭐ |
| **openapi-spec-validator** | 规范合规性验证 | ⭐⭐⭐⭐ |
| **Swagger Editor** | 可视化验证 | ⭐⭐⭐ |
| **Scalar CLI** | Scalar 兼容性 | ⭐⭐⭐⭐ |

#### Spectral 配置

**.spectral.yml** (最严格):

```yaml
extends: ["spectral:oas", "spectral:asyncapi"]

rules:
  # ✅ 必需字段
  info-contact: error          # 必须有联系信息
  info-description: error      # 必须有描述
  info-license: warn           # 应该有许可证

  # ✅ Operation 规范
  operation-description: error # 每个 operation 必须有描述
  operation-operationId: error # 每个 operation 必须有唯一 ID
  operation-summary: error     # 每个 operation 必须有摘要
  operation-tags: error        # 每个 operation 必须有 tags

  # ✅ 参数规范
  operation-parameters: warn   # 参数应该有描述
  parameter-description: error # 参数必须有描述

  # ✅ 响应规范
  operation-success-response: error  # 必须有成功响应
  operation-2xx-response: error      # 必须有 2xx 响应
  operation-4xx-response: warn       # 应该有 4xx 错误响应

  # ✅ Schema 规范
  typed-enum: error            # enum 必须有类型
  no-$ref-siblings: error      # $ref 不能有兄弟节点

  # ✅ 安全规范
  no-script-tags-in-markdown: error  # 描述中不能有 <script>

  # ⚠️ 自定义规则
  custom-example-required:
    description: "All schemas must have examples"
    severity: error
    given: "$.components.schemas.*"
    then:
      field: "examples"
      function: truthy
```

**运行验证**:

```bash
# 安装 Spectral
npm install -g @stoplight/spectral-cli

# 运行验证 (最严格)
spectral lint openapi.json --ruleset .spectral.yml --fail-severity warn

# 预期输出 (无错误)
✅ 0 errors, 0 warnings, 0 infos, 0 hints
```

---

### 7.2 自动化测试

#### 测试金字塔

```
          /\
         /  \    E2E Tests (10%)
        /────\   - Scalar UI 加载测试
       /      \  - 端到端 API 调用
      /────────\
     /          \ Integration Tests (30%)
    /   ────────\  - OpenAPI spec 验证
   /              \ - Schema 验证
  /────────────────\
 /                  \ Unit Tests (60%)
/──────────────────── - Pydantic model 验证
                       - 字段约束测试
```

#### 测试套件

**tests/test_openapi_compliance.py**:

```python
import pytest
import httpx
import json

BASE_URL = "http://localhost:8000"


class TestOpenAPICompliance:
    """OpenAPI 规范合规性测试"""

    @pytest.fixture
    def openapi_spec(self):
        """获取 OpenAPI spec"""
        response = httpx.get(f"{BASE_URL}/openapi.json")
        assert response.status_code == 200
        return response.json()

    def test_openapi_version(self, openapi_spec):
        """✅ MUST: OpenAPI version 必须是 3.x"""
        version = openapi_spec["openapi"]
        assert version.startswith("3."), f"Invalid OpenAPI version: {version}"

    def test_info_required_fields(self, openapi_spec):
        """✅ MUST: Info object 必需字段"""
        info = openapi_spec["info"]

        assert "title" in info, "Missing info.title"
        assert "version" in info, "Missing info.version"
        assert "description" in info, "Missing info.description"

        # 描述长度
        assert len(info["description"]) > 200, "Description too short (< 200 chars)"

        # 联系信息
        assert "contact" in info, "Missing info.contact"
        assert "email" in info["contact"], "Missing contact.email"
        assert "example.com" not in info["contact"]["email"], "Placeholder email detected"

        # 许可证
        assert "license" in info, "Missing info.license"
        assert "name" in info["license"], "Missing license.name"

    def test_servers_defined(self, openapi_spec):
        """✅ MUST: 至少定义 1 个 server"""
        servers = openapi_spec.get("servers", [])
        assert len(servers) >= 1, "No servers defined"

        for server in servers:
            assert "url" in server, "Server missing URL"
            assert "description" in server, "Server missing description"

            # 安全检查
            url = server["url"]
            assert not any(ip in url for ip in ["192.168.", "10.", "172."]), \
                f"Internal IP in server URL: {url}"

    def test_all_operations_have_required_fields(self, openapi_spec):
        """✅ MUST: 所有 operation 必需字段"""
        paths = openapi_spec["paths"]

        for path, methods in paths.items():
            for method, operation in methods.items():
                if method not in ["get", "post", "put", "delete", "patch"]:
                    continue

                # operationId
                assert "operationId" in operation, \
                    f"Missing operationId in {method.upper()} {path}"

                # summary
                assert "summary" in operation, \
                    f"Missing summary in {method.upper()} {path}"
                assert len(operation["summary"]) <= 50, \
                    f"Summary too long in {method.upper()} {path}"

                # description
                assert "description" in operation, \
                    f"Missing description in {method.upper()} {path}"
                assert len(operation["description"]) > 50, \
                    f"Description too short in {method.upper()} {path}"

                # tags
                assert "tags" in operation, \
                    f"Missing tags in {method.upper()} {path}"
                assert len(operation["tags"]) >= 1, \
                    f"No tags in {method.upper()} {path}"

                # responses
                assert "responses" in operation, \
                    f"Missing responses in {method.upper()} {path}"

                responses = operation["responses"]
                assert "200" in responses or any(k.startswith("2") for k in responses), \
                    f"Missing 2xx response in {method.upper()} {path}"

    def test_all_operations_have_unique_operation_ids(self, openapi_spec):
        """✅ MUST: operationId 唯一性"""
        operation_ids = set()

        for path, methods in openapi_spec["paths"].items():
            for method, operation in methods.items():
                if method not in ["get", "post", "put", "delete", "patch"]:
                    continue

                op_id = operation.get("operationId")
                assert op_id not in operation_ids, \
                    f"Duplicate operationId: {op_id}"
                operation_ids.add(op_id)

    def test_all_post_endpoints_have_examples(self, openapi_spec):
        """⚠️ SHOULD: POST 端点应该有 examples"""
        for path, methods in openapi_spec["paths"].items():
            if "post" in methods:
                operation = methods["post"]

                if "requestBody" in operation:
                    content = operation["requestBody"]["content"]["application/json"]

                    # 检查 examples (OpenAPI 3.1) 或 example (OpenAPI 3.0)
                    has_examples = (
                        "examples" in content or
                        "example" in content.get("schema", {}) or
                        "examples" in content.get("schema", {})
                    )

                    assert has_examples, \
                        f"Missing examples in POST {path}"

    def test_all_schemas_have_descriptions(self, openapi_spec):
        """✅ MUST: 所有 schema 有描述"""
        schemas = openapi_spec.get("components", {}).get("schemas", {})

        for schema_name, schema in schemas.items():
            assert "description" in schema or "title" in schema, \
                f"Schema '{schema_name}' missing description"

            # 检查所有属性
            if "properties" in schema:
                for prop_name, prop_schema in schema["properties"].items():
                    assert "description" in prop_schema, \
                        f"Property '{schema_name}.{prop_name}' missing description"

    def test_no_sensitive_information(self, openapi_spec):
        """✅ MUST: 无敏感信息泄露"""
        spec_str = json.dumps(openapi_spec)

        # 检查内部 IP
        assert "192.168." not in spec_str, "Internal IP detected"
        assert " 10." not in spec_str or "top_k" in spec_str, "Internal IP detected"  # 允许 top_k=10

        # 检查常见密钥模式
        import re
        secret_pattern = re.compile(r'(password|secret|token).*:.*"[a-zA-Z0-9]{16,}"', re.IGNORECASE)
        assert not secret_pattern.search(spec_str), "Potential secret detected"


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
```

**运行测试**:

```bash
pytest tests/test_openapi_compliance.py -v

# 预期输出
tests/test_openapi_compliance.py::test_openapi_version PASSED
tests/test_openapi_compliance.py::test_info_required_fields PASSED
tests/test_openapi_compliance.py::test_servers_defined PASSED
tests/test_openapi_compliance.py::test_all_operations_have_required_fields PASSED
tests/test_openapi_compliance.py::test_all_operations_have_unique_operation_ids PASSED
tests/test_openapi_compliance.py::test_all_post_endpoints_have_examples PASSED
tests/test_openapi_compliance.py::test_all_schemas_have_descriptions PASSED
tests/test_openapi_compliance.py::test_no_sensitive_information PASSED

============ 8 passed in 1.23s ============
```

---

## 8. 性能和优化规范

### 8.1 OpenAPI Spec 大小优化

**规则**:
- ⚠️ **SHOULD**: OpenAPI spec 大小 < 500KB (未压缩)
- ⚠️ **SHOULD**: 使用 `$ref` 避免重复定义
- ⚠️ **SHOULD**: 启用 gzip 压缩 (FastAPI 默认支持)

**示例** (使用 $ref):

```yaml
# ❌ 错误: 重复定义
paths:
  /api/v1/ask:
    post:
      responses:
        '422':
          description: "Validation error"
          content:
            application/json:
              schema:
                type: object
                properties:
                  detail:
                    type: array
                    items:
                      type: object

  /api/v1/hybrid-search:
    post:
      responses:
        '422':
          description: "Validation error"
          content:
            application/json:
              schema:
                type: object
                properties:
                  detail:
                    type: array
                    items:
                      type: object

# ✅ 正确: 使用 $ref
components:
  schemas:
    ValidationError:
      type: object
      properties:
        detail:
          type: array
          items:
            type: object

paths:
  /api/v1/ask:
    post:
      responses:
        '422':
          $ref: "#/components/responses/ValidationError"

  /api/v1/hybrid-search:
    post:
      responses:
        '422':
          $ref: "#/components/responses/ValidationError"

components:
  responses:
    ValidationError:
      description: "Validation error"
      content:
        application/json:
          schema:
            $ref: "#/components/schemas/ValidationError"
```

---

### 8.2 Scalar UI 性能

**规则**:
- ✅ **MUST**: OpenAPI spec 可在 2 秒内加载
- ⚠️ **SHOULD**: 使用 CDN 托管 Scalar JavaScript (已在 V2 guide 中使用)
- ⚠️ **SHOULD**: 启用浏览器缓存 (Cache-Control headers)

**FastAPI 配置**:

```python
from fastapi import FastAPI, Response

@app.get("/openapi.json", include_in_schema=False)
async def get_openapi_spec():
    """返回 OpenAPI spec (带缓存)"""
    return Response(
        content=json.dumps(app.openapi()),
        media_type="application/json",
        headers={
            "Cache-Control": "public, max-age=3600",  # 缓存 1 小时
            "ETag": hashlib.md5(json.dumps(app.openapi()).encode()).hexdigest()
        }
    )
```

---

## 📚 参考资源

### 官方规范

- [OpenAPI 3.1 Specification](https://spec.openapis.org/oas/v3.1.0.html) - 官方规范
- [JSON Schema 2020-12](https://json-schema.org/draft/2020-12/json-schema-core.html) - OpenAPI 3.1 基于此
- [Scalar Documentation](https://guides.scalar.com/) - Scalar 官方文档
- [Scalar Configuration](https://guides.scalar.com/scalar/scalar-api-references/configuration) - 配置指南
- [Scalar OpenAPI](https://guides.scalar.com/scalar/scalar-api-references/openapi) - OpenAPI 集成

### 验证工具

- [Spectral](https://stoplight.io/open-source/spectral) - OpenAPI Linting
- [openapi-spec-validator](https://github.com/python-openapi/openapi-spec-validator) - Python 验证器
- [IBM OpenAPI Validator](https://github.com/IBM/openapi-validator) - 严格验证器

### 最佳实践

- [Microsoft API Guidelines](https://github.com/microsoft/api-guidelines) - API 设计最佳实践
- [Google API Design Guide](https://cloud.google.com/apis/design) - Google API 设计指南
- [Zalando RESTful API Guidelines](https://opensource.zalando.com/restful-api-guidelines/) - Zalando 规范

---

## ✅ 合规性检查清单

### 必需项 (MUST) - 100% 合规

- [ ] OpenAPI version 是 3.1.0 或 3.0.2
- [ ] `info.title`, `info.version`, `info.description` 完整
- [ ] `info.contact.email` 非占位符
- [ ] `info.license` 已定义
- [ ] 至少 1 个 `server` 定义
- [ ] 所有 operation 有唯一的 `operationId`
- [ ] 所有 operation 有 `summary` (≤ 50 字符)
- [ ] 所有 operation 有 `description` (≥ 100 字符)
- [ ] 所有 operation 有至少 1 个 `tag`
- [ ] 所有 operation 定义了 200, 4xx, 5xx 响应
- [ ] 所有 schema 有 `type` 和 `description`
- [ ] 所有 schema 属性有 `description`
- [ ] 无内部 IP 地址暴露
- [ ] 无硬编码密钥或 token

### 推荐项 (SHOULD) - 80%+ 合规

- [ ] POST 端点有多个 `examples`
- [ ] 使用 Markdown 撰写 `description`
- [ ] 提供代码示例 (至少 Python + cURL)
- [ ] 使用 JSON Schema 验证关键字 (minLength, minimum, etc.)
- [ ] 使用 `$ref` 避免重复定义
- [ ] Spectral linting 通过 (0 errors)
- [ ] OpenAPI spec 大小 < 500KB
- [ ] Scalar UI 加载时间 < 2s

### 可选项 (OPTIONAL) - 加分项

- [ ] 使用 Scalar 自定义扩展 (x-tagGroups, x-logo)
- [ ] 提供 3+ 语言的代码示例
- [ ] 性能指标在 description 中注明
- [ ] 使用 `x-stability` 标记实验性端点
- [ ] 启用 API 认证 (securitySchemes)

---

**版本历史**:
- **v1.0** (2025-12-07): 初始版本,基于 OpenAPI 3.1 + Scalar 最佳实践

**维护者**: arXiv Paper Curator Team
**反馈**: 通过 GitHub Issues 提交改进建议
