# 0200 - Chat Stack Choice And App Deployment Sketch
Status: DRAFT
Date: 2026-03-02

Deprecated app note:
`Leantime` is no longer an active near-term target. The current collaboration direction is the live `Nextcloud` suite in `docs/plans/0220-nextcloud-first-collaboration-suite.md`.

## Goal
Reduce avoidable trial-and-error by:
1. narrowing the self-hosted chat/collaboration choice down to one likely default
2. sketching one deployment shape that can support:
- chat
- Leantime (deprecated)
- Jellyfin
- PeerTube
- n8n
- Pangolin exposure

This is not a final implementation plan.
It is a forward-looking decision memo for the next app/platform phase.

## Inputs
The target use cases are mixed:
1. serious work chat
2. casual/friends chat
3. visible AI-agent chatter where a human can observe threads
4. eventual convergence on one system, not a permanent multi-chat fleet

The current platform assumptions are:
1. self-hosted on-prem is the default
2. `workload` is the intended default home for general app workloads
3. `platform` is platform-services-first
4. `ops-brain` should not become the default app lane
5. Pangolin remains the exposure boundary, not the internal service architecture

## Research Summary
### 1. Mattermost
Current strengths from official docs:
1. strong enterprise/admin orientation
2. plugin/app ecosystem and marketplace
3. self-hosted configuration surface is mature
4. built-in AI plugin path exists
5. role and security/compliance features are a major focus

Observed caveats:
1. several stronger features and plugins are license-sensitive or enterprise-shaped
2. calls are not end-to-end encrypted in the strong “server cannot see media” sense
3. product direction feels more enterprise-work oriented than friend/community oriented
4. boards are in maintenance mode rather than a strong future-facing reason to choose it

Good fit when:
1. the primary need is serious work coordination
2. admin control and enterprise-style features matter most
3. AI assistants inside the chat product itself are a real priority

### 2. Rocket.Chat
Current strengths from official docs:
1. self-managed collaboration platform with broad positioning
2. federation remains a product goal
3. can bridge/integrate with other systems through API/webhooks
4. better “Slack/Discord alternative” vibe than Mattermost for mixed audiences

Observed caveats:
1. federation is in active transition
2. official docs still describe stabilization work and recommend caution for mission-critical federation use
3. operational shape is heavier than Zulip
4. product surface is broad, which can mean more platform to own

Good fit when:
1. you want a broad chat platform with future federation
2. community/external-collab feel matters more than strict async discipline
3. you are comfortable with some product surface complexity

### 3. Zulip
Current strengths from official docs:
1. self-hosted offering is fully open-source and positioned as feature-complete
2. topic/thread model is the core product, not an add-on
3. robust API and bot/integration surface
4. strong fit for async, multi-threaded, searchable conversations
5. installation/upgrade story is explicitly treated as a first-class self-hosting concern

Observed caveats:
1. UI/interaction model is less Discord-like for casual users
2. social/community energy is lower if people expect chatroom-style freeform flow
3. if voice/video/community presence become central, Zulip is not the obvious “hangout” product

Good fit when:
1. the main need is durable, inspectable, multi-topic conversation
2. AI agents should chat in visible structured threads
3. serious work and automation readability matter more than chatroom vibe

## Recommendation
### Default recommendation: Zulip
If the goal is to converge on one system for:
1. work
2. friends
3. AI-agent-visible chatter

then Zulip is the best current default.

Why:
1. its thread/topic model matches AI-agent conversations unusually well
2. serious work is easier to keep readable over time
3. it is simpler to defend as a long-term knowledge-bearing chat surface
4. it is strongly self-hosted without obvious “real features live behind enterprise upsell” pressure

### When to choose Mattermost instead
Choose Mattermost instead if:
1. the top priority is work-first collaboration
2. you want a stronger built-in enterprise/admin posture
3. you expect the AI assistant experience to live inside the chat product itself

