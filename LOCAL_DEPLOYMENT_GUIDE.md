# 本地部署指南（不含 Langfuse 和 Telegram）

## 📋 前置要求

- Docker 和 Docker Compose 已安装并运行
- Python 3.12+ 已安装
- 至少 8GB 可用内存
- 至少 20GB 可用磁盘空间

---

## 🚀 快速部署步骤

### 步骤 1: 准备环境文件

`.env` 文件已通过脚本自动创建，配置如下：
- ✅ Langfuse: **DISABLED** (`LANGFUSE_ENABLED=false`)
- ✅ Telegram: **DISABLED** (`TELEGRAM__ENABLED=false`)

### 步骤 2: 启动核心服务

```bash
# 进入项目目录
cd "/Users/yemuyu/Documents/Yemu Yu/00 Project/13 arxiv-paper-curator"

# 启动核心服务（PostgreSQL, OpenSearch, Redis, Ollama）
docker compose up -d postgres opensearch redis ollama

# 等待服务健康检查通过（约 60 秒）
sleep 60
```

### 步骤 3: 验证核心服务

```bash
# 检查所有服务状态
docker compose ps

# 验证各服务
docker compose exec postgres pg_isready -U rag_user
curl http://localhost:9200/_cluster/health
docker compose exec redis redis-cli ping
curl http://localhost:11434/api/tags
```

预期输出：
- PostgreSQL: `accepting connections`
- OpenSearch: `{"status":"green",...}` 或 `{"status":"yellow",...}`
- Redis: `PONG`
- Ollama: JSON list of models

### 步骤 4: 拉取 Ollama 模型（如需要）

```bash
# 检查模型是否存在
docker compose exec ollama ollama list

# 如果没有 llama3.2:1b，拉取它（约 1-2GB）
docker compose exec ollama ollama pull llama3.2:1b
```

### 步骤 5: 构建并启动 API

```bash
# 构建并启动 API 服务
docker compose up -d --build api

# 查看 API 启动日志
docker compose logs -f api
```

等待直到看到：
```
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### 步骤 6: 验证 API 健康状态

```bash
# 健康检查
curl http://localhost:8000/api/v1/health | python3 -m json.tool
```

预期输出：
```json
{
  "status": "healthy",
  "postgres": "connected",
  "opensearch": "connected",
  "redis": "connected",
  "ollama": "connected"
}
```

---

## 🧪 运行测试

### 方式 1: 使用自动化测试脚本

```bash
# API 集成测试（7个测试用例）
./scripts/test_api_local.sh

# 单元测试
./scripts/run_unit_tests.sh
```

### 方式 2: 手动API测试

#### Test 1: Health Check
```bash
curl http://localhost:8000/api/v1/health
```

#### Test 2: OpenAPI Spec
```bash
curl http://localhost:8000/openapi.json | python3 -m json.tool | head -50
```

#### Test 3: Hybrid Search
```bash
curl -X POST http://localhost:8000/api/v1/hybrid-search/ \
  -H "Content-Type: application/json" \
  -d '{
    "query": "transformer attention mechanism",
    "size": 3,
    "use_hybrid": true
  }' | python3 -m json.tool
```

#### Test 4: Basic RAG Q&A
```bash
curl -X POST http://localhost:8000/api/v1/ask \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is attention in transformers?",
    "top_k": 3,
    "model": "llama3.2:1b"
  }' | python3 -m json.tool
```

#### Test 5: Streaming RAG (SSE)
```bash
curl -N -X POST http://localhost:8000/api/v1/stream \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is RAG?",
    "top_k": 3
  }'
```

#### Test 6: Agentic RAG
```bash
curl -X POST http://localhost:8000/api/v1/ask-agentic \
  -H "Content-Type: application/json" \
  -d '{
    "query": "Explain transformers",
    "top_k": 3,
    "model": "llama3.2:1b"
  }' | python3 -m json.tool
```

---

## 📊 访问文档和仪表板

### API 文档
- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json
- **Scalar UI**: `open static/api-docs.html`

### 服务仪表板
- **OpenSearch**: http://localhost:9200
- **OpenSearch Dashboards**: http://localhost:5601 (需启动)

---

## 🛑 停止服务

```bash
# 停止所有服务
docker compose down

# 停止并删除数据卷（慎用！）
docker compose down -v
```

---

## 🐛 故障排查

### 问题 1: API 无法连接到 OpenSearch

**症状**:
```
opensearch.exceptions.ConnectionError
```

**解决方案**:
```bash
# 检查 OpenSearch 健康状态
curl http://localhost:9200/_cluster/health

# 重启 OpenSearch
docker compose restart opensearch
docker compose logs opensearch
```

### 问题 2: Ollama 模型未找到

**症状**:
```
"error": "model 'llama3.2:1b' not found"
```

**解决方案**:
```bash
# 拉取模型
docker compose exec ollama ollama pull llama3.2:1b

# 验证模型
docker compose exec ollama ollama list
```

### 问题 3: PostgreSQL 连接失败

**症状**:
```
could not connect to server: Connection refused
```

**解决方案**:
```bash
# 检查 PostgreSQL 状态
docker compose exec postgres pg_isready

# 重启 PostgreSQL
docker compose restart postgres
docker compose logs postgres
```

### 问题 4: Redis 连接超时

**症状**:
```
redis.exceptions.ConnectionError
```

**解决方案**:
```bash
# 检查 Redis
docker compose exec redis redis-cli ping

# 重启 Redis
docker compose restart redis
```

---

## 📈 性能基准测试

运行基准测试（如果 API 可用）：
```bash
python scripts/baseline_performance.py
```

查看结果：
```bash
cat baseline_performance.json | python3 -m json.tool
```

---

## 🔍 日志查看

```bash
# 查看所有服务日志
docker compose logs

# 查看特定服务日志
docker compose logs api
docker compose logs opensearch
docker compose logs postgres

# 实时跟踪日志
docker compose logs -f api
```

---

## ✅ 验收检查清单

部署完成后，确认以下所有项目：

- [ ] PostgreSQL 健康检查通过
- [ ] OpenSearch 健康检查通过（status: green 或 yellow）
- [ ] Redis 健康检查通过
- [ ] Ollama API 响应正常
- [ ] API 健康检查返回 200
- [ ] Swagger UI 可访问
- [ ] Hybrid Search 端点工作正常
- [ ] Basic RAG Q&A 端点工作正常
- [ ] Streaming SSE 端点工作正常
- [ ] Agentic RAG 端点工作正常
- [ ] 所有自动化测试通过

---

## 📞 获取帮助

如遇问题，请查看：
1. **日志**: `docker compose logs [service_name]`
2. **服务状态**: `docker compose ps`
3. **网络连接**: `docker network inspect 13arxiv-paper-curator_rag-network`
4. **GitHub Issues**: https://github.com/Yemu-Yu/arxiv-paper-curator/issues

---

**部署完成！** 🎉

现在可以开始使用 arXiv Paper Curator API 进行学术论文检索和RAG问答了。
