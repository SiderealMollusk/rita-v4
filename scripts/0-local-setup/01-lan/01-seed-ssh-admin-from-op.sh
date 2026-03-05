#!/bin/bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  01-seed-ssh-admin-from-op.sh <host_or_ip> [admin_user]

Description:
  - Connects to a fresh or reset LAN host as root (password login expected).
  - Pulls SSH public key from 1Password.
  - Ensures the admin user exists.
  - Installs the key for root and the admin user.
  - Enables passwordless sudo for automation.

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
command -v ssh-keyscan >/dev/null 2>&1 || { echo "[FAIL] missing command: ssh-keyscan"; exit 1; }

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

echo "[INFO] Resetting stale known_hosts entries for ${TARGET_HOST}..."
ssh-keygen -R "$TARGET_HOST" >/dev/null 2>&1 || true
ssh-keygen -R "[${TARGET_HOST}]:22" >/dev/null 2>&1 || true
ssh-keyscan -H "$TARGET_HOST" >> "${HOME}/.ssh/known_hosts" 2>/dev/null || true

echo "[INFO] Connecting to root@${TARGET_HOST} (password prompt expected on fresh host)..."
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

if ! id "$ADMIN_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "" "$ADMIN_USER"
fi
usermod -aG sudo "$ADMIN_USER"

install_key_for_user root
install_key_for_user "$ADMIN_USER"

SUDO_FILE="/etc/sudoers.d/90-${ADMIN_USER}-nopasswd"
printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$ADMIN_USER" > "$SUDO_FILE"
chmod 440 "$SUDO_FILE"
visudo -cf "$SUDO_FILE"

echo "[OK] SSH key installed for root and $ADMIN_USER; sudo configured."
REMOTE

echo "[INFO] Verifying key-based SSH for ${ADMIN_USER}@${TARGET_HOST}"
ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "${ADMIN_USER}@${TARGET_HOST}" "true" >/dev/null

echo "[OK] Done. Test with:"
echo "     ssh ${ADMIN_USER}@${TARGET_HOST}"
