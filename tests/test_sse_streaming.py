#!/usr/bin/env python3
"""Integration tests for SSE streaming endpoint"""

import asyncio
import json
import httpx
import pytest

BASE_URL = "http://localhost:8000"

@pytest.mark.asyncio
async def test_sse_media_type():
    """Test SSE endpoint returns correct media type"""
    async with httpx.AsyncClient(timeout=30.0) as client:
        response = await client.post(
            f"{BASE_URL}/api/v1/stream",
            json={"query": "What is RAG?", "top_k": 3}
        )

        # Check media type
        content_type = response.headers.get("content-type", "")
        assert "text/event-stream" in content_type, f"Expected text/event-stream, got {content_type}"

        # Check headers
        assert response.headers.get("cache-control") == "no-cache"
        assert response.headers.get("connection") == "keep-alive"

        print("✅ SSE media type and headers correct")

@pytest.mark.asyncio
async def test_sse_basic_flow():
    """Test basic SSE streaming flow"""
    async with httpx.AsyncClient(timeout=30.0) as client:
        chunks = []
        metadata = None

        async with client.stream(
            "POST",
            f"{BASE_URL}/api/v1/stream",
            json={"query": "What is attention mechanism?", "top_k": 3}
        ) as response:
            async for line in response.aiter_lines():
                if line.startswith("data: "):
                    data = json.loads(line[6:])

                    if "sources" in data:
                        metadata = data
                    elif "chunk" in data:
                        chunks.append(data["chunk"])
                    elif data.get("done"):
                        break

        # Validations
        assert metadata is not None, "No metadata event received"
        assert len(chunks) > 0, "No chunks received"

        print(f"✅ SSE flow complete: {len(chunks)} chunks, metadata: {metadata}")

if __name__ == "__main__":
    print("Running SSE tests...")
    asyncio.run(test_sse_media_type())
    asyncio.run(test_sse_basic_flow())
    print("✅ All SSE tests passed!")
