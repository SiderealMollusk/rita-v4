# 0016 - Adding Transcription to Nextcloud Talk Calls (Environment-Specific)
Date: 2026-03-05
Status: Completed

## Goal
Research practical ways to add transcription to Nextcloud Talk calls, with a path tailored to the current `cloud.virgil.info` deployment.

## Current environment snapshot
1. Nextcloud version: `32.0.6` (`occ status` and repo vars).
2. Talk app enabled: `spreed 22.0.9`.
3. AppAPI enabled: `app_api 32.0.0`.
4. HPB signaling is configured (`signaling_servers` present and active).
5. No Talk recording backend configured (`recording_servers` unset).

## Transcription modes in Nextcloud Talk

### Mode A: Live in-call transcription (real-time captions)
Primary path: `live_transcription` app.

What docs say:
1. `live_transcription` provides live speech transcription in Talk calls.
2. Requires Talk + HPB configured + AppAPI deploy daemon.
3. Requires environment variables during deploy:
- `LT_HPB_URL` (websocket endpoint, typically `/standalone-signaling/spreed`)
- `LT_INTERNAL_SECRET`

Environment-specific mapping:
1. Your likely `LT_HPB_URL` value:
- `wss://cloud.virgil.info/standalone-signaling/spreed`
2. `LT_INTERNAL_SECRET` must match HPB internal secret used by your Talk runtime (from HPB runtime config on talk backend host).

Version note:
1. App Store shows `live_transcription` release track for Nextcloud `32` (`1.3.0`) and `33` (`2.0.0`).
2. Current admin docs also mention HPB recency expectations ("latest or released after September 2025").
3. Practical implication: verify HPB build recency before rollout.

### Mode B: Recorded-call transcription (not live captions)
This is a separate chain:
1. recording backend for Talk calls
2. speech-to-text provider app
3. Talk setting to enable call recording transcription

What docs show:
1. Talk recording backend is optional but required for server-side recording workflows.
2. `stt_whisper2` is the current local Whisper STT provider app (AppAPI ExApp).
3. `stt_whisper2` docs explicitly state: it currently does not support live transcription.
4. Historical whisper provider docs show enabling Talk call recording transcription via:
- `occ config:app:set spreed call_recording_transcription --value yes`

Practical meaning:
1. If you want post-call transcript artifacts, build recording backend + STT provider chain.
2. If you want live captions inside calls, prioritize Mode A (`live_transcription`).

## Recommended path for your setup

### Phase 1 (fastest user value): Live captions first
1. Keep existing HPB path (`cloud.virgil.info/standalone-signaling`).
2. Validate HPB version recency and health.
3. Deploy `live_transcription` via AppAPI deploy options with:
- `LT_HPB_URL=wss://cloud.virgil.info/standalone-signaling/spreed`
- `LT_INTERNAL_SECRET=<hpb-internal-secret>`
4. Run a two-user call test and validate real-time captions.

### Phase 2 (optional): Recorded-call transcripts
1. Add Talk recording backend service.
2. Configure recording backend in Talk admin settings.
3. Deploy local STT provider (`stt_whisper2`) and size CPU/GPU appropriately.
4. Enable `call_recording_transcription` setting and validate end-to-end output.

## Deep dive: two custom architectures you asked for

### Option 1 (recommended): Dedicated recording/transcriber service you control
This is the strongest fit if you want data ownership and a clean integration surface.

How it works (Talk-native):
1. Talk recording is started for a room (`/recording/{token}`).
2. Your recording backend captures call media.
3. Your backend uploads recording artifacts back to Nextcloud via `POST /recording/{token}/store` (signed headers).
4. Your pipeline transcribes and publishes transcript where you want (Talk message, Nextcloud file, external system).

Why this fits your goal:
1. You control where audio lands and how long it is retained.
2. You can fan out to local STT stack (`stt_whisper2`, faster-whisper, WhisperX, etc.).
3. You can add policy gates (PII redaction, retention windows, per-room rules).

Artifacts produced:
1. Media file on your recording backend disk first.
2. Optional uploaded recording file in Nextcloud Files/Talk context.
3. Transcript artifact in your chosen sink (markdown/txt/json/vtt), plus optional Talk post.

Implementation shape in your environment:
1. Keep HPB/signaling as-is (`cloud.virgil.info/standalone-signaling` already working).
2. Add recording backend service on a host you control (prefer GPU-capable node if doing near-real-time STT).
3. Configure Talk `recording_servers` with shared secret.
4. Add a post-record hook:
   - official server: extend or sidecar workflow around recorded output
   - community `talked`: use `finalise_recording_script` to push into your transcription pipeline
5. In pipeline: transcribe -> chunk/summarize -> write back to Nextcloud via WebDAV/OCS.

Security controls:
1. Restrict recording backend ingress to Nextcloud host/IP only.
2. Validate `TALK_RECORDING_RANDOM` + `TALK_RECORDING_CHECKSUM` on all callback/store requests.
3. Encrypt storage at rest for temporary media buffers.
4. Keep strict retention policy for raw audio.

