# 0002 - AI And Nextcloud Collective Docs Research
Date: 2026-03-05
Status: Active research note

## Scope
Answer four practical questions for AI-assisted documentation workflows in Nextcloud:
1. Can we generate text files?
2. Is there an easy way for assistants to read/update collective docs?
3. Can we mount Nextcloud files on local systems?
4. Can terminal commands read/write files in Nextcloud?

## Short answers
1. Yes, text files can be generated in Nextcloud using the Assistant stack and/or direct file writes over WebDAV.
2. Yes, with caveats. Collectives pages are Markdown files and can be edited through Files/WebDAV, but app-native semantics (structure, metadata, page linking) are safest through the Collectives APIs.
3. Yes. Easiest is the official desktop sync client; WebDAV mounts are also supported.
4. Yes. Nextcloud officially documents cURL/WebDAV command patterns for create/upload/move/list operations.

## Findings

### 1) Generate text files in Nextcloud
Nextcloud Assistant provides text tasks including "Generate text", "Summarize", and related writing operations, but it requires backend AI apps (local or API-based) to actually process tasks.

For file creation itself, Nextcloud Text stores content as Markdown/plaintext files, so generated output can be saved as normal files in the Files layer.

Practical pattern:
1. Use Assistant (or external AI) to produce text content.
2. Persist to a target file path through Nextcloud Files (UI, WebDAV, or API).

### 2) Assistants reading/updating "collective docs"
Collectives is collaborative Markdown-based documentation tied to teams. The user docs state that Collectives pages are stored as Markdown files and are accessible via Files (default hidden `.Collectives` folder).

This gives two integration levels:
1. File-level: assistants read/write Markdown files directly over WebDAV.
2. App-level: use Collectives developer API surface (OCS API is documented in the app repo `openapi.json`) when you need to preserve higher-level collective semantics.

Recommendation for reliability:
1. Start with file-level edits for straightforward content updates.
2. Move to Collectives API operations when page tree, membership, or app-specific entities are required.

### 3) Mount Nextcloud on local systems
Official docs recommend the Nextcloud Desktop Sync client for ongoing local sync to chosen directories.

WebDAV mounting is also supported:
1. Linux file managers and command-line `davfs2` mounts.
2. macOS Finder `Connect to Server` with the WebDAV URL.
3. Windows network drive mapping.

### 4) Terminal read/write in Nextcloud
Yes. Nextcloud documents cURL/WebDAV operations for scripting:
1. `MKCOL` to create folders.
2. `PUT` upload via `curl -T`.
3. `MOVE` with destination header.
4. `PROPFIND` for listing/properties.

All of these use the WebDAV path under `/remote.php/dav/files/<user>/...` and authentication (typically app-password for integrations).

## Implementation blueprint for this repo
1. Define a dedicated Nextcloud automation account for agent writes.
2. Store credentials in existing secrets flow (same pattern as `n8n-secrets`).
3. Pick one authoritative docs root in Nextcloud (for example `Collectives/Operations`).
4. Phase 1: file-level read/write only (WebDAV + Markdown).
5. Phase 2: add Collectives OCS API usage for page-tree-aware operations.
6. Add idempotency markers in generated docs (`Updated-By`, timestamp, run-id) to prevent edit loops.

## Risks and constraints
1. Concurrent editing conflicts between humans and automated writers.
2. Collectives app updates may evolve API behavior; pin and re-validate.
3. Over-broad credentials can expose all files of the automation account.
4. Direct file edits can bypass app-level invariants if workflows become complex.

## Primary sources
1. Nextcloud Assistant (tasks/backends): https://docs.nextcloud.com/server/32/admin_manual/ai/app_assistant.html
2. Nextcloud Text app (Markdown-based files): https://github.com/nextcloud/text
3. Collectives app overview and docs links: https://nextcloud.github.io/collectives/
4. Collectives user docs (pages stored as Markdown in Files): https://nextcloud.github.io/collectives/usage/
5. Collectives developer note (`OCS API` / `openapi.json`): https://github.com/nextcloud/collectives
6. WebDAV basics (`/remote.php/dav`): https://docs.nextcloud.com/server/30/developer_manual/client_apis/WebDAV/basic.html
7. WebDAV access and mounts (Linux/macOS/Windows): https://docs.nextcloud.com/server/25/user_manual/en/files/access_webdav.html
8. Nextcloud Desktop client overview: https://docs.nextcloud.com/server/stable/user_manual/en/desktop/index.html
9. Nextcloud command-line sync client (`nextcloudcmd`): https://docs.nextcloud.com/server/stable/admin_manual/desktop/commandline.html
10. OCS header conventions: https://docs.nextcloud.com/server/stable/developer_manual/client_apis/OCS/ocs-api-overview.html
