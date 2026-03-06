#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/runbook.sh"

REPO_ROOT="$(runbook_detect_repo_root)"
INVENTORY_PATH=""
HOST_ALIAS=""
BECOME_PASSWORD=""
BECOME_PASSWORD_OP_REF=""

usage() {
  cat <<'EOF'
Usage:
  disable-machine-sleep.sh --inventory <path> --host-alias <alias>
                          [--become-password <value>]
                          [--become-password-op-ref <op://...>]

Description:
  Hard-disables system sleep/hibernate targets and ignores all lid actions.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --inventory)
      INVENTORY_PATH="${2:-}"
      shift 2
      ;;
    --host-alias)
      HOST_ALIAS="${2:-}"
      shift 2
      ;;
    --become-password)
      BECOME_PASSWORD="${2:-}"
      shift 2
      ;;
    --become-password-op-ref)
      BECOME_PASSWORD_OP_REF="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      runbook_fail "Unknown argument: $1"
      ;;
  esac
done

[ -n "$INVENTORY_PATH" ] || runbook_fail "--inventory is required"
[ -n "$HOST_ALIAS" ] || runbook_fail "--host-alias is required"

if [ ! -f "$INVENTORY_PATH" ]; then
  if [ -f "$REPO_ROOT/$INVENTORY_PATH" ]; then
    INVENTORY_PATH="$REPO_ROOT/$INVENTORY_PATH"
  else
    runbook_fail "inventory file not found: $INVENTORY_PATH"
  fi
fi

runbook_require_cmd ansible

ANSIBLE_BECOME_ARGS=()
if [ "${RUNBOOK_ASK_BECOME_PASS:-0}" = "1" ]; then
  ANSIBLE_BECOME_ARGS+=(-K)
fi

if [ -z "$BECOME_PASSWORD" ] && [ -n "$BECOME_PASSWORD_OP_REF" ]; then
  runbook_require_op_access
  BECOME_PASSWORD="$(runbook_resolve_secret_from_op "" "$BECOME_PASSWORD_OP_REF")"
fi

ANSIBLE_EXTRA_ARGS=()
VARS_FILE=""
if [ -n "$BECOME_PASSWORD" ]; then
  VARS_FILE="$(mktemp)"
  cat >"$VARS_FILE" <<EOF
{"ansible_become_password":"$BECOME_PASSWORD"}
EOF
  ANSIBLE_EXTRA_ARGS+=(-e "@$VARS_FILE")
fi

echo "[INFO] Disabling sleep/lid actions on host: $HOST_ALIAS"
echo "[INFO] Inventory: $INVENTORY_PATH"

ANSIBLE_CMD=(ansible -i "$INVENTORY_PATH" "$HOST_ALIAS" -b -m shell -a "set -eu
install -d -m 0755 /etc/systemd/logind.conf.d
install -d -m 0755 /etc/systemd/sleep.conf.d

cat >/etc/systemd/logind.conf.d/90-rita-no-lid-sleep.conf <<'EOF_LOGIND'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
HandleSuspendKey=ignore
HandleHibernateKey=ignore
IdleAction=ignore
EOF_LOGIND

cat >/etc/systemd/sleep.conf.d/90-rita-disable-sleep.conf <<'EOF_SLEEP'
[Sleep]
AllowSuspend=no
AllowHibernation=no
AllowSuspendThenHibernate=no
AllowHybridSleep=no
EOF_SLEEP

if [ -f /etc/UPower/UPower.conf ]; then
  python3 - <<'PY'
from pathlib import Path
path = Path('/etc/UPower/UPower.conf')
text = path.read_text(encoding='utf-8')
if 'IgnoreLid=' in text:
    lines = []
    for line in text.splitlines():
        if line.strip().startswith('IgnoreLid='):
            lines.append('IgnoreLid=true')
        else:
            lines.append(line)
    text = '\\n'.join(lines) + '\\n'
else:
    text += '\\nIgnoreLid=true\\n'
path.write_text(text, encoding='utf-8')
PY
fi

systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
systemctl daemon-reload
systemctl restart systemd-logind || true
systemctl restart upower || true

systemctl is-enabled sleep.target | grep -q masked
systemctl is-enabled suspend.target | grep -q masked
systemctl is-enabled hibernate.target | grep -q masked
systemctl is-enabled hybrid-sleep.target | grep -q masked
grep -Eq '^HandleLidSwitch=ignore$' /etc/systemd/logind.conf.d/90-rita-no-lid-sleep.conf
grep -Eq '^AllowSuspend=no$' /etc/systemd/sleep.conf.d/90-rita-disable-sleep.conf
")

if [ "${#ANSIBLE_BECOME_ARGS[@]}" -gt 0 ]; then
  ANSIBLE_CMD=("${ANSIBLE_CMD[@]:0:1}" "${ANSIBLE_BECOME_ARGS[@]}" "${ANSIBLE_CMD[@]:1}")
fi
if [ "${#ANSIBLE_EXTRA_ARGS[@]}" -gt 0 ]; then
  ANSIBLE_CMD=("${ANSIBLE_CMD[@]:0:1}" "${ANSIBLE_EXTRA_ARGS[@]}" "${ANSIBLE_CMD[@]:1}")
fi

"${ANSIBLE_CMD[@]}"

if [ -n "$VARS_FILE" ]; then
  rm -f "$VARS_FILE"
fi

echo "[OK] Sleep and lid-triggered suspend are disabled on $HOST_ALIAS."
