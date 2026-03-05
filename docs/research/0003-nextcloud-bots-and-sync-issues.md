# 0003 - Nextcloud Bots And Sync Issues Research
Date: 2026-03-05
Status: Active research note

## Scope
Research:
1. how bots work in Nextcloud
2. common sync failure patterns and practical solutions

## Part A - How bots work on Nextcloud

### 1) Primary bot surface today: Nextcloud Talk bots
Nextcloud Talk exposes a bot model over OCS endpoints under:
`/ocs/v2.php/apps/spreed/api/v1`

Core properties from official Talk API docs:
1. requires `bots-v1` capability (available since Nextcloud 27.1)
2. bot install is intentionally CLI-first (`occ talk:bot:*`)
3. conversation moderators can enable/disable bots per room

Operational flow:
1. Admin installs bot on server with `talk:bot:install` (name, secret, URL).
2. Moderator sets bot up in specific conversation(s) (`talk:bot:setup` or API).
3. Talk sends webhook events to bot endpoint for messages/events.
4. Bot verifies signature and can respond/reaction via Talk API.

### 2) Security model for webhook bots
Incoming bot webhooks are signed.
The bot must verify an HMAC-SHA256 over:
1. `X-Nextcloud-Talk-Random` header value
2. request body
with the shared secret configured at install time.

If signature validation fails, payloads should be rejected.

### 3) Event model and capabilities
Talk bot hooks include message events and (newer) reaction events.
Recent docs also describe:
1. `event/events` style capability for local event-driven app bots
2. `reaction` feature for added/removed reaction hooks
3. reply context fields (`object.inReplyTo`) in newer Talk versions

### 4) Nextcloud app-based bots (no external webhook round trip)
For Nextcloud app developers, Talk supports "Nextcloud apps as a bot" via event integration (`BotInvokeEvent`) and supports ExApp registration APIs for Talk bots.

Practical implication:
1. external webhook bots are easiest for service-style integrations
2. in-process app bots reduce network round-trips and can be cleaner for advanced internal automations

### 5) Assistant is AI UX, not Talk bot plumbing
Nextcloud Assistant is the AI interface across Nextcloud apps (summarize/generate/etc.).
It can coexist with Talk bots but is a separate model:
1. Assistant = user-facing AI tasks in apps
2. Talk bot = programmable chat actor/integration endpoint

## Part B - Sync issues and solutions

### 1) First diagnostics path (official order)
From Nextcloud troubleshooting docs, debug in this order:
1. verify web login works
2. verify WebDAV endpoint connectivity (`/remote.php/dav`)
3. isolate client vs server with logs/debug archive

### 2) Common sync issue patterns and fixes

#### A. "Connection closed" on uploads
Typical cause: chunk sizes/timeouts unsuitable for current network/proxy path.
Fixes:
1. tune `chunkSize`, `minChunkSize`, `maxChunkSize`, `targetChunkUploadDuration` in client config
2. re-test after reducing max chunk size in constrained proxy paths

#### B. `CSync unknown error`
Official recovery:
1. stop client
2. delete account-local `.sync_xxxxxxx.db`
3. restart client

Tradeoff: this resets some download-selection settings.

#### C. Only some files never sync
Common causes and fixes documented by Nextcloud:
1. file patterns/ignore rules: inspect Ignored Files Editor and custom patterns
2. unsupported filename/path semantics across filesystems
3. very deep trees: client intentionally limits sync depth to 100 subdirectories

#### D. Slow or delayed remote-change detection
Potential fixes:
1. enable `notify_push` server app (recommended by Virtual Files doc)
2. review local endpoint security scanners that can slow IO
3. ensure only one sync tool owns the directory (do not co-sync with Dropbox/rsync/etc.)

#### E. Linux warning: changes not tracked reliably
Cause: too few inotify watches.
Fix: raise `fs.inotify.max_user_watches`.

### 3) Conflict behavior and operator policy
When local and remote edits diverge between sync runs, client creates a local conflicted copy and keeps remote version as canonical filename.

Recommended policy:
1. treat conflict files as manual merge required
2. for automation-managed folders, reduce multi-writer concurrency and prefer append-only or lock-based patterns

### 4) Fast triage checklist
1. Is Web UI reachable and healthy?
2. Does WebDAV auth work for the same account?
3. Are many users failing (server-side) or single user only (client-side)?
4. Any reverse proxy/body-size/chunking constraints?
5. Any invalid ignore patterns or path depth >100?
6. Collect client debug archive + server logs before changing too many variables.

## Recommendations for this repo
1. For bot work, start with webhook Talk bot + strict signature verification + per-room enablement.
2. Keep bot secret in the same secret-management pattern as other platform apps.
3. For doc/automation syncing, reserve one Nextcloud path for automation outputs and avoid multi-tool co-sync.
4. Add a runbook section for sync incident triage using the checklist above.

## Primary sources
1. Talk bots and webhooks: https://nextcloud-talk.readthedocs.io/en/stable/bots/
2. Talk bot management API: https://nextcloud-talk.readthedocs.io/en/stable/bot-management/
3. Talk OCC bot commands: https://nextcloud-talk.readthedocs.io/en/stable/occ/
4. Nextcloud ExApp Talk bot API: https://docs.nextcloud.com/server/latest/developer_manual/exapp_development/tech_details/api/talkbots.html
5. Nextcloud Assistant admin docs: https://docs.nextcloud.com/server/29/admin_manual/ai/app_assistant.html
6. Desktop sync troubleshooting: https://docs.nextcloud.com/server/stable/admin_manual/desktop/troubleshooting.html
7. Desktop conflicts: https://docs.nextcloud.com/server/stable/user_manual/en/desktop/conflicts.html
8. Desktop sync FAQ (depth/inotify): https://docs.nextcloud.com/server/stable/user_manual/en/desktop/faq.html
9. Desktop usage (ignored files editor and constraints): https://docs.nextcloud.com/server/stable/user_manual/en/desktop/usage.html
10. macOS virtual files + `notify_push` note: https://docs.nextcloud.com/server/latest/user_manual/nn/desktop/macosvfs.html
