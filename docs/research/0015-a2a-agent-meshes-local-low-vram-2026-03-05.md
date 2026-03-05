# 0015 - A2A Agent Meshes for Local + Low-VRAM Setups
Date: 2026-03-05
Status: Completed

## Goal
Research current A2A-style agent mesh options, with emphasis on local-only deployments and constrained VRAM.

## Executive summary
1. The most future-proof protocol choice is A2A (now Linux Foundation-governed), with MCP for tool calls.
2. For low VRAM, the winning pattern is not "many models" but "many agents, one shared local inference server".
3. A practical stack today is:
   - A2A for agent-to-agent transport
   - MCP for tool integration
   - one local model backend (Ollama, vLLM, or llama.cpp server)
   - small/quantized models (1B-4B class where possible)

## What A2A gives you (and what it does not)

### A2A strengths
1. A2A is an open interoperability protocol for agent-to-agent collaboration.
2. It is explicitly positioned as framework-agnostic and usable for remote and local agents.
3. It has concrete protocol semantics (service methods and HTTP bindings, e.g. `/message:send`).

### A2A boundaries
1. A2A standardizes agent communication, not model serving efficiency.
2. Low-VRAM success depends mostly on your inference layer (model size, quantization, concurrency, context), not on the A2A wire protocol itself.

## A2A vs MCP in a local mesh
1. A2A = agent-to-agent communication.
2. MCP = agent-to-tool/resource communication.
3. Best practice is to use both together: A2A between agents, MCP inside each agent for tools.

## Current ecosystem signals

### A2A maturity signals
1. Official docs now state A2A was donated to the Linux Foundation.
2. A2A docs position MCP as complementary, not competing.
3. BeeAI ACP has publicly announced merge direction into A2A under Linux Foundation umbrella (community signal; not a normative spec).

### Local framework compatibility signals
1. A2A docs quickstart is simple Python + Starlette/Uvicorn, making local dev straightforward.
2. AutoGen has local Ollama guidance and explicit tool-calling behavior notes.
3. CrewAI supports local Ollama model endpoints via its LLM connection layer.

## Low-VRAM mesh design patterns that actually work

### Pattern A (recommended): many agents, one model backend
1. Run many agent processes/services (A2A nodes), but point them to one shared local inference endpoint.
2. Use role/system prompts to specialize behavior instead of spinning up separate model instances.
3. Keep heavy tasks routed to one stronger model; keep routine tasks on a tiny model.

Why:
1. VRAM is consumed by model + KV cache, so duplicating model instances is expensive.
2. Centralized serving enables better batching/scheduling and easier guardrails.

### Pattern B: split by model tier
1. tiny model tier (1B-4B) for routing, classification, extraction, formatting
2. mid tier (7B-14B) for synthesis/planning
3. optional "rare-use" large model with strict concurrency caps

### Pattern C: strict context budgets per agent class
1. short-context workers for utility tasks
2. longer-context only for planner/summarizer agents
3. avoid giving every agent large context windows by default

## Engine options for low VRAM

### 1) Ollama (easy local operations)
1. Strong local UX and broad model library with very small options (e.g. 270m/1b/1.5b families listed in library).
2. Works well as OpenAI-compatible endpoint for many frameworks.

Tradeoff:
1. Less advanced serving controls than vLLM in some production scenarios.

### 2) vLLM (strong serving controls)
1. OpenAI-compatible HTTP server (`vllm serve ...`, local `localhost:8000/v1`).
2. Quantization support is broad (AWQ, GPTQ, GGUF, INT4/INT8/FP8, quantized KV cache, etc.).

Tradeoff:
1. Operational complexity is higher than minimal local servers.

### 3) llama.cpp server (very pragmatic for constrained hardware)
1. Very broad quantization support and CPU+GPU hybrid inference.
2. Lightweight OpenAI-compatible local server mode (`llama-server`).

Tradeoff:
1. Requires more manual model/runtime tuning choices.

## Practical build paths (local-first)

### Path 1: "Fastest to working" (single machine)
1. Stand up one inference endpoint (Ollama first).
2. Implement 2-3 A2A agents (router, researcher, writer) as separate services.
3. Connect all agents to the same local model endpoint.
4. Use MCP only for the tools each agent truly needs.

### Path 2: "More control" (if you already run vLLM)
1. Use vLLM as shared backend (`/v1` OpenAI-compatible).
2. Enable quantization strategy appropriate to hardware.
3. Keep one small "router" model always loaded; load larger model only for escalations.

### Path 3: "Tightest VRAM envelope"
1. Use llama.cpp server with aggressive quantized GGUFs.
2. Keep concurrency modest and context conservative.
3. Offload overflow to CPU+GPU hybrid path when needed.

## Decision matrix (for your stated constraint)
1. Lowest setup friction: Ollama-backed mesh.
2. Best throughput tuning headroom: vLLM-backed mesh.
3. Best survival on weak/older hardware: llama.cpp-backed mesh.

## Recommendations for your repo direction
1. Adopt A2A for inter-agent contracts now (future-proofing).
2. Keep MCP as tool boundary inside each agent.
3. Implement one shared inference service, not per-agent model servers.
4. Start with tiny local models for "clerical" agents; escalate only when needed.
5. Add per-agent max context/concurrency limits as first-class config.

## Sources
1. A2A official docs (Linux Foundation, local/remote agent positioning): https://a2a-protocol.org/latest/
2. A2A protocol repo README (JSON-RPC over HTTP(S), SDKs, features): https://github.com/a2aproject/A2A
3. A2A protocol definition (service methods incl. `/message:send`): https://a2a-protocol.org/latest/definitions/
4. A2A and MCP comparison (complementary roles): https://a2a-protocol.org/latest/topics/a2a-and-mcp/
5. A2A Python quickstart setup/server (`A2AStarletteApplication`): https://a2a-protocol.org/latest/tutorials/python/2-setup/ and https://a2a-protocol.org/latest/tutorials/python/5-start-server/
6. A2A samples repo (incl. security warning for untrusted external agents): https://github.com/a2aproject/a2a-samples
7. ACP merge announcement into A2A direction (community signal): https://github.com/orgs/i-am-bee/discussions/5
8. AutoGen + local Ollama (tool-calling details): https://microsoft.github.io/autogen/0.2/docs/topics/non-openai-models/local-ollama/
9. AutoGen local LiteLLM+Ollama multi-agent example with `llama3.2:1b`: https://microsoft.github.io/autogen/stable/user-guide/core-user-guide/cookbook/local-llms-ollama-litellm.html
10. CrewAI local model connection with Ollama: https://docs.crewai.com/en/learn/llm-connections
11. vLLM quantization capabilities: https://docs.vllm.ai/en/stable/features/quantization/
12. vLLM OpenAI-compatible serving: https://docs.vllm.ai/en/latest/serving/openai_compatible_server/
13. llama.cpp capabilities (quantization, CPU+GPU hybrid, local server): https://github.com/ggml-org/llama.cpp
14. Ollama model library (small model families listed): https://ollama.com/library

## Confidence
1. High confidence: protocol mechanics and official framework/server capabilities.
2. Medium confidence: "best" stack choice for your exact hardware until benchmarked under your target workload/token/context profile.