### Option 2: Bot that appears as a user/participant
This can be simpler to demo but is usually less robust for production transcription.

Important constraint:
1. Official Talk Bot API/webhooks are chat-event oriented (messages/reactions), not an official raw call-media stream API.
2. So a transcription "bot user" usually means a headless web client (or browser automation) joining the call as a participant and capturing local audio output.

What this looks like:
1. Create dedicated Nextcloud user (e.g., `transcriber-bot`).
2. Bot joins call from a headless browser session.
3. Bot captures audio locally and streams to your STT service.
4. Bot posts transcript snippets into Talk or writes to docs.

Tradeoffs:
1. Pros: quick to prototype, no deep changes to recording backend path.
2. Cons: brittle UI automation, harder concurrency, bot visibly joins calls, more breakage on UI updates.

Where this is still useful:
1. Single-room or low-volume experiments.
2. Internal pilot to validate model quality/latency before building recording backend path.

## Which option to choose
1. Choose Option 1 if you want durable operations, clear security boundaries, and multi-room growth.
2. Choose Option 2 if you want a fast prototype and can tolerate fragility/limited scale.
3. Practical sequence: pilot with Option 2 for 1-2 rooms, then move to Option 1 for production.

## Direct answers to operator questions

### 1) What support/scaffolding exists for a recording backend?
You are not starting from zero. Talk provides built-in scaffolding:
1. Admin-level recording backend configuration (`recording_servers` + shared secret in Talk settings).
2. Conversation-level controls in UI for moderators (start/stop recording).
3. A defined recording API contract:
   - start: `POST /ocs/v2.php/apps/spreed/api/v1/recording/{token}`
   - stop: `DELETE /ocs/v2.php/apps/spreed/api/v1/recording/{token}`
   - upload completed recording: `POST /ocs/v2.php/apps/spreed/api/v1/recording/{token}/store`
4. Signed backend callbacks to Nextcloud:
   - `POST /ocs/v2.php/apps/spreed/api/v1/recording/backend`
   - event types: `started`, `stopped`, `failed`

Practical starting point:
1. Use official `nextcloud-talk-recording` first if you want closest-to-supported path.
2. Use `talked` if you want simpler hackable behavior and post-processing hook (`finalise_recording_script`).

### 2) What is `POST /recording/{token}` exactly?
1. It is the call-recording start command for a specific room token.
2. It requires `recording-v1` capability and moderator permissions.
3. It does not itself deliver media bytes to your app.
4. It triggers the recording backend workflow for that room call.

### 3) Cadence of updates: stream or batch?
From Talk API contract, cadence is event-driven, not media-stream API:
1. backend status notifications: `started`, `stopped`, `failed`
2. final artifact upload through `/recording/{token}/store`

Inference for design:
1. Native Talk recording integration is effectively batch/final-file oriented.
2. If you need near-live chunks, implement that inside your recording backend pipeline (custom), then optionally still store final file back to Nextcloud.

### 4) How do you turn recording on/off?
Two control planes:
1. User/moderator UI:
   - before call: \"Start recording immediately with the call\"
   - during call: top-bar menu -> \"Start recording\" / \"Stop recording\"
2. API:
   - on: `POST /recording/{token}`
   - off: `DELETE /recording/{token}`

Global prerequisite:
1. Recording must be enabled/configured by admin with a recording backend, otherwise start fails with `config` error.

### 5) Does it know who is speaking?
What is provided by built-in recording flow:
1. Recorded media is speaker-view/video+audio centric (and screen share) in Talk UX.
2. API payload includes actor for start/stop actions (who started/stopped recording), not full per-utterance speaker diarization.

Practical implication:
1. Per-speaker transcript labels are not guaranteed by Talk recording API itself.
2. If you need speaker attribution, add diarization in your STT pipeline (e.g., WhisperX/pyannote-style post-processing) or capture per-participant tracks in a custom media path.

## Low-level bit flow (where bytes move, what you get, what you write)

This section uses the official recording-server behavior as baseline.

### A) What stock Talk gives you vs what it does not
Stock Talk gives you:
1. Control-plane events and endpoints (`start`, `stop`, backend status callbacks, `store` upload endpoint).
2. Room token + actor context for recording lifecycle.

Stock Talk does not give you:
1. A built-in \"live transcript stream\" endpoint.
2. Per-utterance speaker identity labels.

### B) Byte path for official recording backend
1. Moderator triggers recording start (UI or `POST /recording/{token}`).
2. Recording server starts one browser session (Firefox/Chromium via Selenium) and joins the call as a participant.
3. Browser receives live WebRTC media from HPB/Janus (continuous RTP/WebRTC flow, not polling).
4. Local capture path on recording server:
1. audio source enters ffmpeg via PulseAudio (`-f pulse -i ...`)
2. video source enters ffmpeg via X11 capture (`-f x11grab ...`)
5. ffmpeg encodes to a local file in backend temp directory:
1. default directory: `/tmp` (configurable `backend->directory`)
2. default extensions commonly configured as:
   - audio+video: `.webm`
   - audio-only: `.ogg`
