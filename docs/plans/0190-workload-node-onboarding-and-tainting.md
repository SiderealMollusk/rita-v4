# 0190 - Workload Node Onboarding And Tainting
Status: DRAFT
Date: 2026-03-02

## Goal
Turn the current server-side Proxmox substrate into a real, repo-managed `workload-node` lane and decide whether the cluster should move from label-only placement into explicit taints/tolerations.

This phase exists because the current screenshot-visible server is only a candidate substrate.
It is not yet a proven workload lane in repo terms.

## Freshness
Start with the latest relevant progress note before trusting this plan:
1. [0420-flux-bootstrap-complete-and-cluster-network-policy-codified.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0420-flux-bootstrap-complete-and-cluster-network-policy-codified.md)

## Current State
What is true now:
1. the internal cluster is healthy
2. `ops-brain` is the control plane and monitoring home
3. `platform` is the first real worker
4. Flux bootstrap is complete and reconciling
5. platform services can now start landing on the cluster

What is not yet true:
1. the server-side Proxmox host is not yet codified as the real `workload-node` substrate
2. no server-side worker VM has been durably onboarded into repo inventory and runbooks
3. taints have not been applied anywhere
4. scheduling still depends on labels, placement intent, and current capacity rather than hard isolation

## Why This Phase Exists
The current architecture says:
1. `platform-node` should host platform services
2. `workload-node` should host app and compute workloads

But the actual cluster only has:
1. `ops-brain`
2. `platform`

So before calling the system truly app-ready for heavier or more isolated workloads, the workload lane itself must become real.

This phase also intentionally keeps two unfinished concerns separate:
1. onboarding the workload lane as a clean cluster worker
2. deciding whether workload-local `Newt` should terminate routes directly on the server side

The second concern may become worth it later for route locality and heavy traffic, but it should not be coupled into first-pass worker onboarding.

## Questions This Phase Must Resolve
1. what is the canonical substrate identity for the server-side Proxmox host?
2. what is the canonical guest identity for the future workload worker VM?
3. should the existing `9300 (docker-worker-big)` VM be reused, renamed, or rebuilt?
4. does the workload lane join the current internal cluster as another worker, or remain outside it?
5. when should taints be introduced, and on which nodes?
6. when, if ever, should workload-local `Newt` be introduced?

## Recommended Answers
1. treat the server-side Proxmox box as the `workload-node` substrate
2. onboard a dedicated worker VM, not a generic leftover host name
3. prefer rebuilding or renaming the current `9300` guest into a clean workload worker identity before cluster onboarding
4. join the current internal cluster as a worker rather than creating a second internal cluster
5. add taints only after the workload worker is healthy and verified
6. defer workload-local `Newt` until the workload lane itself is proven under real app placement

## Scope
### In Scope
1. formalize the server-side Proxmox substrate in repo inventory
2. formalize the workload worker guest identity
3. define and apply the worker onboarding path
4. encode firewall/network rules required for Flannel and cluster traffic
5. verify the workload worker joins the internal cluster cleanly
6. define and apply the first tainting policy if the new worker is stable
7. update placement guidance so app deployment has a real workload target

### Out Of Scope
1. shared app auth
2. final storage/NAS architecture
3. GPU-specific workload tuning
4. full app onboarding catalog
5. large-scale autoscaling or multi-environment strategy
6. workload-local `Newt` during initial worker onboarding

## Relation To Larger Plan
This phase follows:
1. [0160-platform-flux-gitea-and-worker-expansion.md](/Users/virgil/Dev/rita-v4/docs/plans/0160-platform-flux-gitea-and-worker-expansion.md)
2. [0170-platform-worker-execution-plan.md](/Users/virgil/Dev/rita-v4/docs/plans/0170-platform-worker-execution-plan.md)
3. [0180-flux-bootstrap-and-initial-platform-services.md](/Users/virgil/Dev/rita-v4/docs/plans/0180-flux-bootstrap-and-initial-platform-services.md)

It advances the architecture by:
1. making the planned `workload-node` real
2. separating app/compute scheduling from platform-service scheduling
3. enabling taints as real guardrails instead of continuing indefinitely with soft placement only

## Success Criteria
This phase is successful when:
1. the workload substrate exists in inventory and node docs
2. the workload worker VM exists as a clean and intentional identity
3. the workload worker joins the internal cluster and is `Ready`
4. inter-node networking works without manual firewall edits
5. placement policy for platform vs workload is explicit
6. taints are either applied or consciously deferred with a documented reason

## The Play
### Stage 1 - Formalize The Workload Substrate
1. decide the canonical inventory identity for the server-side Proxmox host
2. add the substrate to `ops/ansible/inventory/proxmox.ini`
3. add machine-specific `host_vars`
4. update `docs/nodes/workload-node.md` if the substrate identity changes
5. add any needed Proxmox-side rebuild/inspection runbooks if the current NUC patterns are being reused

