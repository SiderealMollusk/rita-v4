# 0770 - Nextcloud Talk Transcription Research

Date: 2026-03-05
Status: Completed

## Summary
Researched how to add transcription to Nextcloud Talk calls and mapped the options to the current `cloud.virgil.info` environment.

Output:
1. [0016-nextcloud-talk-transcription-paths-2026-03-05.md](/Users/virgil/Dev/rita-v4/docs/research/0016-nextcloud-talk-transcription-paths-2026-03-05.md)

## Key outcomes
1. Separated live captioning path (`live_transcription`) from recorded-call transcription path (recording backend + STT provider).
2. Confirmed environment baseline: NC `32.0.6`, Talk + AppAPI enabled, HPB signaling configured, recording backend not configured.
3. Produced phased rollout recommendation: live captions first, recording transcription second if needed.
4. Captured concrete environment variable mapping and acceptance checklist for operator validation.