6. On stop (`DELETE /recording/{token}`), encoder finalizes container file.
7. Backend uploads final file via `POST /recording/{token}/store` (`multipart/form-data` with `file` + `owner`).
8. If upload succeeds: temporary file is removed from recording server.
9. If upload fails: file remains on recording backend disk until manual cleanup.

### C) Does your backend poll?
No, not for media.
1. Control event arrives once at start.
2. Media then flows continuously over WebRTC to recording participant.
3. Control event arrives at stop.

### D) How near-real-time works without a Talk stream API
Near-real-time is implemented inside your recording backend process:
1. keep writing the \"final\" recording file for archival/upload.
2. in parallel, branch audio to rolling chunks (e.g., 2-5s windows) using ffmpeg segmenting or pipe/stdout.
3. feed chunks to local STT worker immediately.
4. emit partial transcript updates to your target (Talk message, WebDAV file append, your DB).

So the real-time behavior is in your custom data path, while Talk still only sees start/stop/store contract.

### E) Speaker identity (who spoke) in low-level terms
1. Recording API `owner` means \"who started recording\", not \"who said this sentence\".
2. To label speakers you need diarization in your STT path (segment-by-speaker over audio timeline).
3. Optional mapping layer can try to map diarized speakers to Talk participants using metadata/timing heuristics.

### F) What you need to write (minimum custom code)
1. A chunker stage:
1. reads live audio from ffmpeg pipe or rolling segment files
2. emits short audio chunks + timestamps
2. An STT worker:
1. transcribes each chunk
2. returns partial text with time ranges
3. Optional diarization worker:
1. tags segments as speaker A/B/C
2. (optional) maps labels to participant identities
4. A sink/publisher:
1. posts incremental transcript updates (Talk/API/file)
2. writes final merged transcript artifact at call end

## Resource and hardware implications
1. `live_transcription` docs list meaningful CPU/GPU and disk requirements (models + container footprint).
2. `stt_whisper2` can run CPU or NVIDIA GPU; docs note high resource usage and limited scaling.
3. For your environment, dedicate transcription workloads to the GPU-capable machine where possible, rather than loading the Nextcloud VM.

## Risks and gotchas
1. Secret mismatch between HPB and `live_transcription` env causes silent failure/no captions.
2. Live transcription language quality varies; punctuation limits currently documented.
3. `stt_whisper2` is not live transcription; avoid assuming it enables in-call captions.
4. Recording backend introduces storage and policy obligations (retention/legal/privacy).

## Acceptance checklist
1. Talk room shows transcription controls during active call.
2. Captions appear in real time for at least two participants.
3. No recurrent HPB websocket/signaling errors in logs during captioning.
4. (If recording path enabled) recording artifact and transcript are both produced for test call.

## Sources
1. Nextcloud admin docs: Live transcription app (`live_transcription`): https://docs.nextcloud.com/server/stable/admin_manual/ai/app_live_transcription.html
2. Nextcloud app store (live_transcription version tracks incl. NC32/33): https://apps.nextcloud.com/apps/live_transcription
3. live_transcription source repo (env vars + HPB requirement): https://github.com/nextcloud/live_transcription
4. Nextcloud Talk quick install (recording backend + SIP context): https://nextcloud-talk.readthedocs.io/en/stable/quick-install/
5. Nextcloud Talk recording API/docs: https://nextcloud-talk.readthedocs.io/en/stable/recording/
6. Nextcloud admin docs: Local Whisper STT (`stt_whisper2`), limitations and requirements: https://docs.nextcloud.com/server/latest/admin_manual/ai/app_stt_whisper2.html
7. Historical local whisper provider note for Talk call recording transcription toggle (`call_recording_transcription`): https://github.com/nextcloud/stt_whisper
8. Nextcloud user manual: Talk advanced features (live transcription user-facing behavior): https://docs.nextcloud.com/server/latest/user_manual/en/talk/advanced_features.html
9. Talk recording API (`/recording/{token}`, `/recording/{token}/store`, backend callbacks): https://nextcloud-talk.readthedocs.io/en/stable/recording/
10. Official Nextcloud Talk recording server repo: https://github.com/nextcloud/nextcloud-talk-recording
11. Community recording backend (`talked`) with `finalise_recording_script`: https://github.com/MetaProvide/talked
12. Talk bots/webhooks scope (chat events/features): https://nextcloud-talk.readthedocs.io/en/stable/bots/

## Confidence
1. High confidence on architecture split (live captions vs recording transcription), prerequisites, and AppAPI/HPB dependencies.
2. Medium confidence on exact runtime sizing in your workload until tested with your call concurrency and language mix.
