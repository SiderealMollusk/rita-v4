#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  01-seed-ssh-admin-from-op.sh <vps_host_or_ip> [admin_user]

Description:
  - Connects to a fresh VPS as root (password login expected for first run).
  - Pulls SSH public key from 1Password.
  - Installs the key for root and the admin user.
  - Creates the admin user if missing.
  - Adds admin user to sudo and enables passwordless sudo for automation.

Environment (optional):
  OP_SSH_ADMIN_KEY_VAULT_ID   Default: ss5mpavcq4io5mia5o4qjpaoxm
  OP_SSH_ADMIN_KEY_ITEM_ID    Default: ysxpb5pitwbmawcdtecicag2dy
USAGE
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  usage
  exit 1
fi

TARGET_HOST="$1"
ADMIN_USER="${2:-virgil}"

OP_SSH_ADMIN_KEY_VAULT_ID="${OP_SSH_ADMIN_KEY_VAULT_ID:-ss5mpavcq4io5mia5o4qjpaoxm}"
OP_SSH_ADMIN_KEY_ITEM_ID="${OP_SSH_ADMIN_KEY_ITEM_ID:-ysxpb5pitwbmawcdtecicag2dy}"

command -v op >/dev/null 2>&1 || { echo "[FAIL] missing command: op"; exit 1; }
command -v ssh >/dev/null 2>&1 || { echo "[FAIL] missing command: ssh"; exit 1; }
command -v ssh-keygen >/dev/null 2>&1 || { echo "[FAIL] missing command: ssh-keygen"; exit 1; }

# Host-only guard: this script is intended for the Mac host shell.
if [ -f /.dockerenv ] || grep -q 'docker\|containerd' /proc/1/cgroup 2>/dev/null; then
  echo "[FAIL] Run this script from your Mac host terminal, not inside the devcontainer."
  exit 1
fi

if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "[INFO] Using 1Password service-account context"
else
  echo "[INFO] Verifying 1Password CLI session..."
  op whoami >/dev/null
fi

echo "[INFO] Reading public key from vault=$OP_SSH_ADMIN_KEY_VAULT_ID item=$OP_SSH_ADMIN_KEY_ITEM_ID"
PUB_KEY="$(op item get "$OP_SSH_ADMIN_KEY_ITEM_ID" \
  --vault "$OP_SSH_ADMIN_KEY_VAULT_ID" \
  --fields label='public key')"

[ -n "$PUB_KEY" ] || { echo "[FAIL] failed to read public key from 1Password"; exit 1; }
KEY_B64="$(printf '%s' "$PUB_KEY" | base64 | tr -d '\n')"

echo "[INFO] Resetting stale known_hosts entries for ${TARGET_HOST} (common after VPS rebuild)..."
ssh-keygen -R "$TARGET_HOST" >/dev/null 2>&1 || true
ssh-keygen -R "[${TARGET_HOST}]:22" >/dev/null 2>&1 || true

echo "[INFO] Connecting to root@${TARGET_HOST} (password prompt expected on fresh VPS)..."
ssh -o StrictHostKeyChecking=accept-new "root@${TARGET_HOST}" "ADMIN_USER='$ADMIN_USER' KEY_B64='$KEY_B64' bash -s" <<'REMOTE'
set -euo pipefail

install_key_for_user() {
  local user_name="$1"
  local home_dir
  home_dir="$(getent passwd "$user_name" | cut -d: -f6)"
  [ -n "$home_dir" ] || return 1

  install -d -m 700 "$home_dir/.ssh"
  touch "$home_dir/.ssh/authorized_keys"
  chmod 600 "$home_dir/.ssh/authorized_keys"

  if ! grep -qxF "$PUB_KEY" "$home_dir/.ssh/authorized_keys"; then
    printf '%s\n' "$PUB_KEY" >> "$home_dir/.ssh/authorized_keys"
  fi

  if [ "$user_name" != "root" ]; then
    chown -R "$user_name:$user_name" "$home_dir/.ssh"
  fi
}

PUB_KEY="$(printf '%s' "$KEY_B64" | base64 -d)"

# Ensure admin user exists and has sudo group membership.
if ! id "$ADMIN_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$ADMIN_USER"
fi
usermod -aG sudo "$ADMIN_USER"

# Install keys for root and admin user.
install_key_for_user root
install_key_for_user "$ADMIN_USER"

# Allow passwordless sudo for automation.
SUDO_FILE="/etc/sudoers.d/90-${ADMIN_USER}-nopasswd"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$ADMIN_USER" > "$SUDO_FILE"
chmod 440 "$SUDO_FILE"
visudo -cf "$SUDO_FILE"

echo "[OK] SSH key installed for root and $ADMIN_USER; sudo configured."
REMOTE

echo "[OK] Done. Test with:"
echo "     ssh ${ADMIN_USER}@${TARGET_HOST}"
