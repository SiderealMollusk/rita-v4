# 0018 - Nextcloud Flow AppAPI And Recording Incident (2026-03-06)
Date: 2026-03-06
Status: Deep-dive completed

## Scope
Investigate rapid post-flush return of Nextcloud warnings/log volume, isolate dominant emitters, attempt recovery with existing runbooks, and identify stable short-term operating posture.

## Context
After log flush, warnings quickly returned. Primary concern was whether this represented broad platform instability or two narrow subsystems emitting repeated failures.

Environment in scope:
1. Nextcloud VM: `nextcloud-vm`
2. Talk recording backend host: `talk-recording-gpu`
3. Repo runbooks under [scripts/2-ops/workload](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload)

## Observed Symptoms

### A. Flow ExApp / AppAPI noise
1. Repeated `401` responses on `/ocs/v1.php/apps/app_api/ex-app/state?format=json`.
2. Repeated Nextcloud log messages:
- `Invalid signature for ExApp: flow and user: null.`
- `ExApp flow request to NC validation failed.`
3. Repeated heartbeat-related failures around `/exapps/flow/heartbeat` including `404` and disabled-state lines.

### B. Talk recording backend errors
1. `spreed` recording calls returned `403 FORBIDDEN` from `http://192.168.6.19:1234`.
2. Nextcloud emitted:
- `Failed to send message to recording server`
- paired Guzzle `ClientException` traces for recording endpoint requests.

## Evidence Snapshot
From active VM probing and tails during incident:
1. `nextcloud.log` and `nginx/access.log` regrew quickly after flush.
2. `nginx/error.log` remained low/clean relative to access and app logs.
3. Message distribution in `nextcloud.log` was dominated by `app_api` + `flow` signature/validation failures.

## Runbooks Executed

### Log and warning hygiene
1. [45-flush-nextcloud-logs.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/45-flush-nextcloud-logs.sh)
2. [44-clear-nextcloud-throttle-and-show-source.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/44-clear-nextcloud-throttle-and-show-source.sh)

### Flow / AppAPI recovery attempts
1. [46-configure-nextcloud-appapi-harp-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/46-configure-nextcloud-appapi-harp-runtime.sh)
2. [19-deploy-nextcloud-flow-exapp.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/19-deploy-nextcloud-flow-exapp.sh)
3. [20-patch-nextcloud-flow-oss.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/20-patch-nextcloud-flow-oss.sh)
4. [34-verify-nextcloud-exapps-health.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/34-verify-nextcloud-exapps-health.sh)

Additional manual operator actions during recovery:
1. force disable/unregister of `flow`
2. runtime purge of `nc_app_flow` container/volume
3. re-register/re-enable attempts against `harp_local_vm`

### Recording backend recovery
1. [47-install-nextcloud-talk-recording-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/47-install-nextcloud-talk-recording-runtime.sh)
2. [48-configure-nextcloud-talk-recording-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/48-configure-nextcloud-talk-recording-runtime.sh)
3. [49-verify-nextcloud-talk-recording-runtime.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/49-verify-nextcloud-talk-recording-runtime.sh)

## Results

### Recording lane
Recovered to verified-good state.
1. Host service active.
2. Public welcome probe succeeded.
3. Nextcloud recording config verification passed with runtime SoT parity.

Reference SoT:
- [talk-recording-runtime.yaml](/Users/virgil/Dev/rita-v4/ops/nextcloud/talk-recording-runtime.yaml)

### Flow lane
Did not stabilize under current runbook sequence.
1. `flow` could be toggled/enabled, but health verification continued to fail.
2. Sustained auth/signature failures persisted in state polling windows.
3. Heartbeat path failures (`/exapps/flow/heartbeat`) showed disabled/mismatch behavior during registration attempts.

## Interpretation
This incident is not broad Nextcloud failure. It is two independent lanes:
1. Recording lane: configuration drift/mismatch; fixed by full SoT reapply and verification.
2. Flow lane: AppAPI/Flow runtime alignment remains unstable in this environment, producing high-volume warning noise.

Given current product priorities, Flow should be treated as optional and disabled unless actively needed.

## Deep-Dive Research Findings

### 1) Standard approach (reference model)
For Nextcloud ExApps with AppAPI, stable path is:
1. use one deploy daemon strategy per instance (HaRP or docker-local, not mixed day-to-day)
2. set daemon `nextcloud_url` to an internal/reachable URL from daemon/runtime context (examples in `occ app_api:daemon:register --help` use `http://nextcloud.local`)
3. keep `/exapps/` routing and daemon runtime aligned with the same mode
4. register/deploy/verify with bounded checks and clear rollback path

