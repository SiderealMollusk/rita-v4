# 0640 - Nextcloud Talk Websocket HTTPS Fix And Log Cleanup

Date: 2026-03-05

## Summary

Resolved the primary web-Talk connectivity blocker by moving signaling from insecure internal `ws://` to a public HTTPS endpoint on the Nextcloud origin, then cleaned historical error backlog from Nextcloud logs.

## What Changed

1. Added secure signaling reverse-proxy path to Nextcloud Nginx template:
- [nginx-site.conf.j2](/Users/virgil/Dev/rita-v4/ops/ansible/templates/nextcloud/nginx-site.conf.j2)
  - new `location ^~ /standalone-signaling/` with websocket upgrade headers and upstream forwarding

2. Added upstream variable in group vars:
- [nextcloud.yml](/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/nextcloud.yml)
  - `nextcloud_talk_signaling_upstream: "http://192.168.6.184:8080"`

3. Updated Talk runtime SoT signaling server to HTTPS path:
- [talk-runtime.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/talk-runtime.yaml)
  - `talk.signaling.server: "https://cloud.virgil.info/standalone-signaling"`
  - `talk.signaling.verify_tls: true`

4. Installed missing SQLite PHP extension on `nextcloud-vm`:
1. package: `php8.2-sqlite3`
2. modules now present: `pdo_sqlite`, `sqlite3`

5. Switched live Nextcloud signaling registration:
1. removed `ws://192.168.6.184:8080`
2. added `https://cloud.virgil.info/standalone-signaling` with verify enabled

6. Cleared stale historical log errors:
1. backed up `nextcloud.log` to `nextcloud.log.pre-clean-<timestamp>`
2. truncated current `nextcloud.log`
3. immediate `level>=3` count after clean: `0`

## Verification Evidence

1. HPB service/API on `talk-hpb-vm`:
1. `curl http://127.0.0.1:8080/api/v1/welcome` => version `v2.1.0`
2. services active: `nextcloud-spreed-signaling`, `janus`, `nats-server`

2. Public signaling endpoint:
1. `curl -si https://cloud.virgil.info/standalone-signaling/api/v1/welcome` => `HTTP/2 200`
2. websocket probe to `/standalone-signaling/spreed` reached backend path and returned signaling-layer `400 Bad Request` (expected for synthetic handshake)

3. Nextcloud signaling config:
1. `occ talk:signaling:list` now shows only `https://cloud.virgil.info/standalone-signaling` with `verify: true`

## Follow-up

1. Re-test browser Talk call start/join after hard refresh and new login session.
2. If UI still shows HPB warning, capture fresh warning text and current Talk JS network websocket URL for final alignment.
