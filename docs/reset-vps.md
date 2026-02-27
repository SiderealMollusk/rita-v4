# Reset VPS Playbook

Validated: 2026-02-27

## Goal
Factory reset the VPS, restore SSH admin access, and return to the Pangolin-server install flow.

## Human Steps
1. Open `https://www.servercontrolpanel.de/SCP/Home`
2. Go to `Media`
3. Trigger `Reset`
4. Wait for reset/reinstall to finish
5. Copy the new status page details into 1Password
- IP
- root password
- reset timestamp
- hostname/image notes if shown

## Re-seed SSH Access
Run from your Mac host terminal:

```bash
/Users/virgil/Dev/rita-v4/scripts/0-local-setup/03-vps/01-seed-ssh-admin-from-op.sh 159.195.41.160 virgil
```

Then test:

```bash
ssh virgil@159.195.41.160
```

## VPS Bring-Up
Run from repo:

```bash
scripts/2-ops/vps/01-ansible-ping.sh
scripts/2-ops/vps/02-bootstrap-host.sh
scripts/2-ops/vps/03-install-runtime.sh
scripts/2-ops/vps/04-install-pangolin-server.sh
```

## Interactive Installer
Run on the VPS:

```bash
chmod +x /home/virgil/installer
sudo /home/virgil/installer
cd /home/virgil && docker compose up -d
```

## Post-Install
Back in repo:

```bash
scripts/2-ops/vps/05-capture-setup-token.sh
scripts/2-ops/vps/06-verify-pangolin-server.sh
```

## Store in 1Password
1. root password
2. VPS IP
3. reset timestamp
4. Pangolin setup token
