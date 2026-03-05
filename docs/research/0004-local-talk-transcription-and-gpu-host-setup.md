# 0004 - Local Talk Transcription And GPU Host Setup
Date: 2026-03-05
Status: Active research note

## Scope
1. Define a simple local-only call transcription path for Nextcloud Talk.
2. Define a practical speech -> text -> text -> speech bot flow.
3. Define what a Debian GPU host needs when serving AI workloads for Nextcloud using Ollama and vLLM.

## Part A - Keep-it-simple local-only call transcription

### Recommended v1 (post-call, not live)
Do post-call transcription first. It is much easier to operate and debug than live in-call voice bot behavior.

Pipeline:
1. Nextcloud Talk call recording is saved.
2. A local worker picks up the new recording.
3. STT runs locally (`faster-whisper` or `whisper.cpp`).
4. Transcript is saved back into Nextcloud as `.md` or `.txt`.

Why this is the right first step:
1. no real-time latency budget
2. no media bridge complexity
3. easy retry/idempotency

### Minimal implementation shape
1. Trigger: poll or webhook-like file detection on recording directory.
2. Transcribe: `faster-whisper` model (`small` or `medium` to start).
3. Emit: write transcript to `Transcripts/<call-id>.md` in Nextcloud.
4. Optional: summarize transcript with local LLM and append summary/action items.

## Part B - Talk bot: speech -> text -> text -> speech

### Practical architecture (v1.5)
Treat Talk bot as chat-oriented orchestration and keep media processing external.

Flow:
1. Audio input from call recording/chunks.
2. STT local worker -> text segments.
3. LLM local worker (Ollama or vLLM) -> response text.
4. TTS local worker (Piper/Coqui) -> `.wav` output.
5. Bot posts text reply and uploads audio reply file into Talk.

### Important constraint
Webhook Talk bots are excellent for message/event integrations. Live audio participation inside a call is significantly harder and typically needs additional WebRTC/SFU bridge work.

Recommendation:
1. Start with transcript + text + uploaded audio file responses.
2. Defer live voice injection until later.

### Reliability controls
1. include per-call `run_id` and per-chunk sequence numbers
2. deduplicate by `(call_id, chunk_start_ms, chunk_end_ms)`
3. enforce max processing time per chunk
4. store raw transcript and model output separately for audit/replay

## Part C - Debian GPU machine setup for Nextcloud AI workloads
Assumes: you already run `ollama` and `vLLM` on a Debian host with NVIDIA GPU.

### 1) Base machine requirements
1. Debian 12 (recommended)
2. NVIDIA driver + CUDA userspace compatible with your GPU
3. Sufficient VRAM for chosen models
4. fast local SSD for model cache and temp audio
5. stable LAN reachability from Nextcloud/node workloads

### 2) Core services to install on that machine
1. `ollama` service (general local model serving)
2. `vllm` service (high-throughput OpenAI-compatible serving)
3. STT service: `faster-whisper` API worker
4. TTS service: `piper` or `coqui-tts` worker
5. Optional queue/broker: Redis (for async jobs)
6. Optional reverse proxy: Caddy or Nginx (TLS/internal routing)

### 3) Recommended API surface (single internal gateway)
Expose one internal API entrypoint for automation workers:
1. `/llm/ollama/*` -> Ollama
2. `/llm/v1/*` -> vLLM OpenAI-compatible endpoint
3. `/stt/transcribe` -> STT worker
4. `/tts/synthesize` -> TTS worker

This keeps Nextcloud-side integrations stable while backend models evolve.

### 4) GPU host hardening and ops baseline
1. bind APIs to LAN/internal interface only (no public exposure)
2. protect with auth token or mTLS
3. limit concurrent jobs per service to prevent VRAM thrash
4. pin model versions and quantizations
5. monitor GPU memory/utilization and request latency
6. set persistent model cache paths and disk quotas

### 5) Integration with your Nextcloud platform
1. Use a dedicated Nextcloud automation account + app password for file writes.
2. Run orchestration in `n8n` or a worker service:
   - detect recording
   - call STT endpoint
   - call LLM endpoint
   - call TTS endpoint
   - write outputs back to Nextcloud
3. Keep outputs in deterministic paths:
   - `Transcripts/<call-id>.md`
   - `Summaries/<call-id>.md`
   - `AudioReplies/<call-id>.wav`

### 6) What you need installed/configured on Debian (checklist)
1. NVIDIA driver validated (`nvidia-smi` healthy)
2. CUDA runtime compatible with your Ollama/vLLM builds
3. Python runtime + virtualenv tooling for STT/TTS workers
4. FFmpeg (audio decode/resample)
5. systemd units for each worker (`Restart=always`)
6. centralized logs (`journald` or Loki/promtail)
7. firewall rules for internal-only API ports
8. backup plan for prompts/configs (not model blobs)

## Rollout plan (minimal risk)
1. Phase 1: post-call transcription only
2. Phase 2: add summary generation
3. Phase 3: add TTS audio reply files
4. Phase 4: evaluate live call voice path only if prior phases are stable

## Success criteria
1. >95% recordings get transcript within SLA window
2. deterministic file outputs in Nextcloud
3. no public exposure of AI endpoints
4. bounded GPU memory usage under peak load
