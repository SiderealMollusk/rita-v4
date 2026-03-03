# 0220 - Nextcloud First Collaboration Suite
Status: ACTIVE
Date: 2026-03-03

## Goal

Hard pivot the first-wave app plan toward a single Nextcloud-centered collaboration suite and defer the other public app installs.

V1 tenancy model:
1. one shared Nextcloud instance
2. group-based organization inside that instance
3. no instance-per-project or instance-per-person automation in v1
4. multi-instance Nextcloud remains a later option, not the first deployment target

Target application surface:
1. `Nextcloud`
2. `Collectives`
3. `Contacts`
4. `Calendar`
5. `Deck`
6. `Notes`
7. `Tasks`

Deferred from the earlier first-wave sequence:
1. `Leantime`
2. `Zulip`
3. `n8n`
4. `Jellyfin`
5. `PeerTube`

## Current State

As of `0470`:
1. the base Nextcloud deployment is live
2. Redis is live
3. external Postgres is live and in use
4. the target collaboration apps are enabled
5. this plan now governs follow-on automation and hardening, not first bring-up

## Why This Pivot Is Coherent

The new operating assumption is:
1. one organized human collaboration home base is more valuable right now than several separate off-the-shelf apps
2. custom apps can remain separate and weird later
3. the platform should optimize for a durable suite install plus repeatable onboarding, not for maximum app diversity on day one

This makes Nextcloud a good candidate even though it is not the universal platform substrate.

## Recommendation

Use the Kubernetes Helm chart, but do it with eyes open:
1. use the community `nextcloud/helm` chart because you want GitOps and Kubernetes-native automation
2. do not confuse that with “officially supported by Nextcloud GmbH”
3. do not treat the default values as production-safe

The chart repository itself warns:
1. it is community maintained
2. it is designed for expert use
3. Nextcloud GmbH recommends All-in-One for quick/easy deployments with full Hub features

For this repo, the right interpretation is:
1. AIO is attractive for ease
2. Helm is attractive for automation and source-of-truth
3. since your priority is durable automation, Helm still makes sense

## Chosen Platform Shape

### Placement
1. `Nextcloud` runs on `workload`
2. `platform-postgres` remains on `platform`
3. no general app workload lands on `ops-brain`

### Exposure
1. `Nextcloud` is a Pangolin Public Resource
2. use `app.virgil.info` as the dedicated public host
3. treat it as the main public collaboration suite, not an internal-only tool

### Data
1. use external PostgreSQL via `platform-postgres`
2. use external Redis
3. use persistent storage for app files/config/data
4. do not front-load object storage as primary storage in the first pass

### Deployment posture
1. single replica first
2. no HPA first
3. no “clustered Nextcloud” first
4. no nginx sidecar first unless a concrete reason appears
5. prefer the chart’s Apache path first to reduce reverse-proxy weirdness

## Current Best-Practice Shape

### 1. External database, not SQLite
The chart defaults to SQLite for convenience/testing.
That is not acceptable for this deployment.

Use:
1. `internalDatabase.enabled = false`
2. `externalDatabase.enabled = true`
3. `externalDatabase.type = postgresql`
4. credentials from External Secrets / 1Password

Why:
1. Nextcloud docs explicitly say SQLite is not recommended for production
2. you already have a shared Postgres service alive

### 2. Redis is not optional
Nextcloud docs recommend Redis for:
1. distributed cache
2. transactional file locking

This matters even on a modest install because default database-backed locking adds load and pain.

Use:
1. external Redis
2. `memcache.locking = Redis`
3. `memcache.distributed = Redis`
4. APCu as local cache

Do not use Memcached for file locking.

### 3. Cron, not Ajax/webcron
Background jobs must be real cron.

In chart terms:
1. `cronjob.enabled = true`
2. choose one implementation and standardize it

Recommendation:
1. use the sidecar cron mode first for simplicity

### 4. Reverse proxy settings must be explicit
Nextcloud’s automatic proxy detection is fragile behind reverse proxies.

Must model:
1. `trusted_proxies`
2. `overwriteprotocol=https`
3. maybe `overwritehost`
4. `phpClientHttpsFix` in the chart if needed

This is especially important because you are using Pangolin as the external entrypoint.

### 5. Single replica first
The chart supports HPA and sticky-session guidance, but first pass should not use that.

Reason:
1. shared storage semantics
2. app upgrade behavior
3. cache/locking correctness
4. session affinity
5. lower debugging complexity

Treat HA as a later phase.

## Required Apps And Dependencies

Desired suite apps:
1. `contacts`
2. `calendar`
3. `deck`
4. `notes`
5. `tasks`
6. `collectives`

