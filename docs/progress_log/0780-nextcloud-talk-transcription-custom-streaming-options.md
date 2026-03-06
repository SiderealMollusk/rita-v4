# 0780 - Nextcloud Talk Transcription: Custom Streaming Options Added

Date: 2026-03-05
Status: Completed

## Summary
Expanded transcription research with two implementation architectures requested by operator:
1. dedicated recording/transcriber service controlled by operator
2. bot-like participant account path for fast prototype

Output:
1. [0016-nextcloud-talk-transcription-paths-2026-03-05.md](/Users/virgil/Dev/rita-v4/docs/research/0016-nextcloud-talk-transcription-paths-2026-03-05.md)

## What was added
1. talk-native recording pipeline flow (`/recording/{token}` + `/store`) and artifact model.
2. environment-specific implementation shape for `cloud.virgil.info`.
3. security controls for recording callback validation and retention.
4. explicit constraint that Talk bot webhooks are chat-event APIs, not raw media-stream APIs.
5. "bot appears as user" headless participant architecture and tradeoffs.
6. decision guidance on when to use each option.