### 2) High-confidence likely causes in this incident
Ranked by observed evidence + upstream issue similarity:

#### C1. Mixed daemon state + stale app registration
Evidence:
1. two daemons existed simultaneously:
   - `harp_local_vm` (default, local URL)
   - `docker_local_vm` (non-default, NC Url `https://cloud.virgil.info`)
2. `flow` remained registered as disabled and still emitted heartbeat noise:
   - repeated `ExApp with appId flow is disabled (/exapps/flow/heartbeat)`
   - repeated heartbeat failures against `http://127.0.0.1/exapps/flow/heartbeat` with large retry counters

Impact:
1. warning/log flood continues even when Flow is \"disabled\" if stale registration remains.

#### C2. NC URL / proxy mismatch class for AppAPI validation
Evidence:
1. upstream AppAPI issues document invalid-signature loops when daemon uses public/proxied URL instead of local/internal URL.
2. your historical signature failures match this family:
   - `Invalid signature for ExApp: flow and user: null`
   - `ExApp flow request to NC validation failed`
3. one daemon (`docker_local_vm`) used public URL (`https://cloud.virgil.info`) while stable local daemon used `http://127.0.0.1`.

Impact:
1. intermittent/sticky auth validation errors and 401 state polling under proxy-mediated paths.

#### C3. Flow runtime fragility on OSS path + script drift
Evidence:
1. repo carries explicit Flow OSS patch runbook (`20-patch-nextcloud-flow-oss.sh`) for known runtime instability.
2. patch script targets `FLOW_RUNTIME_HOST=virgil@192.168.6.181` by default (legacy host path risk if runtime moved).
3. verify script windows can fail on stale log lines (already noted in this incident).

Impact:
1. false-negative verification and repeated churn cycles even after partial recovery.

### 3) Recording lane root cause summary
Observed `403 FORBIDDEN` from recording endpoint was consistent with backend/config secret mismatch/drift.
Full SoT reapply (install/configure/verify 47/48/49) restored recording lane to healthy state.

