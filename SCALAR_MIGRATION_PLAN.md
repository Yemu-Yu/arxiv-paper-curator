# Scalar API 管理平台迁移计划

## 📋 项目概述

**目标**: 将 arXiv Paper Curator 的 6 个 FastAPI 端点迁移到 Scalar API 管理平台

**当前状态**:
- FastAPI 应用运行在 `http://localhost:8000`
- 自带 Swagger UI (`/docs`) 和 ReDoc (`/redoc`)
- OpenAPI 3.0 规范自动生成
- 6 个核心 API 端点 (Health, Search, RAG x4)

**目标状态**:
- Scalar API 文档和交互式界面
- API 版本管理和变更追踪
- Mock Server 支持
- API 治理和安全策略

---

## 🎯 迁移目标和收益

### 核心目标

1. **统一 API 文档平台** - 替代默认的 Swagger UI
2. **改善开发者体验** - Scalar 的现代化界面和交互
3. **API 版本管理** - 支持多版本并存和平滑迁移
4. **增强安全性** - API 密钥管理、访问控制
5. **监控和分析** - API 调用统计、性能监控

### 预期收益

| 维度 | 当前 Swagger UI | Scalar 平台 | 改进 |
|------|----------------|------------|------|
| **UI/UX** | 基础功能界面 | 现代化、响应式 | ⭐⭐⭐⭐⭐ |
| **代码生成** | 无 | 多语言 SDK 生成 | ⭐⭐⭐⭐ |
| **版本管理** | 单一版本 | 多版本并存 | ⭐⭐⭐⭐⭐ |
| **Mock Server** | 无 | 内置 Mock | ⭐⭐⭐⭐ |
| **API 治理** | 无 | Linting + Best Practices | ⭐⭐⭐⭐ |
| **安全认证** | 手动实现 | 内置 OAuth/API Key | ⭐⭐⭐⭐⭐ |
| **协作功能** | 无 | 团队协作 + 评论 | ⭐⭐⭐⭐ |

---

## 📊 迁移方案对比

### 方案 A: Scalar 本地自托管 (推荐)

**架构**:
```
FastAPI (8000) ──► Scalar Gateway (7999) ──► Scalar UI (7998)
                        │
                        └──► OpenAPI Spec
```

**优点**:
- ✅ 完全控制数据和隐私
- ✅ 无外部依赖
- ✅ 与 Docker Compose 集成简单
- ✅ 免费开源

**缺点**:
- ⚠️ 需要维护额外服务
- ⚠️ 功能相对云版本有限

**成本**: $0/月

---

### 方案 B: Scalar Cloud SaaS

**架构**:
```
FastAPI (8000) ──► Scalar Cloud API
                        │
                        └──► 公网可访问的文档
```

**优点**:
- ✅ 零运维成本
- ✅ 自动更新和维护
- ✅ 高级功能（团队协作、分析）
- ✅ CDN 加速

**缺点**:
- ❌ 需要将 API 暴露到公网（或使用 tunnel）
- ❌ 数据隐私风险（API 规范上传到云端）
- ❌ 订阅费用

**成本**: $49-199/月（企业版）

---

### 方案 C: 混合方案 (开发推荐)

**架构**:
```
开发环境: Scalar 本地 (docker-compose)
生产环境: Scalar Cloud (公开文档)
```

**优点**:
- ✅ 开发时完全本地化
- ✅ 生产环境专业文档
- ✅ 灵活的访问控制

**缺点**:
- ⚠️ 需要维护两套配置

**成本**: 开发 $0，生产 $49/月起

---

## 🚀 迁移实施计划

### 阶段 1: 准备和评估 (Week 1)

#### 1.1 环境准备

**安装 Scalar CLI**:
```bash
# 已安装: /opt/homebrew/bin/scalar
scalar --version

# 或使用 npx (无需安装)
npx @scalar/cli --version
```

**验证 OpenAPI 规范**:
```bash
# 启动 FastAPI
docker compose up -d api

# 导出 OpenAPI JSON
curl http://localhost:8000/openapi.json > openapi.json

# 验证规范合法性
npx @scalar/cli validate openapi.json
```

#### 1.2 当前 API 审计

**检查点**:
- [ ] 所有端点都有 Pydantic response_model
- [ ] 所有端点都有文档字符串
- [ ] 所有 schema 都有 example
- [ ] Tags 分类清晰
- [ ] 认证方式明确

