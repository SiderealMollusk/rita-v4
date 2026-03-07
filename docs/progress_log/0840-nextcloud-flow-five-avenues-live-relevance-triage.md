# 0840 - Nextcloud Flow 5-Avenues Live Relevance Triage

Date: 2026-03-06
Status: Completed

## Summary
Executed live-state validation against the five researched incident avenues and ranked actual relevance by evidence.

Output:
1. [0018-nextcloud-flow-appapi-and-recording-incident-2026-03-06.md](/Users/virgil/Dev/rita-v4/docs/research/0018-nextcloud-flow-appapi-and-recording-incident-2026-03-06.md)

## Relevance ranking
1. high: disabled Flow heartbeat retry noise
2. high: mixed daemon state / NC URL boundary risk
3. high: verify false negatives from unbounded tails + daemon ambiguity
4. partial: HaRP/AppAPI version skew (drift risk)
5. partial: Flow OSS bootstrap/security-key class (relevant on re-enable)

## Notable live evidence
1. two app_api daemons registered with different NC URLs (`harp_local_vm` local URL; `docker_local_vm` public URL)
2. Flow still registered as disabled and heartbeat-related log spam present
3. verify script currently uses broad tail windows without since-time bounds