Important dependency note:
1. `Collectives` depends on the Teams/Circles and Text ecosystem
2. current project docs/community references indicate dependencies including:
   - Teams/Circles
   - Text
   - Viewer
   - `files_versions`

This means “install Collectives” is not a one-app action.

## Helm/Automation Strategy

### Base install should remain declarative
Use Flux-managed Helm for the base Nextcloud deployment:
1. chart source
2. values
3. PVCs
4. external DB wiring
5. Redis wiring
6. ingress/service exposure
7. config snippets

### App enablement should be post-install automation
The suite app layer is better treated as a bootstrap step after the base pod is healthy.

Reason:
1. app installation often wants `occ`
2. some app configuration is easier after the instance exists
3. “org provisioning” needs imperative application logic anyway

So the right split is:
1. Helm/Flux for the base instance
2. `occ` + OCS/API automation for app enablement and tenant/org onboarding

## Proposed Automation Model

### Stage A - Base instance bootstrap
Flux/Helm should create:
1. Nextcloud workload
2. PVCs
3. service/ingress
4. DB secret and DB connectivity
5. Redis connectivity
6. cron enabled
7. config snippets for proxy/cache defaults

Canonical secret contract for v1:
1. one 1Password item: `nextcloud-main`
2. fields:
   - `nextcloud-admin`
   - `nextcloud-db`
   - `nextcloud-redis`
3. Kubernetes `ExternalSecret` resources derive app-facing secrets from that single item

### Stage B - Suite enablement bootstrap
A no-arg runbook should:
1. wait for Nextcloud readiness
2. run `occ background:cron`
3. run `occ app:install` / `occ app:enable` for:
   - `contacts`
   - `calendar`
   - `deck`
   - `notes`
   - `tasks`
   - `collectives`
   - dependency apps as needed
4. verify enabled app list

### Stage C - “Create org” automation
This is the thing you actually want.

For v1, “org” means an organized collaboration space inside one shared instance, not a separate tenant/instance.

Recommended first definition of an “org”:
1. one Nextcloud group
2. one Team folder
3. one shared Collective space
4. one shared Deck board
5. one default user/app visibility bundle

Later, maybe:
1. shared calendars
2. shared address books
3. quota policy

## Concrete Org Provisioning Sketch

### Canonical org inputs
1. `org_slug`
2. `display_name`
3. initial users
4. storage quota policy
5. whether to create shared board/folder/collective

### Canonical operations
1. create group with `occ group:add` or Provisioning API
2. create/add users with Provisioning API
3. add users to group
4. create Team folder with `occ groupfolders:create`
5. assign group to Team folder with `occ groupfolders:group`
6. set Team folder quota if desired
7. seed Collectives initial content through the Collectives skeleton mechanism
8. create initial Deck board through Deck API

### Recommended interfaces
1. OCS Provisioning API for users/groups
2. `occ` for app installation and Team folder operations
3. Deck API for board creation

This split is better than trying to force everything through one interface.

## Best Initial Definition Of “Configured Nextcloud”

When you say “spin up an org”, the first version should mean:
1. users can log in
2. the right apps are visible
3. they share a Team folder
4. they have a Collective workspace
5. they have a Deck board

Do **not** make v1 depend on perfectly auto-creating every DAV object.
Do **not** make v1 depend on separate Nextcloud instances per org.

Why:
1. users/groups/folders are easy to automate
2. Deck is reasonably API-friendly
3. shared calendars/address books are more awkward and are not necessary to prove the system

That is the practical line between a robust onboarding system and a sprawling integration trap.

## Footguns

### 1. The Helm chart is community-maintained, not official product support
This is the biggest strategic footgun.

If you choose Helm, you are choosing:
1. better GitOps fit
2. more operator responsibility

### 2. SQLite default
The chart defaults are not the deployment you want.

Never allow the install to quietly fall back to SQLite.

### 3. Redis-less Nextcloud
Without Redis:
1. file locking falls back to the DB
2. performance and correctness suffer

Treat Redis as required, not optional.

### 4. Reverse proxy misconfiguration
If `trusted_proxies` / overwrite settings are wrong:
1. bad redirects
2. mixed `http`/`https`
3. broken CSP
4. wrong client IPs

There is also a live chart issue about nginx mode causing wrong redirects/CSP when proxied.

### 5. Using nginx mode first
Because of the current chart issue and extra complexity, nginx+fpm is not the best first-pass shape here.

Recommendation:
1. start with Apache flavor
2. only move to nginx/fpm later if you have a real reason

### 6. `nextcloud.host` is install-time-ish
The chart README warns that `nextcloud.host` updates `trusted_domains` at installation time only.

That means:
1. choose the host/domain early
2. do not treat hostname changes as free

### 7. RWX/NFS/shared-storage assumptions
Community issue history shows pain around existing claims and RWX-style persistence.