**审计脚本**:
```bash
# 检查缺少 response_model 的端点
grep -r "@.*router\.(get|post|put|delete)" src/routers/ | \
  grep -v "response_model" | \
  wc -l
# 期望输出: 0

# 检查缺少文档的端点
grep -A 5 "@.*router\.(get|post)" src/routers/ | \
  grep -c '"""'
# 期望输出: 6 (每个端点都有)
```

#### 1.3 差距分析

**需要优化的部分**:

| 端点 | 当前状态 | 需要改进 | 优先级 |
|------|---------|---------|--------|
| `/health` | ✅ 完整 | - | - |
| `/hybrid-search` | ✅ 完整 | 添加更多 examples | P2 |
| `/ask` | ✅ 完整 | 添加错误码文档 | P1 |
| `/stream` | ⚠️ 无 response_model | 定义 SSE schema | P0 |
| `/ask-agentic` | ✅ 完整 | 添加 LangGraph 流程图 | P2 |
| `/feedback` | ✅ 完整 | - | - |

---

### 阶段 2: OpenAPI 规范增强 (Week 2)

#### 2.1 添加 Scalar 特定元数据

**修改 `src/main.py`**:
```python
# 当前
app = FastAPI(
    title="arXiv Paper Curator API",
    description="Personal arXiv CS.AI paper curator with RAG capabilities",
    version=os.getenv("APP_VERSION", "0.1.0"),
    lifespan=lifespan,
)

# 增强版 (Scalar 优化)
app = FastAPI(
    title="arXiv Paper Curator API",
    description="""
    ## 🎓 Academic Research Assistant with RAG

    A production-grade Retrieval-Augmented Generation system for academic papers.

    ### Features
    - 🔍 Hybrid Search (BM25 + Vector)
    - 🤖 Agentic RAG with LangGraph
    - 📊 Real-time Langfuse Tracing
    - ⚡ Redis Caching
    - 📱 Telegram Bot Integration

    ### Getting Started
    1. Check system health: `GET /api/v1/health`
    2. Try search: `POST /api/v1/hybrid-search`
    3. Ask a question: `POST /api/v1/ask-agentic`
    """,
    version=os.getenv("APP_VERSION", "0.1.0"),
    lifespan=lifespan,
    terms_of_service="https://github.com/jamwithai/arxiv-paper-curator/blob/main/LICENSE",
    contact={
        "name": "arXiv Paper Curator Support",
        "url": "https://github.com/jamwithai/arxiv-paper-curator/issues",
        "email": "support@example.com"
    },
    license_info={
        "name": "MIT License",
        "url": "https://github.com/jamwithai/arxiv-paper-curator/blob/main/LICENSE"
    },
    servers=[
        {
            "url": "http://localhost:8000",
            "description": "Development Server"
        },
        {
            "url": "https://api.arxiv-curator.example.com",
            "description": "Production Server (Future)"
        }
    ],
    # Scalar 特定配置
    openapi_tags=[
        {
            "name": "Health",
            "description": "System health monitoring and service status checks"
        },
        {
            "name": "hybrid-search",
            "description": "Document search with BM25 and vector similarity"
        },
        {
            "name": "ask",
            "description": "Basic RAG question answering (sync and streaming)"
        },
        {
            "name": "stream",
            "description": "Streaming responses with Server-Sent Events"
        },
        {
            "name": "agentic-rag",
            "description": "Intelligent RAG with adaptive retrieval (LangGraph)"
        }
    ]
)

# 添加安全方案 (未来实现)
# from fastapi.security import HTTPBearer
# security = HTTPBearer()
```

#### 2.2 修复 `/stream` 端点的 OpenAPI 定义

**当前问题**: SSE 响应没有明确的 schema

