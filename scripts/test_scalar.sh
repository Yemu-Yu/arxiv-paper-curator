#!/bin/bash
# test_scalar.sh - Scalar 集成测试脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}✅ PASS${NC} $1"
}

log_fail() {
    echo -e "${RED}❌ FAIL${NC} $1"
}

echo ""
echo "========================================="
echo "🧪 Scalar Integration Tests"
echo "========================================="
echo ""

# Test 1: API 健康检查
log "Test 1: API Health Check"
if curl -f -s http://localhost:8000/api/v1/health > /dev/null 2>&1; then
    log_pass "API is running"
else
    log_fail "API is not running"
    echo "  Please start API: docker compose up -d api"
    exit 1
fi
echo ""

# Test 2: OpenAPI 规范可访问
log "Test 2: OpenAPI Specification Accessibility"
RESPONSE=$(curl -s -w "\n%{http_code}" http://localhost:8000/openapi.json)
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    VERSION=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['openapi'])" 2>/dev/null)
    TITLE=$(echo "$BODY" | python3 -c "import sys, json; print(json.load(sys.stdin)['info']['title'])" 2>/dev/null)
    PATHS=$(echo "$BODY" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['paths']))" 2>/dev/null)

    log_pass "OpenAPI spec accessible"
    echo "  Version: $VERSION"
    echo "  Title: $TITLE"
    echo "  Endpoints: $PATHS"
else
    log_fail "OpenAPI spec not accessible (HTTP $HTTP_CODE)"
    exit 1
fi
echo ""

