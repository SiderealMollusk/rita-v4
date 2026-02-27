# Node: main-vps

## Identity
- Host alias: `main-vps`
- Role: public edge runtime
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
- Expected open ports: `22`, `80`, `443`, `51820/udp`, `21820/udp`

## Runtime
- OS: Debian
- Runtime: Docker + Docker Compose v2
- Primary service: `pangolin-server`
- Secrets: 1Password for admin/setup tokens and operational secrets

## Automation links
- Inventory: `ops/ansible/inventory/vps.ini`
- Group vars: `ops/ansible/group_vars/vps.yml`
- VPS runbooks: `scripts/2-ops/vps/`