**解决方案**:
```python
# src/routers/ask.py

from fastapi.responses import StreamingResponse
from pydantic import BaseModel

class StreamChunk(BaseModel):
    """Single SSE event chunk"""
    chunk: Optional[str] = Field(None, description="Text chunk from LLM")
    sources: Optional[List[str]] = Field(None, description="Source PDFs")
    chunks_used: Optional[int] = Field(None, description="Number of chunks")
    search_mode: Optional[str] = Field(None, description="Search mode used")
    answer: Optional[str] = Field(None, description="Complete answer")
    done: Optional[bool] = Field(None, description="Stream completion flag")
    error: Optional[str] = Field(None, description="Error message if failed")

@stream_router.post(
    "/stream",
    responses={
        200: {
            "description": "Server-Sent Events stream",
            "content": {
                "text/event-stream": {
                    "schema": {
                        "type": "string",
                        "format": "binary",
                        "description": "SSE stream with JSON events"
                    },
                    "example": 'data: {"chunk": "Based on "}\n\ndata: {"chunk": "the papers..."}\n\ndata: {"answer": "Complete answer", "done": true}\n\n'
                }
            }
        }
    },
    summary="Stream RAG answer in real-time",
    description="""
    Real-time streaming RAG with Server-Sent Events.

    **Event Sequence**:
    1. Metadata event: `{"sources": [...], "chunks_used": 3}`
    2. Chunk events: `{"chunk": "text fragment"}`
    3. Done event: `{"answer": "complete text", "done": true}`

    **Usage**:
    ```javascript
    const eventSource = new EventSource('/api/v1/stream', {
        method: 'POST',
        body: JSON.stringify({query: "..."})
    });
    eventSource.onmessage = (e) => {
        const data = JSON.parse(e.data);
        if (data.chunk) console.log(data.chunk);
        if (data.done) eventSource.close();
    };
    ```
    """
)
async def ask_question_stream(...):
    ...
```

#### 2.3 增强 Schema Examples

**修改所有 schema 文件**:
```python
# src/schemas/api/ask.py

class AskRequest(BaseModel):
    query: str = Field(
        ...,
        description="User's question about academic research",
        min_length=1,
        max_length=1000,
        examples=[
            "What are the advantages of transformers over RNNs?",
            "Explain the attention mechanism in BERT",
            "Latest developments in quantum computing"
        ]
    )
    top_k: int = Field(
        3,
        description="Number of top chunks to retrieve",
        ge=1,
        le=10,
        examples=[3, 5, 10]
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
                    "query": "Explain self-attention mechanism",
                    "top_k": 5,
                    "use_hybrid": False,
                    "model": "llama3.2:3b",
                    "categories": ["cs.AI", "cs.LG"]
                }
            ]
        }
    )
```

---

### 阶段 3: Scalar 集成部署 (Week 3)

#### 3.1 Docker Compose 配置

**添加到 `compose.yml`**:
```yaml
services:
  # ... 现有服务 ...

  # Scalar API Reference (文档 UI)
  scalar:
    image: scalar/scalar-api-reference:latest
    container_name: arxiv-scalar-ui
    ports:
      - "7998:8080"
    environment:
      - SPEC_URL=http://api:8000/openapi.json
      # Scalar 配置
      - SCALAR_THEME=purple  # purple, blue, green, default
      - SCALAR_LAYOUT=modern  # modern, classic
      - SCALAR_PROXY_ENABLED=true
      - SCALAR_SHOW_SIDEBAR=true
    depends_on:
      - api
    networks:
      - rag-network
    restart: unless-stopped

  # Scalar Gateway (可选 - API 网关)
  scalar-gateway:
    image: scalar/scalar-gateway:latest
    container_name: arxiv-scalar-gateway
    ports:
      - "7999:8080"
    environment:
      - UPSTREAM_URL=http://api:8000
      - OPENAPI_URL=http://api:8000/openapi.json
      # API 治理
      - ENABLE_RATE_LIMIT=true
      - RATE_LIMIT_REQUESTS=100
      - RATE_LIMIT_WINDOW=60
      # 安全
      - ENABLE_CORS=true
      - CORS_ORIGINS=http://localhost:7998,http://localhost:7861
      # Mock Server
      - ENABLE_MOCK=true
    depends_on:
      - api
    networks:
      - rag-network
    restart: unless-stopped
```

#### 3.2 启动和验证

```bash
# 1. 重建服务
docker compose up -d --build scalar scalar-gateway

# 2. 验证 Scalar UI
open http://localhost:7998

# 3. 验证 API Gateway
curl http://localhost:7999/api/v1/health

# 4. 检查日志
docker compose logs scalar -f
```

#### 3.3 Nginx 反向代理（生产环境）

**`nginx/scalar.conf`**:
```nginx
upstream scalar_ui {
    server scalar:8080;
}

upstream scalar_gateway {
    server scalar-gateway:8080;
}

server {
    listen 80;
    server_name docs.arxiv-curator.example.com;

    # Scalar 文档
    location / {
        proxy_pass http://scalar_ui;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # API 请求通过 Gateway
    location /api/ {
        proxy_pass http://scalar_gateway;
        proxy_set_header Host $host;

        # CORS headers
        add_header Access-Control-Allow-Origin *;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS";
    }
}
```

