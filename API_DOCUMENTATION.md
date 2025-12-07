# API 文档访问指南

## 🎯 推荐文档工具

### ✅ Scalar API Reference (推荐)
**访问地址**: [file://static/api-docs.html](file://static/api-docs.html)

**特点**:
- ✅ 现代化的紫色主题界面
- ✅ 支持所有 OpenAPI 3.1.0 功能
- ✅ 交互式 API 测试
- ✅ 优雅的端点分组展示
- ✅ 使用稳定版本 v1.24.66（避免 v1.40.1 的渲染 bug）

**配置方式**:
```html
<script
    id="api-reference"
    data-url="http://localhost:8000/openapi.json"
    data-theme="purple">
</script>
<script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference@1.24.66"></script>
```

### ✅ Swagger UI
**访问地址**: http://localhost:8000/docs

**特点**:
- ✅ 完全集成在 FastAPI 中
- ✅ 交互式 API 测试
- ✅ 支持所有 OpenAPI 3.1.0 功能
- ✅ "Try it out" 直接测试端点
- ✅ 自动生成请求/响应示例

### ✅ ReDoc
**访问地址**: http://localhost:8000/redoc

**特点**:
- ✅ 优雅的三栏布局
- ✅ 响应式设计
- ✅ 代码示例自动生成
- ✅ 搜索功能

### 📄 OpenAPI JSON
**访问地址**: http://localhost:8000/openapi.json

直接访问 OpenAPI 3.1.0 规范(JSON 格式)

---

## 📊 API 端点概览

### Core Services (核心服务)

1. **Health Check** - `GET /api/v1/health`
   - 检查所有后端服务健康状态
   - 包括: PostgreSQL, OpenSearch, Ollama

2. **Hybrid Search** - `POST /api/v1/hybrid-search/`
   - BM25 关键词 + 向量相似度混合搜索
   - 使用 Jina 1024-dim 嵌入

### RAG Endpoints (RAG 端点)

3. **Basic RAG** - `POST /api/v1/ask`
   - 基础 RAG 问答
   - 同步响应

4. **Streaming RAG** - `POST /api/v1/stream`
   - 流式 RAG 响应
   - Server-Sent Events (SSE)

5. **Agentic RAG** - `POST /api/v1/ask-agentic`
   - 智能 RAG with LangGraph
   - 包含查询重写、文档评分、护栏检查

6. **Feedback** - `POST /api/v1/feedback`
   - 提交用户反馈

---

## 🔧 关于 Scalar 版本选择

**状态**: ✅ 已解决

**问题**: Scalar API Reference 最新版本 (v1.40.1) 存在 "Document not found in configList" 错误。

**解决方案**: 使用稳定版本 **v1.24.66**，该版本已验证可以正常显示 API 列表。

**技术细节**:
- v1.24.66 使用 `data-url` 属性配置（旧版 API）
- v1.40.1+ 使用 `Scalar.createApiReference()` 方法（新版 API，但有 bug）
- 建议固定使用 v1.24.66 直到新版本 bug 修复

---

## 🚀 快速开始

1. **查看 API 文档**:
   ```bash
   open http://localhost:8000/docs
   ```

2. **测试 Health Check**:
   ```bash
   curl http://localhost:8000/api/v1/health | jq .
   ```

3. **测试混合搜索**:
   ```bash
   curl -X POST http://localhost:8000/api/v1/hybrid-search/ \
     -H "Content-Type: application/json" \
     -d '{"query": "transformer architecture", "top_k": 5}'
   ```

---

**最后更新**: 2025-12-07  
**API 版本**: 0.1.0  
**OpenAPI 版本**: 3.1.0
