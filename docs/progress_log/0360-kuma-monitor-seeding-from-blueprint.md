# 0360 Kuma Monitor Seeding From Blueprint

As of this update:

1. A host-side seeding script exists to create or update Uptime Kuma monitors from the canonical Pangolin monitoring blueprint.
2. The canonical endpoint source for Pangolin-exposed monitoring surfaces is:
   - `ops/pangolin/blueprints/ops-brain/monitoring.blueprint.yaml`
3. The Kuma seeding path no longer depends on the old hand-maintained `ops/monitoring/kuma/monitors.yaml` inventory for the exposed monitoring resources.

Implementation shape:

1. The script runs on the Mac host.
2. It reads Kuma admin credentials from 1Password item `kuma_ops_brain_admin`.
3. It opens a temporary SSH-backed tunnel to the in-cluster Kuma service on `ops-brain`.
4. It parses Pangolin `public-resources` and turns `full-domain` entries into HTTPS monitor URLs.
5. It creates or updates Kuma monitors by name.

Operational note:

1. This is intentionally a second-layer automation step after:
   - Helm deploys Kuma
   - Kuma first-run bootstrap is completed
2. The seeding script should be treated as the repeatable monitor inventory sync path.
