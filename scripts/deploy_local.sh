#!/bin/bash
# deploy_local.sh - 本地部署脚本（不包含 Langfuse 和 Telegram）
# 部署核心服务：PostgreSQL, OpenSearch, Redis, Ollama, API

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目根目录
PROJECT_ROOT="/Users/yemuyu/Documents/Yemu Yu/00 Project/13 arxiv-paper-curator"
cd "$PROJECT_ROOT"

# 日志函数
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $1${NC}"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}"
}

echo ""
echo "========================================="
echo "🚀 Local Deployment (No Langfuse/Telegram)"
echo "========================================="
echo "Project: arXiv Paper Curator"
echo "Services: PostgreSQL, OpenSearch, Redis, Ollama, API"
echo "========================================="
echo ""

# Step 1: 创建 .env 文件（禁用 Langfuse 和 Telegram）
log "Step 1: Creating .env configuration..."

cat > .env <<'ENV'
# Application Settings
DEBUG=true
ENVIRONMENT=development
APP_VERSION=0.1.0

# PostgreSQL Database
POSTGRES_DATABASE_URL=postgresql+psycopg2://rag_user:rag_password@postgres:5432/rag_db

# External Services
OPENSEARCH_HOST=http://opensearch:9200
OPENSEARCH__HOST=http://opensearch:9200
OLLAMA_HOST=http://ollama:11434

# arXiv API Configuration
ARXIV__MAX_RESULTS=15
ARXIV__BASE_URL=https://export.arxiv.org/api/query
ARXIV__PDF_CACHE_DIR=./data/arxiv_pdfs
ARXIV__RATE_LIMIT_DELAY=3.0
ARXIV__TIMEOUT_SECONDS=30
ARXIV__SEARCH_CATEGORY=cs.AI
ARXIV__DOWNLOAD_MAX_RETRIES=3
ARXIV__DOWNLOAD_RETRY_DELAY_BASE=5.0
ARXIV__MAX_CONCURRENT_DOWNLOADS=5
ARXIV__MAX_CONCURRENT_PARSING=1

# PDF Parser Configuration
PDF_PARSER__MAX_PAGES=1000
PDF_PARSER__MAX_FILE_SIZE_MB=50
PDF_PARSER__DO_OCR=false
PDF_PARSER__DO_TABLE_STRUCTURE=true

# OpenSearch Configuration
OPENSEARCH__INDEX_NAME=arxiv-papers
OPENSEARCH__CHUNK_INDEX_SUFFIX=chunks
OPENSEARCH__MAX_TEXT_SIZE=1000000
OPENSEARCH__VECTOR_DIMENSION=1024
OPENSEARCH__VECTOR_SPACE_TYPE=cosinesimil
OPENSEARCH__RRF_PIPELINE_NAME=hybrid-rrf-pipeline
OPENSEARCH__HYBRID_SEARCH_SIZE_MULTIPLIER=2

# Text Chunking
CHUNKING__CHUNK_SIZE=600
CHUNKING__OVERLAP_SIZE=100
CHUNKING__MIN_CHUNK_SIZE=100
CHUNKING__SECTION_BASED=true

# Jina AI Embeddings
JINA_API_KEY=jina_76f921c3dc204f79b88c1c50e7ac8c43rUtKsKMe5kCa-lJBmrdNlMDyxyS3

# Ollama Configuration
OLLAMA_MODEL=llama3.2:1b
OLLAMA_TIMEOUT=300

# Langfuse - DISABLED
LANGFUSE_ENABLED=false
LANGFUSE_HOST=http://localhost:3001
LANGFUSE_PUBLIC_KEY=pk-disabled
LANGFUSE_SECRET_KEY=sk-disabled
LANGFUSE_DEBUG=false

# Redis Cache
REDIS__HOST=redis
REDIS__PORT=6379
REDIS__PASSWORD=X74g/aCN5aAyMPA4PKNwww==
REDIS__DB=0
REDIS__TTL_HOURS=6

# Telegram - DISABLED
TELEGRAM__ENABLED=false
TELEGRAM__BOT_TOKEN=disabled
ENV

log_success ".env created with Langfuse and Telegram disabled"

# Step 2: 停止现有容器
log "Step 2: Stopping existing containers..."
docker compose down 2>/dev/null || true
log_success "Existing containers stopped"

# Step 3: 清理旧数据（自动跳过）
# 保留现有数据以加快部署
log "Keeping existing data (use 'docker compose down -v' to clean)"