---

### 阶段 4: 高级功能启用 (Week 4)

#### 4.1 API 版本管理

**创建 v2 API（示例）**:
```python
# src/routers/v2/agentic_ask.py
from fastapi import APIRouter

router = APIRouter(prefix="/api/v2", tags=["agentic-rag-v2"])

@router.post("/ask-agentic")
async def ask_agentic_v2(...):
    """
    V2 enhancements:
    - Multi-agent orchestration
    - Improved context window handling
    - Cost optimization
    """
    ...

# src/main.py
app.include_router(agentic_ask_v2.router)  # V2 API
app.include_router(agentic_ask.router)     # V1 (保持兼容)
```

**OpenAPI Spec 合并**:
```python
# 生成多版本文档
app = FastAPI(
    title="arXiv Paper Curator API",
    version="2.0.0",
    openapi_tags=[
        {"name": "v1", "description": "Stable API (deprecated 2025-06-01)"},
        {"name": "v2", "description": "Current API with enhanced features"}
    ]
)
```

#### 4.2 Mock Server 配置

**Scalar Gateway Mock 模式**:
```yaml
# .scalar/mock-config.yml
mocks:
  - path: /api/v1/ask
    method: POST
    response:
      status: 200
      delay: 500  # 模拟真实延迟
      body:
        query: "{{request.body.query}}"
        answer: "This is a mocked response for testing purposes."
        sources: ["https://arxiv.org/pdf/mock.pdf"]
        chunks_used: 3
        search_mode: "hybrid"

  - path: /api/v1/ask-agentic
    method: POST
    response:
      status: 200
      body:
        query: "{{request.body.query}}"
        answer: "Mocked agentic response with reasoning."
        reasoning_steps:
          - "✓ Mock: Query validated"
          - "✓ Mock: Documents retrieved"
          - "✓ Mock: Answer generated"
        retrieval_attempts: 1
        trace_id: "mock-trace-12345"
```

**用途**:
- 前端开发无需真实后端
- 集成测试环境隔离
- Demo 和演示用途

#### 4.3 API 安全增强

**添加 API Key 认证**:
```python
# src/dependencies.py
from fastapi import Security, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def verify_api_key(
    credentials: HTTPAuthorizationCredentials = Security(security)
) -> str:
    """Verify API key from Authorization header"""
    api_key = credentials.credentials

    # 简单验证（生产环境使用数据库）
    valid_keys = os.getenv("VALID_API_KEYS", "").split(",")
    if api_key not in valid_keys:
        raise HTTPException(
            status_code=401,
            detail="Invalid API key"
        )
    return api_key

# src/routers/agentic_ask.py
from src.dependencies import verify_api_key

@router.post("/ask-agentic")
async def ask_agentic(
    request: AskRequest,
    api_key: str = Depends(verify_api_key),  # 添加认证
    agentic_rag: AgenticRAGDep,
):
    ...
```

**OpenAPI 安全方案**:
```python
# src/main.py
app = FastAPI(
    ...
    # 定义安全方案
    swagger_ui_init_oauth={
        "clientId": "scalar-client",
        "appName": "arXiv Paper Curator"
    }
)

# 在 OpenAPI spec 中声明
from fastapi.openapi.utils import get_openapi

def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema

    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        routes=app.routes,
    )

    # 添加安全方案
    openapi_schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "API Key"
        }
    }

    # 全局应用（可选）
    # openapi_schema["security"] = [{"BearerAuth": []}]

    app.openapi_schema = openapi_schema
    return app.openapi_schema

app.openapi = custom_openapi
```

---

### 阶段 5: 测试和优化 (Week 5)

#### 5.1 端到端测试

**测试清单**:
```bash
# 1. OpenAPI Spec 有效性
npx @scalar/cli validate openapi.json

# 2. Scalar UI 可访问性
curl -I http://localhost:7998

# 3. API 通过 Gateway 调用
curl -X POST http://localhost:7999/api/v1/ask \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "top_k": 1}'

# 4. Mock Server 响应
curl -X POST http://localhost:7999/api/v1/ask?mock=true \
  -H "Content-Type: application/json" \
  -d '{"query": "test"}'

# 5. SSE 流式传输
curl -N -X POST http://localhost:7999/api/v1/stream \
  -H "Content-Type: application/json" \
  -d '{"query": "test", "top_k": 1}'
```