## Known upstream issue patterns (relevant)
1. Nextcloud Flow issue: Docker Local VM deployment can fail with missing security key (`No security key with id ...`) (#375).
2. AppAPI issue: invalid signatures when daemon NC URL points through reverse proxy/public endpoint (#980).
3. AppAPI issue: local/public URL mismatch can break ExApp registration/validation (#984).
4. AppAPI issue: invalid signature behavior through proxy/tunnel setups (#947).

These patterns are consistent with your observed 401/signature class.

## Stabilization recommendations (concrete)

### A) Keep recording lane as-is (already stabilized)
1. retain current verified runtime SoT.
2. keep 49-verify in regular maintenance cadence.

### B) For Flow lane, choose one of two explicit postures
1. **Posture B1 (recommended now): fully remove Flow runtime noise**
   - keep `flow` disabled
   - unregister `flow` (not only disable) when stabilization lane is paused
   - remove/retire non-canonical daemon entries causing ambiguity (`docker_local_vm`) after validation
2. **Posture B2 (when re-opening stabilization): strict single-daemon lane**
   - use only `harp_local_vm`
   - ensure daemon `nextcloud_url` remains local/internal
   - bounded verification window from command start time
   - only then re-register/deploy Flow and evaluate

### C) Runbook hardening (required)
1. add timestamp-bounded log checks to `34-verify-nextcloud-exapps-health.sh`.
2. make `20-patch-nextcloud-flow-oss.sh` runtime host derive from canonical daemon/runtime SoT instead of hardcoded default.
3. add explicit check: fail if multiple docker-install daemons exist unless allowlisted.
4. add `flow` unregister cleanup mode to stop disabled heartbeat spam deterministically.

## Standard operating posture (until Flow is needed)
1. Recording: enabled + verified.
2. Flow: disabled and treated as optional.
3. AppAPI daemon baseline: HaRP local VM only.
4. Alerting: app_api signature/heartbeat error-rate threshold with bounded log window.

## Operational Decision (Current)
Disable Flow to stop warning/log flood while preserving core Nextcloud + Talk baseline.

Command path used:
1. `sudo -u www-data php /var/www/nextcloud/occ app_api:app:disable flow`

## Risks And Follow-Up Research
1. If Flow is needed later, reopen as a dedicated stabilization lane with explicit success criteria.
2. Investigate whether `flow` should run against `docker_local_vm` instead of `harp_local_vm` for this deployment shape.
3. Add bounded log window checks to avoid false failures from stale historical lines in [34-verify-nextcloud-exapps-health.sh](/Users/virgil/Dev/rita-v4/scripts/2-ops/workload/34-verify-nextcloud-exapps-health.sh).

## Related Material
1. [0760-nextcloud-appapi-harp-vm-default-and-warning-burndown.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0760-nextcloud-appapi-harp-vm-default-and-warning-burndown.md)
2. [0770-nextcloud-harp-baseline-snapshot.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0770-nextcloud-harp-baseline-snapshot.md)
3. [0790-nextcloud-talk-recording-backend-faq-addendum.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0790-nextcloud-talk-recording-backend-faq-addendum.md)
4. [0810-nextcloud-flow-disabled-and-recording-runtime-repaired.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0810-nextcloud-flow-disabled-and-recording-runtime-repaired.md)

## External Sources
1. AppAPI daemon register semantics (local/internal `nextcloud_url` examples): `occ app_api:daemon:register --help` on live host.
2. Nextcloud AppAPI docs (AppAPI + external apps): https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/AppAPIAndExternalApps.html
3. Nextcloud AppAPI deploy configurations (HaRP/manual/docker-local): https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/DeployConfigurations.html
4. Nextcloud Flow issue #375 (Docker Local VM security key class): https://github.com/nextcloud/flow/issues/375
5. Nextcloud AppAPI issue #980 (invalid signature via reverse proxy URL mismatch): https://github.com/nextcloud/app_api/issues/980
6. Nextcloud AppAPI issue #984 (local/public URL mismatch class): https://github.com/nextcloud/app_api/issues/984
7. Nextcloud AppAPI issue #947 (proxy/tunnel signature behavior): https://github.com/nextcloud/app_api/issues/947

## Online deep research: 5 concrete avenues

### Avenue 1 - Daemon NC URL + reverse-proxy boundary mismatch
Why this matches your symptom:
1. Signature/validation failures are a known class when ExApp/AppAPI requests traverse mismatched public/proxy URL paths.
2. Your logs previously showed `Invalid signature for ExApp` and `validation failed`.

What to test:
1. ensure active daemon `NC Url` is local/internal for VM-local daemon path (`http://127.0.0.1` in your current HaRP local model).
2. remove non-canonical daemon entries using public URL from day-to-day path.
3. re-register Flow once with only one daemon mode.

Sources:
1. AppAPI daemon register docs (examples use local internal URL): https://docs.nextcloud.com/server/stable/admin_manual/exapps_management/ManagingDeployDaemons.html
2. AppAPI troubleshooting (`401 Unauthorized` guidance): https://nextcloud.github.io/app_api/faq/Troubleshooting.html
3. Community report with exact signature failures on ExApp requests (`context_chat_backend`): https://help.nextcloud.com/t/context-chat-backend-not-working/221948
4. Community report with Flow + validation/signature failures: https://help.nextcloud.com/t/writing-to-nc-files-from-windmill-scripts/230272

### Avenue 2 - Heartbeat path semantics and disabled ExApp retry noise
Why this matches your symptom:
1. You observed repeated `/exapps/flow/heartbeat` failures and disabled-state lines.
2. ExApp lifecycle includes periodic heartbeat checks and disabled/enabled callbacks.

What to test:
1. after disable, run explicit unregister and confirm heartbeat checks stop.
2. validate heartbeat behavior with test-deploy before Flow re-enable.
3. keep verification windows bounded to post-action timestamps.

Sources:
1. ExApp lifecycle/heartbeat behavior: https://docs.nextcloud.com/server/latest/developer_manual/exapp_development/development_overview/ExAppLifecycle.html
2. App installation flow heartbeat contract: https://docs.nextcloud.com/server/latest/developer_manual/exapp_development/tech_details/InstallationFlow.html
3. AppAPI issue: heartbeat check failing despite healthy container (#522): https://github.com/nextcloud/app_api/issues/522
4. Community HaRP heartbeat/test-deploy 404 thread: https://help.nextcloud.com/t/appapi-harp-proxy-connects-but-test-deploy-fails-on-heartbeat-with-404/233446

### Avenue 3 - Flow-on-OSS runtime quirks (Windmill/bootstrap/security key class)
Why this matches your symptom:
1. Your repo already carries a Flow OSS patch script, indicating known upstream mismatch with default Flow image/behavior in non-standard setups.
2. Community threads show Flow users seeing the same signature/validation family while integrating internal NC resources.

What to test:
1. strict Flow version pin + daemon mode pin for one controlled test window.
2. patch script host-target correctness (avoid legacy host defaults).
3. verify ExApp config state immediately after register.

Sources:
1. Community Flow/AppAPI signature failure thread: https://help.nextcloud.com/t/writing-to-nc-files-from-windmill-scripts/230272
2. Flow repository issues (general instability classes): https://github.com/nextcloud/flow/issues

### Avenue 4 - HaRP/AppAPI version skew and protocol compatibility
Why this matches your symptom:
1. Community reports show `_ping`/heartbeat failures from version/protocol mismatches (`client version ... too old`) even when containers are \"up\".
2. This can masquerade as generic 404/400/validation noise.

What to test:
1. pin AppAPI app version + HaRP image tag together (avoid floating `release` for incident reproduction).
2. run test-deploy compatibility check before Flow deploy.
3. verify from inside HaRP container to daemon/docker socket path as docs suggest.

Sources:
1. Community thread showing `_ping` compatibility/version error string: https://help.nextcloud.com/t/appapi-harp-proxy-connects-but-test-deploy-fails-on-heartbeat-with-404/233446
2. AppAPI + external apps admin docs: https://docs.nextcloud.com/server/latest/admin_manual/exapps_management/AppAPIAndExternalApps.html

### Avenue 5 - Verification pipeline false negatives (log windows, multi-daemon ambiguity)
Why this matches your symptom:
1. Your verify script currently inspects large tail windows and can catch stale historical errors.
2. Multiple registered daemons increase ambiguity when deploy scripts and verify defaults diverge.

What to test:
1. add `--since-epoch` bounded grep window in verify script.
2. fail fast if more than one docker-install daemon is present unless allowlisted.
3. add explicit check that deployed app references expected daemon.

Sources:
1. Internal runbook behavior in `34-verify-nextcloud-exapps-health.sh` (tail-based checks).
2. AppAPI CLI semantics for daemon/app listing and config inspection (`occ app_api:*` help/output on live host).

## Live relevance triage (validated)

### Avenue 1 - Daemon NC URL + reverse-proxy mismatch
Relevance: **High**

Live evidence:
1. two daemons are currently registered:
   - `harp_local_vm` (default, `NC Url=http://127.0.0.1`)
   - `docker_local_vm` (non-default, `NC Url=https://cloud.virgil.info`)
2. upstream issue class explicitly maps invalid-signature behavior to proxy/public URL mismatches.

Conclusion:
1. this avenue is active risk in current state and should be normalized to one canonical daemon path.

### Avenue 2 - Heartbeat/disabled ExApp retry noise
Relevance: **High**

Live evidence (log counts):
1. `/exapps/flow/heartbeat` related messages: high volume (200+ historical lines).
2. `ExApp with appId flow is disabled (/exapps/flow/heartbeat)` repeats heavily.
3. Flow is still registered in disabled state (`app_api:app:list`), which allows recurring disabled-heartbeat noise.

Conclusion:
1. this is currently the dominant warning/log flood vector.

### Avenue 3 - Flow-on-OSS runtime bootstrap/security-key class
Relevance: **Partial**

Live evidence:
1. no current `No security key with id ...` lines found.
2. repo still carries explicit OSS patch script (`20-patch-nextcloud-flow-oss.sh`), indicating known fragility class.
3. patch script default runtime host points to legacy host path by default, which is operationally risky.

Conclusion:
1. not primary current emitter, but still relevant if Flow is re-enabled.

### Avenue 4 - HaRP/AppAPI version skew
Relevance: **Partial**

Live evidence:
1. `app_api` app is 32.0.0 and HaRP image is floating `:release` tag.
2. floating tag increases drift risk across retries/windows.
3. no immediate hard version error observed in current snapshot, but compatibility class remains plausible.

Conclusion:
1. not proven primary cause right now, but pinning versions is prudent before any Flow re-open.

### Avenue 5 - Verification false negatives (stale tails + ambiguity)
Relevance: **High**

Live evidence:
1. verify script uses fixed tail windows (`tail -n`) with no time bound.
2. script does not enforce single-daemon invariant before app checks.
3. this can fail current runs due to stale historical errors and mixed daemon state.

Conclusion:
1. directly relevant and should be fixed before using verify script as gate.

## Priority order from triage
1. Avenue 2 (disabled Flow heartbeat noise) - immediate.
2. Avenue 1 (mixed daemon/URL boundary) - immediate.
3. Avenue 5 (verify script false negatives) - immediate.
4. Avenue 4 (version pinning) - before re-enable attempts.
5. Avenue 3 (Flow OSS bootstrap quirks) - re-open lane only.