# Step 4: 启动核心服务
log "Step 4: Starting core services (PostgreSQL, OpenSearch, Redis, Ollama)..."

docker compose up -d postgres opensearch redis ollama

log "Waiting for services to be healthy..."
sleep 10

# 检查服务健康状态
log "Checking service health..."

# PostgreSQL
for i in {1..30}; do
    if docker compose exec -T postgres pg_isready -U rag_user > /dev/null 2>&1; then
        log_success "PostgreSQL is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "PostgreSQL failed to start"
        exit 1
    fi
    sleep 2
done

# OpenSearch
for i in {1..60}; do
    if curl -f -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
        log_success "OpenSearch is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "OpenSearch failed to start"
        exit 1
    fi
    sleep 2
done

# Redis
for i in {1..30}; do
    if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        log_success "Redis is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        log_error "Redis failed to start"
        exit 1
    fi
    sleep 2
done

# Ollama
for i in {1..30}; do
    if curl -f -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        log_success "Ollama is ready"
        break
    fi
    if [ $i -eq 30 ]; then
        log_warning "Ollama not responding (may need manual pull of llama3.2:1b)"
    fi
    sleep 2
done

log_success "All core services started"

# Step 5: 拉取 Ollama 模型（如果需要）
log "Step 5: Checking Ollama models..."
if docker compose exec -T ollama ollama list | grep -q "llama3.2:1b"; then
    log_success "Model llama3.2:1b already exists"
else
    log "Pulling llama3.2:1b model (this may take a while)..."
    docker compose exec -T ollama ollama pull llama3.2:1b
    log_success "Model llama3.2:1b pulled"
fi

# Step 6: 构建并启动 API
log "Step 6: Building and starting API service..."
docker compose up -d --build api

log "Waiting for API to be healthy..."
for i in {1..60}; do
    if curl -f -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
        log_success "API is ready"
        break
    fi
    if [ $i -eq 60 ]; then
        log_error "API failed to start. Check logs: docker compose logs api"
        exit 1
    fi
    sleep 2
done

# Step 7: 验证部署
log "Step 7: Verifying deployment..."

echo ""
echo "========================================="
echo "📊 Service Status"
echo "========================================="

# PostgreSQL
if docker compose exec -T postgres pg_isready -U rag_user > /dev/null 2>&1; then
    echo "✅ PostgreSQL: Running on port 5432"
else
    echo "❌ PostgreSQL: Not running"
fi

# OpenSearch
if curl -f -s http://localhost:9200/_cluster/health > /dev/null 2>&1; then
    HEALTH=$(curl -s http://localhost:9200/_cluster/health | python3 -c "import sys, json; print(json.load(sys.stdin)['status'])")
    echo "✅ OpenSearch: Running on port 9200 (status: $HEALTH)"
else
    echo "❌ OpenSearch: Not running"
fi

# Redis
if docker compose exec -T redis redis-cli ping > /dev/null 2>&1; then
    echo "✅ Redis: Running on port 6379"
else
    echo "❌ Redis: Not running"
fi

# Ollama
if curl -f -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama: Running on port 11434"
else
    echo "⚠️  Ollama: Not responding"
fi

# API
if curl -f -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    API_HEALTH=$(curl -s http://localhost:8000/api/v1/health)
    echo "✅ API: Running on port 8000"
    echo ""
    echo "API Health Check:"
    echo "$API_HEALTH" | python3 -m json.tool 2>/dev/null || echo "$API_HEALTH"
else
    echo "❌ API: Not running"
fi

echo ""
echo "========================================="
echo "🔗 Service URLs"
echo "========================================="
echo "API Documentation:"
echo "  - Swagger UI:  http://localhost:8000/docs"
echo "  - ReDoc:       http://localhost:8000/redoc"
echo "  - OpenAPI:     http://localhost:8000/openapi.json"
echo "  - Scalar UI:   file://$(pwd)/static/api-docs.html"
echo ""
echo "Service Dashboards:"
echo "  - OpenSearch:  http://localhost:9200"
echo "  - Dashboards:  http://localhost:5601"
echo ""
echo "========================================="
echo "✅ Local Deployment Complete!"
echo "========================================="
echo ""
echo "Next Steps:"
echo "  1. Run API tests:  ./scripts/test_api_local.sh"
echo "  2. View logs:      docker compose logs -f api"
echo "  3. Stop services:  docker compose down"
echo ""
