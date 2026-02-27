# Node: main-vps

## Identity
- Host alias: `main-vps`
- Role: edge VPS (k3s single-node control plane + ESO + Pangolin)
- Provider: Netcup
- Region: TBD

## Access
- SSH user: `virgil`
- SSH port: `22`
- Root access: bootstrap/break-glass only

## Specs
- CPU: TBD
- RAM: TBD
- Disk: TBD

## Network
- Public IP: `159.195.41.160`
- Public routes: see `ops/network/routes.yml`
- Expected open ports: `22`, `80`, `443`

## Runtime
- OS: Debian
- Kubernetes: k3s
- Secrets: External Secrets Operator with 1Password Service Account token

## Automation links
- Inventory: `ops/ansible/inventory/vps.ini`
- Group vars: `ops/ansible/group_vars/vps.yml`
- VPS runbooks: `scripts/2-ops/vps/`