### When to choose Rocket.Chat instead
Choose Rocket.Chat instead if:
1. you want the closest “Slack/Discord alternative” feel
2. federation/inter-instance communication matters strategically
3. you are willing to accept a somewhat heavier and more in-motion product surface

## Convergence Rule
If the primary question is:
"Which one best supports humans and AI agents talking in ways that remain readable later?"

pick `Zulip`.

If the primary question is:
"Which one best supports enterprise-style team operations first?"

pick `Mattermost`.

If the primary question is:
"Which one feels most like a broad community chat platform?"

pick `Rocket.Chat`.

## n8n Fit
Officially, n8n:
1. supports Postgres for self-hosted deployments
2. supports queue mode for scale-out
3. supports webhook-heavy automation patterns

For this homelab, that means:
1. n8n is a good workflow/notification/orchestration layer
2. it should not be the source of truth for app identity or infrastructure state
3. it is a strong candidate for:
- chat notifications
- ingest/sync jobs
- automation glue between apps
- AI workflow experiments

## App-by-App Deployment Sketch
This section is intentionally light.
It is a topology sketch, not the final per-app plan.

### 1. Chat platform (recommended default: Zulip)
Suggested lane:
1. deploy on `workload`

Backing state:
1. Postgres
2. persistent media/uploads volume

Exposure:
1. Pangolin Public Resource for the web UI
2. optional Pangolin Private Resource for admin/internal access if desired

Why:
1. chat is user-facing and stateful
2. it should not live on `ops-brain`
3. it is a real workload, not a platform primitive

### 2. Leantime (deprecated)
Suggested lane:
1. deploy on `workload`

Backing state:
1. MySQL/MariaDB, not Postgres
2. persistent userfiles/log/plugin volumes

Exposure:
1. Pangolin Public Resource

Notes:
1. Leantime’s official Docker path is MySQL-oriented
2. treat it as its own app-specific data stack
3. do not try to force it onto `platform-postgres`

### 3. Jellyfin
Suggested lane:
1. deploy on `workload`

Backing state:
1. local config/db volume
2. media library volume

Exposure:
1. Pangolin Public Resource if you want browser access from outside the LAN
2. otherwise private/internal access can be enough initially

Notes:
1. reverse-proxy config matters
2. known proxies / forwarded headers matter if proxied
3. media storage design matters more than database design here

### 4. PeerTube
Suggested lane:
1. deploy on `workload`

Backing state:
1. Postgres
2. Redis
3. large video storage

Exposure:
1. Pangolin Public Resource

Notes:
1. domain choice matters early because PeerTube treats the webserver host as definitive
2. federation and remote redundancy add operational complexity
3. this is heavier than Jellyfin and should not be treated as a casual sidecar

### 5. n8n
Suggested lane:
1. start on `platform`
2. move to `workload` later only if automation traffic becomes heavy

Backing state:
1. Postgres preferred
2. persistent encryption key

Exposure:
1. Pangolin Public Resource for the UI if you want browser access
2. webhook endpoints may be public, semi-public, or private depending on workflow type

Notes:
1. n8n is more platform-adjacent than the media apps
2. if webhook volume becomes high, consider queue mode and separate workers later

### 6. Pangolin role across all of them
Use Pangolin for:
1. browser-facing exposure
2. operator/private access to selected internal targets

Do not use Pangolin as:
1. the internal service-to-service architecture
2. the app database connectivity layer
3. the cluster plumbing layer

## Shared Deployment Shape
One deployment shape that works for all of the above:

### Platform lane
Runs on `platform`:
1. Flux
2. future `platform-postgres`
3. future Gitea
4. n8n initially

### Workload lane
Runs on `workload`:
1. chat platform
2. Leantime (deprecated)
3. Jellyfin
4. PeerTube
5. other friend-facing and app-facing workloads

### Storage expectations
1. app config and DB data are persistent app state
2. media and large artifacts are separate bulk storage concerns
3. design all storage bindings with the expectation of eventual NAS migration

