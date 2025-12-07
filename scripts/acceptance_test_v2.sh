#!/bin/bash
# acceptance_test_v2.sh - 综合验收测试

set -e

echo "🧪 Running Comprehensive Acceptance Tests..."
echo "================================================"

FAILED_TESTS=0

# Test 1: API Health Check
echo ""
echo "Test 1: API Health Check"
if curl -f -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    echo "  ✅ PASSED"
else
    echo "  ❌ FAILED: API health check failed"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 2: OpenAPI Spec Availability
echo ""
echo "Test 2: OpenAPI Spec Availability"
if curl -f -s http://localhost:8000/openapi.json | jq . > /dev/null 2>&1; then
    echo "  ✅ PASSED"
else
    echo "  ❌ FAILED: OpenAPI spec not available"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 3: OpenAPI Required Fields
echo ""
echo "Test 3: OpenAPI Required Fields"
SPEC=$(curl -s http://localhost:8000/openapi.json)
if echo "$SPEC" | jq -e '.info.title' > /dev/null 2>&1 && \
   echo "$SPEC" | jq -e '.info.version' > /dev/null 2>&1 && \
   echo "$SPEC" | jq -e '.paths' > /dev/null 2>&1; then
    echo "  ✅ PASSED"
else
    echo "  ❌ FAILED: Missing required OpenAPI fields"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi

# Test 4: Static API Docs (if exists)
echo ""
echo "Test 4: Static API Documentation"
if [ -f "static/api-docs.html" ]; then
    if grep -q "scalar/api-reference" static/api-docs.html; then
        echo "  ✅ PASSED"
    else
        echo "  ❌ FAILED: Invalid Scalar reference in HTML"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    echo "  ⏭️  SKIPPED: static/api-docs.html not created yet"
fi

# Test 5: Baseline Performance File (if exists)
echo ""
echo "Test 5: Baseline Performance Data"
if [ -f "baseline_performance.json" ]; then
    if jq -e '.[0].mean' baseline_performance.json > /dev/null 2>&1; then
        echo "  ✅ PASSED"
    else
        echo "  ❌ FAILED: Invalid baseline performance data"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
else
    echo "  ⏭️  SKIPPED: baseline_performance.json not created yet"
fi

# Summary
echo ""
echo "================================================"
if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ All tests PASSED!"
    exit 0
else
    echo "❌ $FAILED_TESTS test(s) FAILED"
    exit 1
fi
