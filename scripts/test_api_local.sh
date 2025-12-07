#!/bin/bash
# test_api_local.sh - 本地API测试脚本
# 测试所有API端点（不包含 Langfuse 和 Telegram）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

BASE_URL="http://localhost:8000"
FAILED_TESTS=0
PASSED_TESTS=0

# 日志函数
log() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}✅ PASS${NC} $1"
    ((PASSED_TESTS++))
}

log_fail() {
    echo -e "${RED}❌ FAIL${NC} $1"
    ((FAILED_TESTS++))
}

log_skip() {
    echo -e "${YELLOW}⏭️  SKIP${NC} $1"
}

echo ""
echo "========================================="
echo "🧪 API Integration Tests"
echo "========================================="
echo "Base URL: $BASE_URL"
echo "========================================="
echo ""

# Test 1: Health Check
log "Test 1: Health Check Endpoint"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/api/v1/health")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    log_pass "Health check returned 200"
    echo "  Response: $BODY" | python3 -m json.tool 2>/dev/null || echo "  Response: $BODY"
else
    log_fail "Health check failed (HTTP $HTTP_CODE)"
    echo "  Response: $BODY"
fi
echo ""

# Test 2: OpenAPI Spec
log "Test 2: OpenAPI Specification"
RESPONSE=$(curl -s -w "\n%{http_code}" "$BASE_URL/openapi.json")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    # Validate JSON
    if echo "$BODY" | python3 -m json.tool > /dev/null 2>&1; then
        VERSION=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['openapi'])")
        TITLE=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['info']['title'])")
        log_pass "OpenAPI spec valid (version: $VERSION, title: $TITLE)"
    else
        log_fail "Invalid JSON in OpenAPI spec"
    fi
else
    log_fail "OpenAPI spec request failed (HTTP $HTTP_CODE)"
fi
echo ""

# Test 3: Hybrid Search
log "Test 3: Hybrid Search Endpoint"
SEARCH_QUERY='{
  "query": "transformer attention mechanism",
  "size": 3,
  "use_hybrid": true,
  "min_score": 0.0
}'

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/hybrid-search/" \
    -H "Content-Type: application/json" \
    -d "$SEARCH_QUERY")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    CHUNKS=$(echo "$BODY" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['chunks']))" 2>/dev/null || echo "0")
    log_pass "Hybrid search succeeded (found $CHUNKS chunks)"
    echo "  Sample result: $(echo "$BODY" | python3 -m json.tool 2>/dev/null | head -20)"
else
    log_fail "Hybrid search failed (HTTP $HTTP_CODE)"
    echo "  Error: $BODY"
fi
echo ""

# Test 4: Basic RAG Q&A
log "Test 4: Basic RAG Q&A Endpoint"
ASK_QUERY='{
  "query": "What is attention in transformers?",
  "top_k": 3,
  "use_hybrid_search": true,
  "model": "llama3.2:1b"
}'

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/ask" \
    -H "Content-Type: application/json" \
    -d "$ASK_QUERY" \
    --max-time 120)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    ANSWER=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['answer'][:100])" 2>/dev/null || echo "")
    if [ -n "$ANSWER" ]; then
        log_pass "RAG Q&A succeeded"
        echo "  Answer preview: $ANSWER..."
    else
        log_fail "RAG Q&A returned empty answer"
    fi
else
    log_fail "RAG Q&A failed (HTTP $HTTP_CODE)"
    echo "  Error: $BODY"
fi
echo ""

# Test 5: Streaming RAG (SSE) - Basic Connection Test
log "Test 5: Streaming RAG (SSE) Endpoint"
STREAM_QUERY='{
  "query": "What is RAG?",
  "top_k": 3
}'

# Test SSE connection (first few events)
RESPONSE=$(timeout 10 curl -s -N -X POST "$BASE_URL/api/v1/stream" \
    -H "Content-Type: application/json" \
    -d "$STREAM_QUERY" | head -20)

if echo "$RESPONSE" | grep -q "data:"; then
    # Check media type
    HEADERS=$(curl -s -I -X POST "$BASE_URL/api/v1/stream" \
        -H "Content-Type: application/json" \
        -d "$STREAM_QUERY")

    if echo "$HEADERS" | grep -i "content-type" | grep -q "text/event-stream"; then
        log_pass "SSE streaming works (correct media type)"
        echo "  First events: $(echo "$RESPONSE" | head -5)"
    else
        log_fail "SSE media type incorrect"
    fi
else
    log_fail "SSE streaming failed (no events received)"
fi
echo ""

# Test 6: Agentic RAG
log "Test 6: Agentic RAG Endpoint"
AGENTIC_QUERY='{
  "query": "Explain transformers",
  "top_k": 3,
  "model": "llama3.2:1b"
}'

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/ask-agentic" \
    -H "Content-Type: application/json" \
    -d "$AGENTIC_QUERY" \
    --max-time 120)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    ANSWER=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin).get('answer', '')[:100])" 2>/dev/null || echo "")
    if [ -n "$ANSWER" ]; then
        log_pass "Agentic RAG succeeded"
        echo "  Answer preview: $ANSWER..."
    else
        log_fail "Agentic RAG returned empty answer"
    fi
else
    log_fail "Agentic RAG failed (HTTP $HTTP_CODE)"
    echo "  Error: $BODY"
fi
echo ""

# Test 7: Invalid Requests (Error Handling)
log "Test 7: Error Handling (Invalid Request)"
INVALID_QUERY='{"invalid": "data"}'

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$BASE_URL/api/v1/hybrid-search/" \
    -H "Content-Type: application/json" \
    -d "$INVALID_QUERY")
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -eq 422 ] || [ "$HTTP_CODE" -eq 400 ]; then
    log_pass "Error handling works (returned HTTP $HTTP_CODE for invalid input)"
else
    log_fail "Error handling unexpected (HTTP $HTTP_CODE)"
fi
echo ""

# Summary
echo "========================================="
echo "📊 Test Summary"
echo "========================================="
echo "Total Tests: $((PASSED_TESTS + FAILED_TESTS))"
echo "✅ Passed: $PASSED_TESTS"
echo "❌ Failed: $FAILED_TESTS"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo "========================================="
    echo "🎉 All tests PASSED!"
    echo "========================================="
    exit 0
else
    echo "========================================="
    echo "⚠️  Some tests FAILED!"
    echo "========================================="
    echo ""
    echo "Troubleshooting:"
    echo "  1. Check API logs: docker compose logs api"
    echo "  2. Verify services: docker compose ps"
    echo "  3. Check health: curl http://localhost:8000/api/v1/health"
    exit 1
fi
