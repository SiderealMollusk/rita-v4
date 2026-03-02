# Platform GitOps Tree

This tree is the first internal-cluster GitOps lane.

Bootstrap target:
1. `scripts/2-ops/worker/06-bootstrap-flux-github.sh`
2. Flux path: `ops/gitops/clusters/internal`
3. Bootstrap defaults: `ops/gitops/flux-bootstrap.yml`

Current ownership:
1. `ops/gitops/clusters/internal/`
- top-level cluster reconciliation target
2. `ops/gitops/platform/namespaces/`
- namespace declarations
3. `ops/gitops/platform/sources/`
- Helm repositories and secret-store plumbing
4. `ops/gitops/platform/apps/`
- platform services (`platform-postgres`, `gitea`)
5. `ops/gitops/platform/observability/`
- declared observability defaults and targets
6. `ops/gitops/platform/backup-state/`
- explicit stateful-service backup declarations