#### 5.2 性能测试

**负载测试脚本**:
```python
# tests/load_test_scalar.py
import asyncio
import httpx
import time

async def load_test_gateway(concurrent_requests: int = 10):
    """Test Scalar Gateway performance"""

    async def single_request():
        async with httpx.AsyncClient() as client:
            start = time.time()
            response = await client.post(
                "http://localhost:7999/api/v1/ask",
                json={"query": "What is attention?", "top_k": 3},
                timeout=30.0
            )
            latency = time.time() - start
            return response.status_code, latency

    # 并发请求
    tasks = [single_request() for _ in range(concurrent_requests)]
    results = await asyncio.gather(*tasks)

    # 统计
    success = sum(1 for status, _ in results if status == 200)
    avg_latency = sum(latency for _, latency in results) / len(results)

    print(f"Success: {success}/{concurrent_requests}")
    print(f"Average latency: {avg_latency:.2f}s")
    print(f"RPS: {concurrent_requests / max(latency for _, latency in results):.2f}")

# 运行测试
asyncio.run(load_test_gateway(concurrent_requests=50))
```

**预期结果**:
- 直连 API: ~2-3s 平均延迟
- 通过 Gateway: ~2.5-3.5s (增加 ~500ms)
- RPS: 10-15 (受 Ollama 限制)

#### 5.3 文档质量检查

**Scalar Linting**:
```bash
# OpenAPI 最佳实践检查
npx @scalar/cli lint openapi.json

# 常见问题:
# - Missing operation IDs
# - Inconsistent naming conventions
# - Missing examples
# - Incomplete error responses
```

**修复示例**:
```python
# 添加 operation_id (唯一标识符)
@router.post(
    "/ask-agentic",
    operation_id="ask_question_with_agentic_rag",  # 添加
    summary="Ask with intelligent retrieval",
    response_model=AgenticAskResponse
)
```

---

## ⚠️ 风险分析和缓解措施

### 风险矩阵

| 风险 | 影响 | 概率 | 等级 | 缓解措施 |
|------|------|------|------|---------|
| **OpenAPI 规范不兼容** | 高 | 低 | 🟡 中 | 使用 Scalar CLI 验证 |
| **性能下降（Gateway 开销）** | 中 | 中 | 🟡 中 | 负载测试 + 监控 |
| **SSE 流式传输问题** | 高 | 中 | 🟠 高 | 充分测试 + 降级方案 |
| **API 破坏性变更** | 高 | 低 | 🟡 中 | 版本管理 + 弃用策略 |
| **安全漏洞（API Key 泄露）** | 高 | 中 | 🟠 高 | 密钥轮换 + 审计日志 |
| **Docker 镜像大小增加** | 低 | 高 | 🟢 低 | 多阶段构建 |
| **维护成本增加** | 中 | 中 | 🟡 中 | 自动化部署 |
| **团队学习曲线** | 低 | 高 | 🟢 低 | 文档和培训 |

---

### 风险 1: OpenAPI 规范不兼容 🟡

**场景**: Scalar 对 OpenAPI 3.0/3.1 的某些特性支持不完整

**影响**:
- 文档无法正常渲染
- 某些端点不可见
- 交互式测试失败

**检测方法**:
```bash
# 1. 验证规范版本
jq '.openapi' openapi.json
# 期望: "3.0.2" 或 "3.1.0"

# 2. Scalar 验证
npx @scalar/cli validate openapi.json --strict

# 3. 检查不支持的特性
grep -E "oneOf|anyOf|allOf" openapi.json
```

**缓解措施**:
1. **使用 FastAPI 最新版本** (确保 OpenAPI 3.1 支持)
2. **简化复杂 Schema** (避免深层嵌套的 oneOf/anyOf)
3. **回归测试**:
   ```python
   # tests/test_openapi_compatibility.py
   import requests

   def test_scalar_can_parse_spec():
       spec = requests.get("http://localhost:8000/openapi.json").json()

       # 检查必需字段
       assert "openapi" in spec
       assert "info" in spec
       assert "paths" in spec

       # 检查端点数量
       assert len(spec["paths"]) == 6
   ```

---

### 风险 2: 性能下降（Gateway 开销）🟡

**场景**: Scalar Gateway 增加每个请求的延迟

**影响**:
- 用户体验下降
- 高并发场景 QPS 降低
- 成本增加（更多服务器资源）