### Stage 2 - Decide The Workload Guest Identity
1. inspect the current server-side VM inventory
2. determine whether `9300 (docker-worker-big)` should:
- be reused in place
- be renamed and cleaned
- be rebuilt from template
3. choose the canonical worker identity
4. define its intended hostname, IP, and role

Recommended outcome:
1. a dedicated workload worker VM identity, not a generic “docker worker” placeholder

### Stage 3 - Add Canonical Repo State
1. add the workload worker to inventory
2. add any needed `host_vars`
3. update cluster-wide group vars if the node joins the internal cluster
4. update firewall allowlists for:
- k3s API if needed
- Flannel VXLAN `udp/8472`
5. update `docs/adding-a-machine.md` references if a new reusable pattern appears

### Stage 4 - Bootstrap And Join
1. bootstrap the workload worker host baseline
2. install/join k3s agent
3. apply labels
4. verify the node becomes `Ready`
5. verify cross-node pod/service traffic works

### Stage 5 - Placement Decision
1. verify that `platform` can continue to host platform services cleanly
2. verify that the workload worker has enough capacity for real app placement
3. decide whether the next app should land on:
- `platform`
- `workload`
- either, via affinity/preference

### Stage 5.5 - Workload-Local Newt Decision
Do not make workload-local `Newt` part of first-pass worker onboarding.

Decision rule:
1. if the workload lane is only cluster capacity, skip `Newt`
2. if the workload lane starts serving heavy user-facing traffic, media, model APIs, or other locality-sensitive routes, treat workload-local `Newt` as the next networking phase

The point of sequencing here is to avoid coupling:
1. worker onboarding and cluster validation
2. route-locality optimization and Newt site lifecycle

### Stage 6 - Tainting Decision
Do not taint before the workload worker is healthy.

Once healthy, choose one of these models:

#### Option A - Soft Placement Only
Use:
1. labels
2. node affinity / preferred placement

Choose this if:
1. the cluster is still small
2. recovery flexibility matters more than hard isolation
3. you are still proving app behavior

#### Option B - Taint `ops-brain`
Use:
1. `ops-brain` tainted away from normal app workloads
2. tolerations only for monitoring/control-plane-adjacent workloads

Choose this if:
1. you want to protect the control-plane laptop first
2. `platform` and `workload` are both healthy enough to absorb regular workloads

#### Option C - Taint `platform` And `workload` By Role
Use:
1. `platform` tainted for platform services
2. `workload` tainted for app/compute workloads

Choose this if:
1. you want hard isolation between platform and app layers
2. you are willing to manage tolerations intentionally
3. your placement model is stable enough that the operational overhead is justified

## Recommended Tainting Sequence
1. first add the workload worker
2. verify the workload worker is stable under real cross-node traffic
3. then taint `ops-brain` first
4. treat `platform` as platform-services-first capacity, not the default app lane
5. move general app workloads toward `workload`
6. defer `platform` vs `workload` hard taints until there are real workloads that justify the complexity

This means the first likely taint is:
1. reserve `ops-brain` away from arbitrary app workloads

Current intended placement policy:
1. no general application workloads on `ops-brain`
2. no default spillover of general application workloads onto `platform`
3. `workload` is the intended default home for general workloads once app placement begins

## Verification
### Substrate Verification
1. Proxmox host is reachable by canonical inventory identity
2. intended guest exists or can be rebuilt cleanly
3. inventory and host vars match reality

### Worker Verification
1. `kubectl get nodes -o wide`
2. `kubectl get nodes --show-labels`
3. pod-to-service and cross-node traffic checks
4. firewall state on both sides

Pass condition:
1. node is `Ready`
2. labels are correct
3. Flannel traffic is working

### Taint Verification
1. `kubectl describe node <node>`
2. deploy a simple test workload without tolerations
3. confirm it lands only on intended nodes
4. deploy a toleration-aware test workload if needed

Pass condition:
1. scheduling behavior matches intent
2. the taints do not strand critical services

## Risks
1. reusing a dirty VM identity can carry hidden drift forward
2. premature tainting can make the small cluster awkward to operate
3. hard role isolation before the workload lane is proven can create more complexity than value
4. literal firewall allowlists may drift unless later derived from inventory
5. adding workload-local `Newt` too early can blur worker-onboarding failures with route-topology failures

## Deliverables
1. real workload substrate identity in repo
2. real workload worker identity in repo
3. workload worker join path
4. verified cross-node networking
5. explicit tainting decision
6. updated placement guidance for real app onboarding

## Immediate Next Actions
1. inspect the actual server-side Proxmox host and guest state
2. decide whether to rebuild or reuse the current `9300` VM
3. formalize workload substrate and guest identities in inventory and docs
4. onboard the workload worker as a real k3s worker
5. only then decide whether to taint `ops-brain`
6. revisit workload-local `Newt` only after the workload lane is proven under real app placement