### Exposure expectations
1. internal service traffic stays native to k3s/network policy
2. user-facing web entrypoints go through Pangolin Public Resources
3. operator-only host/service access can use Pangolin Private Resources where useful

## Early Placement Recommendation
If you want the shortest path with the least future regret:
1. `platform-postgres` first
2. choose one chat platform, default `Zulip`
3. deploy that chat platform on `workload`
4. deploy one simpler off-the-shelf app next, but `Leantime` is no longer the recommended path
5. defer `PeerTube` until you are ready for heavier state and federation concerns
6. defer `Gitea` until the transition from platform-hardening into active app development

## Specific Product Notes
### Leantime (deprecated)
Official Docker guidance points to:
1. official Docker image
2. official Docker Compose
3. MySQL as the backing DB
4. persistent volumes for userfiles, public userfiles, plugins, and logs

Practical takeaway:
1. good fit as a self-hosted app
2. should be treated as a MySQL-backed workload, not a Postgres-backed platform primitive

### Jellyfin
Official docs emphasize:
1. reverse-proxy correctness
2. forwarded header and known proxy configuration
3. ordinary subdomain/base-path exposure patterns

Practical takeaway:
1. it is straightforward if proxying is done correctly
2. storage and networking matter more than DB strategy

### PeerTube
Official docs emphasize:
1. official Docker deployment
2. definitive domain/host choice
3. Postgres and Redis needs
4. federation/redundancy considerations

Practical takeaway:
1. treat PeerTube as a heavier commitment than Jellyfin
2. deploy it later, after you are happy with workload-lane storage and exposure patterns

### n8n
Official docs emphasize:
1. Postgres is the better self-hosted DB path
2. queue mode exists for heavier scale
3. shared encryption key matters in multi-process mode

Practical takeaway:
1. n8n is a good platform-adjacent automation service
2. keep its state disciplined early
3. don’t over-scale it until you have real workflow volume

## Suggested Immediate Next Decision
Choose one:
1. commit to `Zulip` as the default chat candidate and plan its deployment on `workload`
2. reject `Zulip` and explicitly choose `Mattermost` or `Rocket.Chat` for a different reason

If no contrary requirement appears, the current recommendation is:
1. `Zulip` for chat
2. `platform-postgres` as the next shared primitive
3. `Leantime` was the earlier off-the-shelf workload candidate, but the repo now prefers `Nextcloud`

## Sources
1. [Zulip self-hosting](https://zulip.com/self-hosting/)
2. [Zulip product overview](https://zulip.com/)
3. [Zulip interactive bots API](https://zulip.com/help/interactive-bots-api)
4. [Rocket.Chat federation guide](https://docs.rocket.chat/docs/create-federated-rooms)
5. [Rocket.Chat federation transition note](https://www.rocket.chat/blog/federation-at-rocket-chat-the-shift-to-a-native-solution)
6. [Mattermost integrations FAQ](https://docs.mattermost.com/integrations-guide/faq.html)
7. [Mattermost encryption options](https://docs.mattermost.com/deployment-guide/encryption-options.html)
8. [Mattermost agents plugin](https://docs.mattermost.com/agents/README.html)
9. [Leantime official Docker image](https://github.com/Leantime/docker-leantime)
10. [Leantime main repository](https://github.com/Leantime/leantime)
11. [Jellyfin reverse proxy guidance](https://jellyfin.org/docs/general/post-install/networking/reverse-proxy/)
12. [PeerTube Docker guide](https://docs.joinpeertube.org/install/docker)
13. [PeerTube documentation index](https://docs.joinpeertube.org/)
14. [PeerTube redundancy/federation notes](https://docs.joinpeertube.org/admin/following-instances)
15. [n8n supported databases](https://docs.n8n.io/hosting/configuration/supported-databases-settings/)
16. [n8n queue mode](https://docs.n8n.io/hosting/scaling/queue-mode/)
17. [n8n concurrency control](https://docs.n8n.io/hosting/scaling/concurrency-control/)
18. [Pangolin 1.13 release notes](https://github.com/fosrl/pangolin/releases)