**基准测试**:
```bash
# 直连 API
ab -n 100 -c 10 -p request.json -T application/json \
   http://localhost:8000/api/v1/ask

# 通过 Gateway
ab -n 100 -c 10 -p request.json -T application/json \
   http://localhost:7999/api/v1/ask

# 对比结果
```

**预期开销**:
- Gateway 延迟: +50-200ms
- 吞吐量下降: 10-20%

**缓解措施**:
1. **直连模式（生产环境）**:
   ```yaml
   # 前端直接调用 FastAPI，只用 Scalar 做文档
   services:
     scalar:
       environment:
         - SCALAR_PROXY_ENABLED=false  # 禁用代理
   ```

2. **缓存优化**:
   ```python
   # Gateway 层缓存
   # .scalar/gateway-config.yml
   cache:
     enabled: true
     ttl: 300  # 5分钟缓存
     patterns:
       - /api/v1/health
       - /api/v1/hybrid-search  # GET only
   ```

3. **CDN 加速**（生产）:
   ```
   用户 → Cloudflare → Scalar Gateway → FastAPI
   ```

---

### 风险 3: SSE 流式传输问题 🟠

**场景**: Scalar Gateway 不正确处理 Server-Sent Events

**影响**:
- `/stream` 端点完全失效
- 前端收到不完整数据
- Gradio 界面损坏

**测试方法**:
```python
# tests/test_sse_through_gateway.py
import httpx

async def test_sse_streaming():
    async with httpx.AsyncClient() as client:
        async with client.stream(
            "POST",
            "http://localhost:7999/api/v1/stream",
            json={"query": "test", "top_k": 1},
            timeout=30.0
        ) as response:
            chunks = []
            async for line in response.aiter_lines():
                if line.startswith("data: "):
                    chunks.append(line[6:])

            # 验证
            assert len(chunks) > 0, "No SSE chunks received"
            assert any("done" in c for c in chunks), "No done signal"
```

**常见问题**:
- Nginx 缓冲导致延迟
- Gateway 超时配置不足
- Content-Type 不匹配

**缓解措施**:
1. **Nginx 配置优化**:
   ```nginx
   location /api/v1/stream {
       proxy_pass http://scalar_gateway;

       # 关键: 禁用缓冲
       proxy_buffering off;
       proxy_cache off;

       # SSE 专用设置
       proxy_set_header Connection '';
       proxy_http_version 1.1;
       chunked_transfer_encoding off;

       # 超时
       proxy_read_timeout 300s;
   }
   ```

2. **降级方案**:
   ```javascript
   // 前端代码
   const USE_GATEWAY = false;  // 流式请求直连 API

   const streamUrl = USE_GATEWAY
     ? "http://gateway:7999/api/v1/stream"
     : "http://api:8000/api/v1/stream";
   ```

3. **WebSocket 替代**（未来）:
   ```python
   # src/routers/ws.py (可选)
   from fastapi import WebSocket

   @app.websocket("/ws/stream")
   async def websocket_stream(websocket: WebSocket):
       await websocket.accept()
       # WebSocket 更可靠
   ```

---

### 风险 4: API 破坏性变更 🟡

**场景**: 迁移过程中意外修改了现有 API 行为

**影响**:
- Gradio 界面损坏
- Telegram Bot 失效
- 现有客户端中断

**检测方法**:
```python
# tests/test_api_contract.py
import pytest
import httpx

@pytest.mark.parametrize("endpoint,expected_fields", [
    ("/api/v1/ask", ["query", "answer", "sources", "chunks_used"]),
    ("/api/v1/ask-agentic", ["reasoning_steps", "retrieval_attempts", "trace_id"]),
])
async def test_response_schema_unchanged(endpoint, expected_fields):
    """确保响应格式不变"""
    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"http://localhost:8000{endpoint}",
            json={"query": "test", "top_k": 1}
        )
        data = response.json()

        for field in expected_fields:
            assert field in data, f"Missing field: {field}"
```

**缓解措施**:
1. **API 版本化**:
   ```python
   # 保留 v1，新功能放 v2
   app.include_router(ask_router, prefix="/api/v1")
   app.include_router(ask_router_v2, prefix="/api/v2")
   ```

2. **弃用策略**:
   ```python
   from fastapi import status

   @router.post(
       "/ask",
       deprecated=True,  # 标记为弃用
       description="⚠️ Deprecated: Use /ask-agentic instead. Will be removed in v2.0"
   )
   ```

