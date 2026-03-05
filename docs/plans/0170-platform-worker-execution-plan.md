# 0170 - Platform Worker Execution Plan
Status: ACTIVE
Date: 2026-03-01

## Goal
Execute the next platform phase in order:
1. reclaim the NUC/Proxmox lane
2. rebuild `9200` as `platform`
3. join `platform` to the existing k3s cluster as a worker
4. bootstrap `Flux` from GitHub
5. deploy shared `platform-postgres`
6. deploy `Gitea`
7. apply observability defaults
8. add declared backup-state reporting

## Freshness
Architecture and decisions:
1. [0160-platform-flux-gitea-and-worker-expansion.md](/Users/virgil/Dev/rita-v4/docs/plans/0160-platform-flux-gitea-and-worker-expansion.md)

Latest decision lock:
1. [0390-platform-flux-gitea-direction-locked.md](/Users/virgil/Dev/rita-v4/docs/progress_log/0390-platform-flux-gitea-direction-locked.md)

## Phase 0 - Reclaim And Inspect Proxmox
### Steps
1. SSH to the Proxmox host as `root`.
2. Verify host identity and uptime.
3. Verify Proxmox services are healthy:
- `pveproxy`
- `pvedaemon`
- `pvestatd`
4. List VMs and containers.
5. Inspect VM `9100`.
6. Inspect VM `9200`.
7. Inspect template `9000`.
8. Inspect datastore usage:
- `local`
- `local-lvm`
9. Verify available RAM and CPU on the host.
10. Verify bridge/network configuration used by `9100` and `9200`.

### Validation
1. Proxmox host is reachable by SSH.
2. Web UI access is restored or confirmed.
3. `9100`, `9200`, and `9000` states are known.
4. Available capacity for a rebuilt `platform` VM is known.

### Conditional
If `9200` contains any data worth preserving:
1. snapshot it
2. export/record key config
3. then continue

If `9200` is disposable:
1. proceed directly to rebuild

If `9000` is not a valid Debian 12 cloud-init template:
1. repair or recreate the template first
2. then continue

### Exit Criteria
1. host state is known
2. `9200` disposition is decided
3. template validity is confirmed

## Phase 1 - Rebuild `9200` As `platform`
### Steps
1. Rebuild or replace VM `9200` as the `platform-vm-worker` guest, with in-guest hostname `platform`.
2. Rebuild or replace VM `9200` from template `9000`.
3. Set CPU, RAM, disk, and network values for the worker VM.
4. Apply cloud-init config:
- hostname
- user
- SSH key
- network config
5. Boot the VM.
6. Verify SSH access to the guest.
7. Verify hostname inside guest is correct.
8. Verify package manager and time sync are healthy.

### Specs Validation
Record:
1. vCPU count
2. RAM allocated
3. root disk size
4. bridge/interface assignment
5. guest IP

### Conditional
If SSH access fails:
1. inspect cloud-init
2. inspect VM console
3. inspect network config
4. fix and retry

If RAM on the host is too tight:
1. reduce initial allocation
2. document the applied value
3. continue

### Exit Criteria
1. `9200` exists as clean `platform-vm-worker`
2. SSH works
3. guest specs are recorded

## Phase 2 - Bootstrap `platform` Guest
### Steps
1. Add or update inventory entry for `platform-vm-worker`.
2. Add or update host vars/group vars if needed.
3. Run base bootstrap for the guest:
- packages
- sudo/admin model
- SSH hardening as already standard in repo
- required runtime prerequisites
4. Verify reboot behavior if bootstrap requires it.
5. Verify host can be reached again after reboot.

### Validation
1. guest is reachable by the repo automation path
2. bootstrap completes without manual host edits

### Conditional
If bootstrap fails:
1. capture failing task
2. fix inventory/vars/playbook mismatch
3. rerun bootstrap

### Exit Criteria
1. `platform-vm-worker` is automation-ready

## Phase 3 - Join `platform` To The Existing k3s Cluster
### Steps
1. Verify `observatory` control plane is healthy.
2. Verify cluster token/join path is available.
3. Install k3s agent on `platform-vm-worker`.
4. Join `platform-vm-worker` to the existing cluster.
5. Verify node appears in `kubectl get nodes`.
6. Label nodes:
- `observatory` => `rita.role=observatory`
- `platform` => `rita.role=platform`
7. Verify labels exist.

### Validation
1. `platform-vm-worker` is `Ready`
2. cluster sees both nodes
3. labels are present

### Conditional
If join fails:
1. inspect token
2. inspect server endpoint
3. inspect firewall/network
4. inspect k3s agent logs
5. retry join

If `observatory` is unhealthy:
1. stop
2. repair the control plane first

### Exit Criteria
1. two-node cluster exists
2. worker role is explicit

## Phase 4 - Apply Initial Placement Rules
### Steps
1. Define node selectors/affinity for platform services.
2. Keep monitoring workloads anchored to `observatory`.
3. Configure `Flux`, `Gitea`, and `platform-postgres` to prefer `platform`.
4. Defer taints unless needed immediately.

