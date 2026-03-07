# 0820 - Nextcloud Flow/AppAPI/Recording Incident Deep-Dive

Date: 2026-03-06
Status: Completed

## Summary
Expanded incident research with deeper upstream correlation and runtime state validation to isolate likely root causes and define a stable operating posture.

Output:
1. [0018-nextcloud-flow-appapi-and-recording-incident-2026-03-06.md](/Users/virgil/Dev/rita-v4/docs/research/0018-nextcloud-flow-appapi-and-recording-incident-2026-03-06.md)

## Added findings
1. ranked root-cause model for Flow lane instability
2. runtime evidence of mixed daemon state and disabled Flow heartbeat noise
3. upstream issue correlation for signature/validation failures under proxy/url mismatch classes
4. explicit standard approach for AppAPI daemon URL and single-daemon strategy
5. concrete runbook hardening actions for bounded verification and stale-runtime cleanup

## Operating recommendation
1. keep recording lane enabled and verified
2. treat Flow as optional lane until dedicated stabilization window
3. maintain HaRP-only daemon baseline and remove ambiguous alternate daemon paths