Recommendation:
1. start simple
2. single replica
3. straightforward PVC model

### 8. Clustering too early
The chart has HPA/sticky-session guidance.
That does not mean it is a good first move.

Avoid:
1. HPA first
2. multi-replica first
3. object storage primary first

### 9. App visibility is not universally controllable
Many apps can be enabled for groups.
Some cannot.

Important caveat:
1. community discussion indicates `Collectives` is not cleanly group-restrictable because of how it integrates with the filesystem backend

So if you want strict tenant/org separation by app visibility alone, Nextcloud will disappoint you.

### 10. Collectives has real dependencies
Collectives is not “just another app”.
It depends on adjacent app ecosystem pieces and wants a Teams/Text-style environment.

### 11. App upgrades are their own lifecycle
After Nextcloud upgrades or app upgrades:
1. app compatibility may matter
2. PHP cache revalidation behavior can produce weird transient states
3. restarts/reloads may be needed

### 12. “One instance per org” temptation
Do not jump to separate Nextcloud instances per org unless you truly need strong isolation.

That would multiply:
1. upgrades
2. DBs
3. storage
4. app state
5. automation complexity

First, prove one suite instance with org automation on top.

## Recommended First Implementation

### 1. Base Nextcloud
1. Helm chart: `nextcloud/nextcloud`
2. image flavor: `apache`
3. external Postgres: yes
4. external Redis: yes
5. single replica: yes
6. cron enabled: yes
7. Pangolin public resource: yes (`app.virgil.info`)

### 2. App bundle bootstrap
1. enable `contacts`
2. enable `calendar`
3. enable `deck`
4. enable `notes`
5. enable `tasks`
6. enable dependencies for `collectives`
7. enable `collectives`

### 3. Org automation v1
1. create group
2. create users / add users to group
3. create Team folder and grant group access
4. seed Collective skeleton
5. create Deck board

### 4. Defer from v1
1. perfect IdP integration
2. strict app visibility per org
3. multi-replica deployment
4. object storage primary backend
5. deep DAV bootstrap for calendars/address books

## Recommended Repo Shape

### GitOps
1. `ops/gitops/workload/apps/nextcloud/`
2. `HelmRelease`
3. external DB/Redis secrets via ESO
4. config snippets in chart values

### Bootstrap/runbooks
1. one runbook to install/verify base Nextcloud
2. one runbook to enable the suite apps with `occ`
3. one runbook to “create org”

That gives you:
1. declarative base platform state
2. imperative suite/app bootstrap
3. imperative org lifecycle automation

## Recommendation On Current Direction

This pivot is sound.

If your real target is:
1. one main organized collaboration surface
2. repeatable human onboarding
3. custom apps outside the suite

then Nextcloud is a better next move than continuing to split attention between `Leantime`, `Zulip`, and several other off-the-shelf apps.

## Sources

Primary / official:
1. Nextcloud Helm repo README: https://github.com/nextcloud/helm
2. Chart README (raw): https://raw.githubusercontent.com/nextcloud/helm/main/charts/nextcloud/README.md
3. Nextcloud installation/admin manual: https://docs.nextcloud.com/server/31/admin_manual/installation/
4. Nextcloud server tuning: https://docs.nextcloud.com/server/stable/admin_manual/installation/server_tuning.html
5. Nextcloud reverse proxy docs: https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/reverse_proxy_configuration.html
6. Nextcloud memory caching docs: https://docs.nextcloud.com/server/stable/admin_manual/configuration_server/caching_configuration.html
7. Nextcloud `occ` command docs: https://docs.nextcloud.com/server/stable/admin_manual/occ_command.html
8. Nextcloud user provisioning API: https://docs.nextcloud.com/server/19/admin_manual/configuration_user/user_provisioning_api.html
9. Deck API docs: https://deck.readthedocs.io/en/latest/API/
10. Contacts/CardDAV admin docs: https://docs.nextcloud.com/server/latest/admin_manual/groupware/contacts.html
11. Nextcloud Groupware user docs: https://docs.nextcloud.com/server/latest/user_manual/en/groupware/index.html

Community / project docs used for gaps and footguns:
1. Nextcloud Helm issue on nginx redirect/CSP behavior: https://github.com/nextcloud/helm/issues/560
2. Nextcloud Helm issue on datadir/external DB confusion: https://github.com/nextcloud/helm/issues/620
3. Nextcloud Helm issue on RWX persistence pain: https://github.com/nextcloud/helm/issues/399
4. Collectives app repo: https://github.com/nextcloud/collectives
5. Collectives documentation rewrite thread with dependency notes: https://help.nextcloud.com/t/collectives-app-documentation-re-write/146873
6. Team folders CLI docs: https://github.com/nextcloud/groupfolders