### Validation
1. placement rules exist in manifests
2. `observatory` remains the preferred monitoring home

### Conditional
If the worker is unstable:
1. keep placement soft with preferred affinity
2. do not add taints yet

If the worker is stable and capacity is adequate:
1. continue with platform placement defaults

### Exit Criteria
1. placement policy is encoded before platform apps land

## Phase 5 - Bootstrap Flux From GitHub
### Steps
1. Choose the GitHub repo/path Flux will own.
2. Define the initial Flux directory layout in repo.
3. Create Flux bootstrap manifests or bootstrap command path.
4. Install Flux into the cluster.
5. Verify controllers are healthy.
6. Verify Flux can reconcile from GitHub.
7. Commit the initial platform tree.

### Validation
1. Flux controllers are healthy
2. reconciliation succeeds
3. GitHub is the active source

### Conditional
If bootstrap auth to GitHub fails:
1. fix deploy key/token/credential path
2. retry bootstrap

If reconciliation fails:
1. inspect Flux objects and controller logs
2. fix manifest/layout issues
3. reconcile again

### Exit Criteria
1. Flux owns the platform lane

## Phase 6 - Deploy Shared `platform-postgres`
### Steps
1. Choose chart/operator/package for Postgres.
2. Create namespace and manifests.
3. Define storage request.
4. Define service name: `platform-postgres`.
5. Create initial database and role contract for `Gitea`.
6. Create Kubernetes secrets for DB access.
7. Deploy Postgres through Flux.
8. Verify pod, PVC, service, and readiness.
9. Verify login and DB creation.

### Specs Validation
Record:
1. chart/operator choice
2. version
3. PVC size
4. storage class
5. service name

### Conditional
If storage provisioning fails:
1. inspect storage class and PVC events
2. correct the claim
3. redeploy

If resource pressure is high:
1. reduce requests/limits
2. keep the deployment single-instance
3. continue

### Exit Criteria
1. shared Postgres is healthy
2. Gitea DB contract exists

## Phase 7 - Deploy `Gitea`
### Steps
1. Choose chart/package for `Gitea`.
2. Create namespace and manifests.
3. Point `Gitea` at `platform-postgres`.
4. Create/apply required secrets.
5. Define ingress/exposure path.
6. Define node affinity toward `platform`.
7. Deploy through Flux.
8. Verify pods, service, PVCs, and app readiness.
9. Verify initial admin/bootstrap flow.

### Validation
1. `Gitea` is healthy
2. DB connection works
3. repo creation/login path works

### Conditional
If `Gitea` schedules onto `observatory` unexpectedly:
1. tighten node affinity/selectors
2. reconcile again

If DB migrations fail:
1. inspect app logs
2. verify DB credentials and schema permissions
3. rerun after correction

### Exit Criteria
1. `Gitea` is running on-cluster against Postgres

## Phase 8 - Apply Observability Defaults
### Steps
1. Define monitoring/logging metadata contract for new services.
2. Apply it to `platform-postgres`.
3. Apply it to `Gitea`.
4. Add scrape config if available.
5. Add uptime checks if appropriate.
6. Verify logs/metrics/health visibility.

### Validation
1. platform services appear in the monitoring lane
2. missing observability is visible

### Conditional
If a service has no easy metrics endpoint:
1. keep basic readiness/liveness and uptime visibility
2. document the gap

### Exit Criteria
1. observability is part of the deployment baseline

## Phase 9 - Add Backup-State Reporting
### Steps
1. Define backup metadata fields for stateful apps.
2. Mark `platform-postgres` and `Gitea` as stateful.
3. Mark current backup state as intentionally unimplemented.
4. Add automated reporting or validation output.
5. Verify the report surfaces the lack of real backups.

### Validation
1. stateful services are declared
2. missing backups are explicit

### Conditional
If the reporting path is not yet automated:
1. create a static declaration first
2. add automation in a later pass

### Exit Criteria
1. clown backup state is visible and tracked

## Phase 10 - Off-The-Shelf App Readiness Gate
### Steps
1. Verify worker capacity is stable.
2. Verify Flux reconciliation remains healthy.
3. Verify `Gitea` is usable.
4. Verify Postgres is usable for another app DB.
5. Verify observability defaults are reusable.
6. Verify storage declarations exist for stateful apps.

### Validation
1. platform lane is ready for first off-the-shelf app

### Exit Criteria
1. cluster is ready to onboard the next app

## Deliverables Checklist
1. reclaimed Proxmox host state
2. rebuilt `9200` as `platform`
3. automation-ready guest
4. joined k3s worker
5. node labels applied
6. Flux bootstrapped from GitHub
7. shared `platform-postgres`
8. `Gitea`
9. observability defaults
10. backup-state declarations

## Blocking Conditions
Stop and resolve before continuing if:
1. Proxmox host health is unknown
2. `9000` template is invalid
3. `observatory` control plane is unhealthy
4. `platform` cannot join the cluster
5. Flux cannot reconcile from GitHub
6. Postgres cannot provision storage
7. `Gitea` cannot complete DB-backed startup
