#!/bin/bash
# Security audit for OpenAPI spec

set -e

echo "🔒 Running Security Audit..."
echo "=============================="

# 获取 OpenAPI spec
if [ -f "openapi_v1_original.json" ]; then
    SPEC_FILE="openapi_v1_original.json"
elif curl -f -s http://localhost:8000/openapi.json > /tmp/openapi_audit.json 2>&1; then
    SPEC_FILE="/tmp/openapi_audit.json"
else
    echo "❌ No OpenAPI spec available"
    exit 1
fi

ISSUES=0

# 1. 检查硬编码敏感信息
echo ""
echo "1. Checking for hardcoded secrets..."
if grep -iE "(password|secret|api_key|token|credentials)" "$SPEC_FILE" | grep -v "description" | grep -v "apiKey" > /dev/null; then
    echo "  ⚠️  Potential hardcoded secrets found"
    ((ISSUES++))
else
    echo "  ✅ No hardcoded secrets"
fi

# 2. 检查内部 IP 泄露
echo ""
echo "2. Checking for internal IPs..."
if grep -oE '(10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)' "$SPEC_FILE" > /dev/null; then
    echo "  ⚠️  Internal IP addresses found"
    ((ISSUES++))
else
    echo "  ✅ No internal IPs"
fi

# 3. 检查示例数据中的敏感信息
echo ""
echo "3. Checking examples for sensitive data..."
if jq -r '.. | select(type == "string")' "$SPEC_FILE" 2>/dev/null | grep -iE '(test@|admin@|root@|@example\.com)' > /dev/null; then
    echo "  ⚠️  Example emails found (should use example.com)"
else
    echo "  ✅ No sensitive example data"
fi

# 4. 检查 HTTPS usage
echo ""
echo "4. Checking server URLs..."
HTTP_SERVERS=$(jq -r '.servers[]?.url' "$SPEC_FILE" 2>/dev/null | grep '^http://' | grep -v 'localhost' | grep -v '127.0.0.1' | wc -l)
if [ "$HTTP_SERVERS" -gt 0 ]; then
    echo "  ⚠️  Non-localhost HTTP servers found (should use HTTPS in production)"
    ((ISSUES++))
else
    echo "  ✅ Server URLs are safe"
fi

# 5. 检查 security schemes
echo ""
echo "5. Checking security schemes..."
if jq -e '.components.securitySchemes' "$SPEC_FILE" > /dev/null 2>&1; then
    echo "  ✅ Security schemes defined"
else
    echo "  ⚠️  No security schemes defined (OK for public API)"
fi

# Summary
echo ""
echo "=============================="
if [ $ISSUES -eq 0 ]; then
    echo "✅ Security audit passed!"
    exit 0
else
    echo "⚠️  $ISSUES security issues found (review above)"
    exit 0  # Non-blocking
fi