3. **Contract Testing**:
   ```bash
   # 使用 Pact 或 Dredd
   npm install -g dredd
   dredd openapi.json http://localhost:8000
   ```

---

### 风险 5: 安全漏洞（API Key 泄露）🟠

**场景**: API Key 在 OpenAPI 文档中暴露或日志泄露

**影响**:
- 未授权访问
- 成本失控（滥用）
- 数据泄露

**脆弱点**:
```python
# ❌ 危险: API Key 在示例中
class AskRequest(BaseModel):
    api_key: str = Field(..., example="sk-1234567890abcdef")  # 不要这样做!
```

**缓解措施**:
1. **环境变量管理**:
   ```python
   # .env (不提交到 Git)
   SCALAR_API_KEY=sk-prod-xxxxxxxxxxxx
   VALID_API_KEYS=sk-dev-abc123,sk-test-def456

   # .gitignore
   .env
   .env.local
   *.key
   ```

2. **文档脱敏**:
   ```python
   class AskRequest(BaseModel):
       # ✅ 正确: 使用占位符
       api_key: str = Field(
           ...,
           example="sk-xxxxxxxxxxxxxxxx",
           description="Your API key (get from /admin/keys)"
       )
   ```

3. **审计日志**:
   ```python
   # src/middlewares.py
   from fastapi import Request
   import logging

   logger = logging.getLogger("audit")

   @app.middleware("http")
   async def audit_middleware(request: Request, call_next):
       # 记录 API 调用（不记录完整 key）
       api_key_hash = hashlib.sha256(
           request.headers.get("Authorization", "").encode()
       ).hexdigest()[:8]

       logger.info(f"API call: {request.url.path} | key_hash: {api_key_hash}")

       response = await call_next(request)
       return response
   ```

4. **密钥轮换**:
   ```bash
   # 每月自动轮换
   # scripts/rotate_api_keys.sh
   #!/bin/bash

   NEW_KEY="sk-$(openssl rand -hex 16)"
   echo "SCALAR_API_KEY=$NEW_KEY" >> .env.new

   # 通知用户
   curl -X POST https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
     -d "chat_id=$ADMIN_ID" \
     -d "text=API key rotated. New key: $NEW_KEY"
   ```

---

### 风险 6: Docker 镜像大小增加 🟢

**场景**: 添加 Scalar 服务后总镜像大小 +500MB

**影响**:
- 构建时间增加
- 带宽消耗
- 存储成本

**当前状态**:
```bash
docker images | grep arxiv
# arxiv-api: ~1.2GB
# 预期增加: scalar (~200MB), gateway (~150MB)
```

**缓解措施**:
1. **使用轻量级镜像**:
   ```yaml
   scalar:
     image: scalar/scalar-api-reference:alpine  # 使用 Alpine 版本
   ```

2. **分离部署**（生产）:
   ```yaml
   # docker-compose.prod.yml (只部署核心服务)
   services:
     api:
       ...
     opensearch:
       ...
     # 不包含 scalar (部署到 CDN)
   ```

---

### 风险 7: 维护成本增加 🟡

**场景**: 需要维护额外的 Scalar 服务和配置

**影响**:
- DevOps 工作量增加
- 更多故障点
- 文档同步复杂

**时间成本估算**:
- 初始设置: 2-3 天
- 月度维护: 2-4 小时
- 版本升级: 1 天/季度

**缓解措施**:
1. **自动化部署**:
   ```bash
   # Makefile
   .PHONY: deploy-scalar
   deploy-scalar:
   	@echo "Updating Scalar documentation..."
   	curl http://localhost:8000/openapi.json > openapi.json
   	npx @scalar/cli validate openapi.json
   	docker compose up -d --force-recreate scalar
   	@echo "✓ Scalar updated"

   # CI/CD 集成
   # .github/workflows/deploy.yml
   - name: Update API Documentation
     run: make deploy-scalar
   ```

2. **监控告警**:
   ```yaml
   # Prometheus + Alertmanager
   - alert: ScalarUIDown
     expr: up{job="scalar"} == 0
     for: 5m
     annotations:
       summary: "Scalar UI is down"
   ```

---

### 风险 8: 团队学习曲线 🟢

**场景**: 团队成员不熟悉 Scalar 平台

**影响**:
- 迁移进度延迟
- 配置错误
- 功能未充分利用

**缓解措施**:
1. **内部培训**:
   - Week 1: Scalar 基础（1 小时）
   - Week 2: OpenAPI 最佳实践（2 小时）
   - Week 3: 实战演练（3 小时）

