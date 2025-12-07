#!/bin/bash
# validate_openapi.sh - 验证 OpenAPI 规范

set -e

echo "🔍 Validating OpenAPI specification..."

# 检查 OpenAPI 文件是否存在
if [ ! -f "openapi_v1_original.json" ]; then
    echo "⚠️  Original OpenAPI spec not found, fetching from API..."
    curl -s http://localhost:8000/openapi.json | jq . > openapi_v1_original.json 2>/dev/null || {
        echo "❌ Failed to fetch OpenAPI spec from API"
        exit 1
    }
fi

# 基本 JSON 格式验证
jq . openapi_v1_original.json > /dev/null 2>&1 || {
    echo "❌ Invalid JSON format"
    exit 1
}

# 检查 OpenAPI 版本
VERSION=$(jq -r '.openapi // "unknown"' openapi_v1_original.json)
if [[ ! "$VERSION" =~ ^3\. ]]; then
    echo "❌ Invalid OpenAPI version: $VERSION (expected 3.x)"
    exit 1
fi

# 检查必需字段
REQUIRED_FIELDS=("info" "paths")
for field in "${REQUIRED_FIELDS[@]}"; do
    if ! jq -e ".$field" openapi_v1_original.json > /dev/null 2>&1; then
        echo "❌ Missing required field: $field"
        exit 1
    fi
done

# 检查 info 元数据
TITLE=$(jq -r '.info.title // "unknown"' openapi_v1_original.json)
VERSION_INFO=$(jq -r '.info.version // "unknown"' openapi_v1_original.json)

if [ "$TITLE" = "unknown" ] || [ "$VERSION_INFO" = "unknown" ]; then
    echo "❌ Missing info.title or info.version"
    exit 1
fi

# 统计端点数量
ENDPOINT_COUNT=$(jq '[.paths | to_entries[].value | to_entries[].key] | length' openapi_v1_original.json)

echo "✅ OpenAPI validation passed"
echo "   Version: $VERSION"
echo "   Title: $TITLE"
echo "   API Version: $VERSION_INFO"
echo "   Endpoints: $ENDPOINT_COUNT"

exit 0
