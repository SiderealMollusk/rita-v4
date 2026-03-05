# 0001 - n8n And Nextcloud Integration Research
Date: 2026-03-05
Status: Active research note

## Why this note exists
Define a practical integration path between the current `n8n` platform app and the official Nextcloud instance, using source-backed behavior and repo-local constraints.

Repo-local context:
1. `n8n` is scaffolded as a private `ClusterIP` platform app in `ops/gitops/platform/apps/n8n/`.
2. Current image pin is `docker.n8n.io/n8nio/n8n:2.7.4` in [n8n-deployment.yaml](/Users/virgil/Dev/rita-v4/ops/gitops/platform/apps/n8n/n8n-deployment.yaml).
3. Bring-up was blocked by control-plane reachability, not manifest syntax ([0550 progress log](/Users/virgil/Dev/rita-v4/docs/progress_log/0550-n8n-platform-gitops-scaffolded-but-bring-up-blocked.md)).

## Confirmed integration surfaces

### 1) n8n -> Nextcloud (outbound automation)
The built-in n8n Nextcloud node supports file/folder operations plus user retrieval/invite workflows.

Auth options supported by n8n credentials:
1. Basic auth with WebDAV URL and password/app-password.
2. OAuth2 against Nextcloud OAuth endpoints.

Practical fit:
1. Start with app-password auth for a service account and revoke/rotate independently from human login.
2. Use OAuth2 only when central token lifecycle or delegated login flows are explicitly needed.

### 2) Nextcloud -> n8n (event-triggered automation)
Nextcloud provides a `webhook_listeners` app that emits HTTP calls for internal events and is managed through OCS API / `occ`.

Constraints:
1. Registering webhooks requires admin or delegated admin rights.
2. n8n webhook trigger should use a production webhook URL with the workflow published.

Practical fit:
1. Use `webhook_listeners` to push event payloads into an n8n Webhook trigger.
2. Keep test URLs only for development; wire production URLs in Nextcloud registrations.

### 3) Direct API fallback for unsupported Nextcloud features
For operations not covered by the n8n Nextcloud node (for example, deeper OCS app endpoints), use n8n HTTP Request nodes against:
1. WebDAV base: `/remote.php/dav`
2. OCS base: `/ocs/v2.php/...` (with required `OCS-APIRequest: true` header)

This keeps n8n viable even when no dedicated node operation exists.

## Security and auth implications
1. Nextcloud OAuth2 currently supports confidential clients and warns that tokens are effectively full-account (no scoped access model), so protect token storage aggressively.
2. App passwords are strongly recommended by Nextcloud for third-party WebDAV clients and are easier to revoke per integration.
3. Use a dedicated Nextcloud service account for n8n workflows to avoid coupling automation blast radius to human users.

## Networking and runtime requirements
1. If n8n is published behind a reverse proxy, configure `WEBHOOK_URL` and `N8N_PROXY_HOPS` so generated webhook URLs are externally valid.
2. Use n8n production webhook URLs only after publishing the workflow.
3. Keep health/readiness checks enabled (`/healthz`, `/healthz/readiness`) for operations visibility.

## Recommended phased adoption for this repo

### Phase 0: unblock base service
1. Finish remaining bring-up steps from [0550](/Users/virgil/Dev/rita-v4/docs/progress_log/0550-n8n-platform-gitops-scaffolded-but-bring-up-blocked.md).
2. Confirm n8n pod readiness and DB migration health.

### Phase 1: outbound low-risk flow (no inbound webhooks yet)
1. Create Nextcloud service account + app password.
2. Build one scheduled n8n flow: list/download from a controlled folder, then write result metadata back.
3. Validate idempotency and retry behavior before adding event-driven triggers.

### Phase 2: inbound event flow
1. Enable `webhook_listeners` in Nextcloud.
2. Register a narrowly filtered webhook (for example, single user or path context) to an n8n production webhook.
3. Add signature/shared-secret validation and deduplication keying in n8n workflow logic.

### Phase 3: capability expansion
1. Add HTTP Request nodes for specific OCS endpoints needed by Deck/Talk/other app workflows.
2. Standardize error handling, dead-letter notifications, and audit traces.

## Risks to track
1. Version drift: n8n node capabilities and Nextcloud webhook payloads evolve; re-validate after upgrades.
2. Over-privileged credentials: OAuth/account-wide tokens can become a high-impact secret.
3. Duplicate or out-of-order events from webhook delivery retries.
4. Tight coupling between Nextcloud event schema and n8n workflow assumptions.

## Primary sources
1. n8n Nextcloud node: https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.nextcloud/
2. n8n Nextcloud credentials: https://docs.n8n.io/integrations/builtin/credentials/nextcloud/
3. n8n Webhook node behavior (test vs production): https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
4. n8n webhook workflow development: https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/workflow-development/
5. n8n reverse proxy webhook URL config: https://docs.n8n.io/hosting/configuration/configuration-examples/webhook-url/
6. n8n monitoring endpoints: https://docs.n8n.io/hosting/logging-monitoring/monitoring/
7. Nextcloud WebDAV basics (`/remote.php/dav`): https://docs.nextcloud.com/server/latest/developer_manual/client_apis/WebDAV/basic.html
8. Nextcloud WebDAV user guidance (app password and per-user DAV URL): https://docs.nextcloud.com/server/latest/user_manual/en/files/access_webdav.html
9. Nextcloud OAuth2 admin config and security considerations: https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/oauth2.html
10. Nextcloud webhook listeners: https://docs.nextcloud.com/server/stable/admin_manual/webhook_listeners/index.html
11. Nextcloud OCS API conventions (`OCS-APIRequest`): https://docs.nextcloud.com/server/latest/developer_manual/client_apis/OCS/index.html