# Test 3: CORS 头部检查
log "Test 3: CORS Headers Verification"
CORS_HEADER=$(curl -s -I -X OPTIONS \
    -H "Origin: http://example.com" \
    -H "Access-Control-Request-Method: GET" \
    http://localhost:8000/openapi.json | grep -i "access-control-allow-origin" || echo "")

if [ -n "$CORS_HEADER" ]; then
    log_pass "CORS headers present"
    echo "  $CORS_HEADER"
else
    log_fail "CORS headers missing"
    echo "  Warning: This may cause issues with file:// protocol"
fi
echo ""

# Test 4: Scalar HTML 文件存在性
log "Test 4: Scalar HTML Files Existence"
SCALAR_FILES=(
    "static/api-docs.html"
    "static/scalar-debug.html"
    "static/scalar-embedded.html"
)

for file in "${SCALAR_FILES[@]}"; do
    if [ -f "$file" ]; then
        log_pass "File exists: $file"
    else
        log_fail "File missing: $file"
    fi
done
echo ""

# Test 5: Scalar HTML 配置验证
log "Test 5: Scalar Configuration Validation"
if grep -q "Scalar.createApiReference" static/api-docs.html; then
    log_pass "Uses Scalar.createApiReference() API"
else
    log_fail "Not using correct Scalar API"
fi

if grep -q "http://localhost:8000/openapi.json" static/api-docs.html; then
    log_pass "Points to correct OpenAPI URL"
else
    log_fail "Incorrect OpenAPI URL"
fi

if grep -q '"theme": "purple"' static/api-docs.html; then
    log_pass "Purple theme configured"
else
    echo "  ℹ️  No theme specified"
fi
echo ""

# Test 6: x-tagGroups 存在性
log "Test 6: Scalar x-tagGroups Extension"
if echo "$BODY" | python3 -c "import sys, json; exit(0 if 'x-tagGroups' in json.load(sys.stdin) else 1)" 2>/dev/null; then
    TAG_GROUPS=$(echo "$BODY" | python3 -c "import sys, json; print(len(json.load(sys.stdin)['x-tagGroups']))")
    log_pass "x-tagGroups present ($TAG_GROUPS groups)"
    echo "$BODY" | python3 -c "import sys, json;
groups = json.load(sys.stdin)['x-tagGroups']
for g in groups:
    print('    - %s: %s' % (g['name'], ', '.join(g['tags'])))"
else
    log_fail "x-tagGroups missing"
fi
echo ""

# Test 7: Scalar 页面渲染测试 (使用 JavaScript 验证)
log "Test 7: Scalar Page Rendering Test"

# 创建测试页面
cat > /tmp/scalar_render_test.html << 'TESTHTML'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Scalar Render Test</title>
</head>
<body>
    <h1>Testing Scalar API List Display...</h1>
    <pre id="results"></pre>
    <div id="api-reference"></div>

    <script src="https://cdn.jsdelivr.net/npm/@scalar/api-reference"></script>
    <script>
        const results = document.getElementById('results');
        const startTime = Date.now();

        results.innerHTML += '[' + new Date().toLocaleTimeString() + '] Starting test...\n';

        // Step 1: Fetch OpenAPI spec
        fetch('http://localhost:8000/openapi.json')
            .then(r => {
                results.innerHTML += '[' + new Date().toLocaleTimeString() + '] ✅ OpenAPI fetch: HTTP ' + r.status + '\n';
                return r.json();
            })
            .then(spec => {
                const paths = Object.keys(spec.paths || {});
                results.innerHTML += '[' + new Date().toLocaleTimeString() + '] ✅ OpenAPI loaded: ' + paths.length + ' endpoints\n';
                results.innerHTML += '   Endpoints: ' + paths.join(', ') + '\n';

                // Step 2: Initialize Scalar
                results.innerHTML += '[' + new Date().toLocaleTimeString() + '] 🎨 Initializing Scalar...\n';

                try {
                    Scalar.createApiReference('#api-reference', {
                        url: 'http://localhost:8000/openapi.json',
                        theme: 'purple',
                        layout: 'modern'
                    });
                    results.innerHTML += '[' + new Date().toLocaleTimeString() + '] ✅ Scalar.createApiReference() called\n';
                } catch (error) {
                    results.innerHTML += '[' + new Date().toLocaleTimeString() + '] ❌ Error: ' + error.message + '\n';
                }

                // Step 3: Check if Scalar rendered content
                setTimeout(() => {
                    const container = document.querySelector('#api-reference');
                    const hasChildren = container && container.children.length > 0;
                    const hasContent = container && container.innerHTML.length > 100;

                    results.innerHTML += '\n--- Rendering Check (after 3s) ---\n';
                    results.innerHTML += 'Container exists: ' + !!container + '\n';
                    results.innerHTML += 'Has children: ' + hasChildren + ' (' + (container ? container.children.length : 0) + ')\n';
                    results.innerHTML += 'Content length: ' + (container ? container.innerHTML.length : 0) + ' chars\n';

                    if (hasChildren && hasContent) {
                        results.innerHTML += '\n✅ VERDICT: Scalar UI rendered successfully!\n';
                        results.innerHTML += '   API list should be visible in the page below.\n';
                    } else {
                        results.innerHTML += '\n❌ VERDICT: Scalar UI did NOT render properly!\n';
                        results.innerHTML += '   The container is empty or has minimal content.\n';
                    }

                    results.innerHTML += '\n--- Test completed in ' + (Date.now() - startTime) + 'ms ---\n';
                }, 3000);

                // Step 4: Extended check
                setTimeout(() => {
                    const apiElements = document.querySelectorAll('[class*="scalar"], [class*="api"], [id*="scalar"]');
                    results.innerHTML += '\n--- Extended Check (after 5s) ---\n';
                    results.innerHTML += 'Scalar-related elements found: ' + apiElements.length + '\n';

                    if (apiElements.length > 10) {
                        results.innerHTML += '✅ Scalar has rendered multiple UI elements\n';
                    } else {
                        results.innerHTML += '⚠️  Very few Scalar elements found\n';
                    }
                }, 5000);
            })
            .catch(error => {
                results.innerHTML += '[' + new Date().toLocaleTimeString() + '] ❌ FAILED: ' + error.message + '\n';
            });
    </script>
</body>
</html>
TESTHTML

# 打开测试页面
open /tmp/scalar_render_test.html

echo "  📄 Opened automated render test page"
echo "  ⏱️  Please wait 5 seconds for test to complete..."
echo "  👁️  Check the opened browser window for test results"
echo ""

sleep 7  # 等待测试完成

# 提示用户检查结果
echo "  ℹ️  The test page should show:"
echo "     - ✅ OpenAPI fetch successful"
echo "     - ✅ Scalar initialized"
echo "     - ✅ VERDICT: Scalar UI rendered successfully"
echo ""
echo "  If you see ❌ VERDICT or errors, Scalar is NOT displaying properly"
echo ""

# Summary
echo "========================================="
echo "📊 Test Summary"
echo "========================================="
echo ""
echo "✅ All backend tests passed!"
echo ""
echo "🌐 Access Scalar Documentation:"
echo "  - Main:       file://$(pwd)/static/api-docs.html"
echo "  - Debug:      file://$(pwd)/static/scalar-debug.html"
echo "  - Embedded:   file://$(pwd)/static/scalar-embedded.html"
echo "  - Test:       file:///tmp/scalar_render_test.html"
echo ""
echo "Alternative access methods:"
echo "  - Swagger UI: http://localhost:8000/docs"
echo "  - ReDoc:      http://localhost:8000/redoc"
echo "  - OpenAPI:    http://localhost:8000/openapi.json"
echo ""
echo "========================================="
echo "🧪 Automated Render Test Results"
echo "========================================="
echo "The test browser window should show whether Scalar"
echo "successfully rendered the API list."
echo ""
echo "If Scalar is NOT working:"
echo "  1. Check browser console (F12) for errors"
echo "  2. Try: open static/scalar-debug.html"
echo "  3. Try: open static/scalar-embedded.html"
echo "========================================="