2. **文档资源**:
   - Scalar 官方文档: https://docs.scalar.com
   - 内部 Wiki: 常见问题和解决方案
   - 视频教程录制

---

## 📅 时间线和里程碑

### Gantt 图

```
Week 1: 准备和评估
├─ OpenAPI 规范审计         [██████] 完成
├─ 差距分析                 [██████] 完成
└─ 环境准备                 [████  ] 进行中

Week 2: 规范增强
├─ 添加 Scalar 元数据       [      ]
├─ 修复 SSE 定义            [      ]
└─ 增强 Schema Examples     [      ]

Week 3: 集成部署
├─ Docker Compose 配置      [      ]
├─ Scalar UI 部署           [      ]
└─ Gateway 配置             [      ]

Week 4: 高级功能
├─ API 版本管理             [      ]
├─ Mock Server              [      ]
└─ 安全认证                 [      ]

Week 5: 测试优化
├─ 端到端测试               [      ]
├─ 性能测试                 [      ]
└─ 文档质量检查             [      ]

Week 6: 上线准备
├─ 生产环境配置             [      ]
├─ 团队培训                 [      ]
└─ 监控告警                 [      ]
```

---

## ✅ 验收标准

### 技术验收

- [ ] OpenAPI 规范通过 Scalar 验证（0 errors）
- [ ] 所有 6 个端点在 Scalar UI 可见且可测试
- [ ] SSE 流式传输正常工作
- [ ] Mock Server 返回正确响应
- [ ] API Gateway 延迟 < 300ms
- [ ] 负载测试通过（50 并发，成功率 > 99%）
- [ ] 安全扫描无高危漏洞

### 文档验收

- [ ] 每个端点都有完整描述
- [ ] 至少 2 个 request examples
- [ ] 错误响应完整定义
- [ ] 认证方式清晰说明
- [ ] 代码示例（curl + Python）

### 用户验收

- [ ] 开发者可在 5 分钟内完成首次调用
- [ ] UI 响应式设计（移动端友好）
- [ ] 搜索功能正常
- [ ] 代码生成器可用

---

## 🎯 推荐决策

### 短期（1-2 个月）

**采用方案 A: Scalar 本地自托管**

**理由**:
1. ✅ 零成本快速验证
2. ✅ 完全控制和隐私
3. ✅ 与现有 Docker Compose 无缝集成
4. ✅ 降低风险（可随时回滚）

**实施重点**:
- 优先修复 `/stream` 端点的 OpenAPI 定义
- 充分测试 SSE 流式传输
- 建立自动化部署流程

---

### 长期（6-12 个月）

**评估方案 B: Scalar Cloud SaaS**

**前提条件**:
1. 用户基数增长（> 100 活跃开发者）
2. 需要团队协作功能
3. 预算允许（$49-199/月）

**迁移路径**:
- 保留本地环境用于开发
- 公开文档托管在 Scalar Cloud
- API 通过 Cloudflare Tunnel 暴露

---

## 📚 参考资源

### 官方文档
- Scalar: https://docs.scalar.com
- FastAPI OpenAPI: https://fastapi.tiangolo.com/advanced/extending-openapi/
- OpenAPI 3.1 Spec: https://spec.openapis.org/oas/v3.1.0

### 社区资源
- Scalar GitHub: https://github.com/scalar/scalar
- FastAPI + Scalar 集成示例: https://github.com/scalar/examples

### 内部文档
- [API_DOCUMENTATION.md](API_DOCUMENTATION.md) - 完整 API 规范
- [CLAUDE.md](CLAUDE.md) - 项目架构指南
- Week 7 Blog: https://jamwithai.substack.com/p/agentic-rag-with-langgraph-and-telegram

---

## 📞 支持和协作

### 迁移团队

| 角色 | 职责 | 联系方式 |
|------|------|---------|
| **技术负责人** | 整体架构和决策 | - |
| **后端工程师** | OpenAPI 规范优化 | - |
| **DevOps** | Docker 和部署 | - |
| **前端工程师** | Gradio 集成测试 | - |
| **QA** | 测试和验证 | - |

### 沟通渠道

- 每周同步会议: 周三 10:00 AM
- Slack 频道: #scalar-migration
- 问题追踪: GitHub Issues (tag: scalar-migration)

---

**最后更新**: 2025-12-07
**版本**: 1.0
**状态**: Draft - 待审核
