#!/bin/bash
# run_unit_tests.sh - 运行单元测试（不包含 Langfuse 和 Telegram 相关测试）

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_ROOT="/Users/yemuyu/Documents/Yemu Yu/00 Project/13 arxiv-paper-curator"
cd "$PROJECT_ROOT"

# 激活虚拟环境
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi

echo ""
echo "========================================="
echo "🧪 Running Unit Tests"
echo "========================================="
echo ""

# Test 1: SSE Integration Tests
echo "Test 1: SSE Streaming Integration Tests"
echo "========================================="
if [ -f "tests/test_sse_streaming.py" ]; then
    if curl -f -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
        echo "Running SSE tests..."
        python tests/test_sse_streaming.py || {
            echo -e "${RED}❌ SSE tests failed${NC}"
        }
    else
        echo -e "${YELLOW}⏭️  Skipping (API not running)${NC}"
    fi
else
    echo -e "${YELLOW}⏭️  test_sse_streaming.py not found${NC}"
fi
echo ""

# Test 2: OpenAPI Compliance Tests (if exists)
echo "Test 2: OpenAPI Compliance Tests"
echo "========================================="
if [ -f "tests/test_openapi_compliance.py" ]; then
    echo "Running OpenAPI compliance tests..."
    pytest tests/test_openapi_compliance.py -v || {
        echo -e "${RED}❌ OpenAPI tests failed${NC}"
    }
else
    echo -e "${YELLOW}⏭️  test_openapi_compliance.py not found${NC}"
fi
echo ""

# Test 3: Python Pytest Suite (excluding Langfuse/Telegram)
echo "Test 3: Core Unit Tests (pytest)"
echo "========================================="
if [ -d "tests" ]; then
    echo "Running pytest with exclusions..."
    pytest tests/ \
        -v \
        --ignore=tests/test_langfuse.py \
        --ignore=tests/test_telegram.py \
        -k "not langfuse and not telegram" \
        --tb=short \
        --maxfail=5 || {
        echo -e "${YELLOW}⚠️  Some tests failed or no tests found${NC}"
    }
else
    echo -e "${YELLOW}⏭️  tests/ directory not found${NC}"
fi
echo ""

# Test 4: Code Quality Checks
echo "Test 4: Code Quality (Ruff)"
echo "========================================="
if command -v ruff &> /dev/null; then
    echo "Running ruff checks..."
    ruff check src/ --select E,F,W,I --ignore E501 || {
        echo -e "${YELLOW}⚠️  Linting issues found${NC}"
    }
else
    echo -e "${YELLOW}⏭️  ruff not installed${NC}"
fi
echo ""

# Test 5: Type Checking (mypy)
echo "Test 5: Type Checking (mypy)"
echo "========================================="
if command -v mypy &> /dev/null; then
    echo "Running mypy type checks..."
    mypy src/ --ignore-missing-imports --no-strict-optional || {
        echo -e "${YELLOW}⚠️  Type checking issues found${NC}"
    }
else
    echo -e "${YELLOW}⏭️  mypy not installed${NC}"
fi
echo ""

echo "========================================="
echo "✅ Unit Tests Complete"
echo "========================================="
echo ""
echo "Note: Run './scripts/test_api_local.sh' for API integration tests"
