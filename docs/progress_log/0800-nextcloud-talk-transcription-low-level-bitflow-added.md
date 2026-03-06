# 0800 - Nextcloud Talk Transcription Low-Level Bitflow Added

Date: 2026-03-05
Status: Completed

## Summary
Extended transcription research with a low-level media/bytes flow explanation to clarify exact handoff boundaries and implementation responsibilities.

Output:
1. [0016-nextcloud-talk-transcription-paths-2026-03-05.md](/Users/virgil/Dev/rita-v4/docs/research/0016-nextcloud-talk-transcription-paths-2026-03-05.md)

## Added detail
1. Start/stop/store control-plane vs media-plane separation.
2. Disk touchpoints on recording backend (`/tmp` default, finalize + upload + cleanup behavior).
3. ffmpeg capture path (PulseAudio + X11 capture) and typical output container extensions.
4. Why near-real-time is implemented in custom backend chunk pipeline, not Talk recording API.
5. Explicit minimal custom components required for chunked STT + optional diarization.
