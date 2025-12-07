#!/bin/bash
# Complete test suite for Scalar migration

set -e

echo "🧪 Running Complete Test Suite"
echo "==============================="

FAILED_TESTS=0

# Test 1: OpenAPI Validation
echo ""
echo "Test 1: OpenAPI Validation"
if [ -f "scripts/validate_openapi.sh" ]; then
    bash scripts/validate_openapi.sh > /dev/null 2>&1 && echo "  ✅ PASSED" || {
        echo "  ❌ FAILED"
        ((FAILED_TESTS++))
    }
else
    echo "  ⏭️  SKIPPED (script not found)"
fi

# Test 2: Acceptance Tests
echo ""
echo "Test 2: Acceptance Tests"
if [ -f "scripts/acceptance_test_v2.sh" ]; then
    bash scripts/acceptance_test_v2.sh > /dev/null 2>&1 && echo "  ✅ PASSED" || {
        echo "  ❌ FAILED"
        ((FAILED_TESTS++))
    }
else
    echo "  ⏭️  SKIPPED (script not found)"
fi

# Test 3: Security Audit
echo ""
echo "Test 3: Security Audit"
if [ -f "scripts/security_audit.sh" ]; then
    bash scripts/security_audit.sh > /dev/null 2>&1 && echo "  ✅ PASSED" || {
        echo "  ⚠️  WARNING (issues found)"
    }
else
    echo "  ⏭️  SKIPPED (script not found)"
fi

# Test 4: SSE Integration Tests (if API available)
echo ""
echo "Test 4: SSE Integration Tests"
if curl -f -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    if [ -f "tests/test_sse_streaming.py" ]; then
        python tests/test_sse_streaming.py > /dev/null 2>&1 && echo "  ✅ PASSED" || {
            echo "  ❌ FAILED"
            ((FAILED_TESTS++))
        }
    else
        echo "  ⏭️  SKIPPED (test not found)"
    fi
else
    echo "  ⏭️  SKIPPED (API not running)"
fi

# Test 5: Static Files Validation
echo ""
echo "Test 5: Static Files Validation"
if [ -f "static/api-docs.html" ] && grep -q "scalar/api-reference" static/api-docs.html; then
    echo "  ✅ PASSED"
else
    echo "  ❌ FAILED"
    ((FAILED_TESTS++))
fi

# Test 6: Code Standards Compliance
echo ""
echo "Test 6: Code Standards (Ruff)"
if command -v ruff &> /dev/null; then
    ruff check src/ > /dev/null 2>&1 && echo "  ✅ PASSED" || {
        echo "  ⚠️  WARNING (linting issues)"
    }
else
    echo "  ⏭️  SKIPPED (ruff not installed)"
fi

# Summary
echo ""
echo "==============================="
echo "📊 Test Summary:"
echo "  Total Failed: $FAILED_TESTS"

if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ All critical tests PASSED!"
    exit 0
else
    echo "❌ $FAILED_TESTS test(s) FAILED"
    exit 1
fi
