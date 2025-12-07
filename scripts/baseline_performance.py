#!/usr/bin/env python3
"""Performance baseline test for API before Scalar migration"""

import asyncio
import time
import statistics
from typing import List, Dict
import httpx
import json

BASE_URL = "http://localhost:8000"

async def test_endpoint_latency(endpoint: str, method: str = "GET", json_data: dict = None) -> float:
    async with httpx.AsyncClient(timeout=30.0) as client:
        start = time.time()
        if method == "GET":
            response = await client.get(f"{BASE_URL}{endpoint}")
        else:
            response = await client.post(f"{BASE_URL}{endpoint}", json=json_data)
        latency = time.time() - start
        if response.status_code != 200:
            raise Exception(f"Request failed: {response.status_code}")
        return latency

async def benchmark_endpoint(endpoint: str, method: str = "GET", json_data: dict = None, iterations: int = 10) -> Dict:
    latencies = []
    for i in range(iterations):
        try:
            latency = await test_endpoint_latency(endpoint, method, json_data)
            latencies.append(latency)
            await asyncio.sleep(0.5)
        except Exception as e:
            print(f"  ❌ Iteration {i+1} failed: {e}")

    if not latencies:
        return {"error": "All requests failed"}

    return {
        "endpoint": endpoint,
        "method": method,
        "iterations": len(latencies),
        "min": min(latencies),
        "max": max(latencies),
        "mean": statistics.mean(latencies),
        "median": statistics.median(latencies),
        "stdev": statistics.stdev(latencies) if len(latencies) > 1 else 0,
        "p95": sorted(latencies)[int(len(latencies) * 0.95)] if len(latencies) > 1 else latencies[0],
    }

async def main():
    print("🚀 Starting Performance Baseline Test...")
    print("=" * 60)

    test_cases = [
        {"name": "Health Check", "endpoint": "/api/v1/health", "method": "GET"},
        {"name": "OpenAPI Spec", "endpoint": "/openapi.json", "method": "GET"},
        {"name": "Hybrid Search", "endpoint": "/api/v1/hybrid-search/", "method": "POST",
         "json": {"query": "transformer architecture", "size": 5, "use_hybrid": True}},
    ]

    results = []
    for test in test_cases:
        print(f"\n📊 Testing: {test['name']}")
        print(f"   Endpoint: {test['method']} {test['endpoint']}")
        result = await benchmark_endpoint(endpoint=test['endpoint'], method=test['method'],
                                         json_data=test.get('json'), iterations=10)
        if "error" not in result:
            print(f"   ✅ Mean: {result['mean']*1000:.0f}ms | P95: {result['p95']*1000:.0f}ms")
        results.append({**test, **result})

    with open("baseline_performance.json", "w") as f:
        json.dump(results, f, indent=2)

    print("\n" + "=" * 60)
    print("✅ Baseline test complete!")
    print("📁 Results saved to: baseline_performance.json")

if __name__ == "__main__":
    asyncio.run(main())
