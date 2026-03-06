#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/runbook.sh"

usage() {
  cat <<'EOF'
Usage:
  validate-machine-sot.sh --lan-ip <ip> [--repo-root <path>] [--host-alias <alias>] [--inventory-file <path>]

Description:
  Validates machine-level source-of-truth consistency for a host identified by LAN IP.
EOF
}

LAN_IP=""
REPO_ROOT=""
HOST_ALIAS_FILTER=""
INVENTORY_FILE_FILTER=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --lan-ip)
      [ "$#" -ge 2 ] || runbook_fail "--lan-ip requires a value"
      LAN_IP="$2"
      shift 2
      ;;
    --repo-root)
      [ "$#" -ge 2 ] || runbook_fail "--repo-root requires a value"
      REPO_ROOT="$2"
      shift 2
      ;;
    --host-alias)
      [ "$#" -ge 2 ] || runbook_fail "--host-alias requires a value"
      HOST_ALIAS_FILTER="$2"
      shift 2
      ;;
    --inventory-file)
      [ "$#" -ge 2 ] || runbook_fail "--inventory-file requires a value"
      INVENTORY_FILE_FILTER="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      runbook_fail "unknown argument: $1"
      ;;
  esac
done

[ -n "$LAN_IP" ] || runbook_fail "--lan-ip is required"
REPO_ROOT="${REPO_ROOT:-$(runbook_detect_repo_root)}"

runbook_require_cmd grep
runbook_require_cmd python3
runbook_require_cmd nc
runbook_require_cmd ssh

INVENTORY_DIR="$REPO_ROOT/ops/ansible/inventory"
HOST_VARS_DIR="$REPO_ROOT/ops/ansible/host_vars"
REQUIRED_SITES_FILE="$REPO_ROOT/ops/pangolin/sites/required-sites.yaml"
LAB_NODES_FILE="$REPO_ROOT/docs/platform/lab-nodes.md"
NODES_DIR="$REPO_ROOT/docs/nodes"

[ -d "$INVENTORY_DIR" ] || runbook_fail "missing inventory dir: $INVENTORY_DIR"
[ -d "$HOST_VARS_DIR" ] || runbook_fail "missing host_vars dir: $HOST_VARS_DIR"
[ -f "$REQUIRED_SITES_FILE" ] || runbook_fail "missing required sites file: $REQUIRED_SITES_FILE"
[ -f "$LAB_NODES_FILE" ] || runbook_fail "missing lab nodes file: $LAB_NODES_FILE"
[ -d "$NODES_DIR" ] || runbook_fail "missing nodes dir: $NODES_DIR"

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

pass() {
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "[PASS] $*"
}

fail() {
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "[FAIL] $*"
}

warn() {
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "[WARN] $*"
}

echo "[INFO] Validating machine SoT for LAN IP: $LAN_IP"
echo "[INFO] Repo root: $REPO_ROOT"

MATCHES_JSON="$(python3 - "$INVENTORY_DIR" "$LAN_IP" <<'PY'
import json
import pathlib
import sys

inventory_dir = pathlib.Path(sys.argv[1])
lan_ip = sys.argv[2]
matches = []

for inv in sorted(inventory_dir.glob("*.ini")):
    for raw in inv.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("["):
            continue
        parts = line.split()
        host_alias = parts[0]
        fields = {}
        for token in parts[1:]:
            if "=" in token:
                k, v = token.split("=", 1)
                fields[k] = v
        if fields.get("ansible_host") == lan_ip:
            matches.append(
                {
                    "inventory_file": str(inv),
                    "inventory_rel": str(inv).split("ops/ansible/inventory/", 1)[-1],
                    "host_alias": host_alias,
                    "ansible_user": fields.get("ansible_user", ""),
                    "ansible_port": fields.get("ansible_port", "22"),
                }
            )

print(json.dumps(matches))
PY
)"

if [ -n "$HOST_ALIAS_FILTER" ]; then
  MATCHES_JSON="$(python3 - "$MATCHES_JSON" "$HOST_ALIAS_FILTER" <<'PY'
import json
import sys

matches = json.loads(sys.argv[1])
host_alias = sys.argv[2]
filtered = [m for m in matches if m.get("host_alias") == host_alias]
print(json.dumps(filtered))
PY
)"
fi

if [ -n "$INVENTORY_FILE_FILTER" ]; then
  MATCHES_JSON="$(python3 - "$MATCHES_JSON" "$INVENTORY_FILE_FILTER" <<'PY'
import json
import os
import sys

matches = json.loads(sys.argv[1])
needle = sys.argv[2]
needle = os.path.normpath(needle)
filtered = []
for m in matches:
    abs_path = os.path.normpath(m.get("inventory_file", ""))
    rel_path = os.path.normpath("ops/ansible/inventory/" + m.get("inventory_rel", ""))
    if needle == abs_path or needle == rel_path or needle == m.get("inventory_rel", ""):
        filtered.append(m)
print(json.dumps(filtered))
PY
)"
fi

MATCH_COUNT="$(python3 - "$MATCHES_JSON" <<'PY'
import json
import sys
print(len(json.loads(sys.argv[1])))
PY
)"

if [ "$MATCH_COUNT" -eq 0 ]; then
  fail "inventory_identity: no host found with ansible_host=$LAN_IP"
  echo
  echo "[SUMMARY] pass=$PASS_COUNT fail=$FAIL_COUNT warn=$WARN_COUNT"
  exit 1
fi

if [ "$MATCH_COUNT" -gt 1 ]; then
  warn "inventory_identity: multiple inventory matches for $LAN_IP after filtering; using first sorted match"
fi

HOST_ALIAS="$(python3 - "$MATCHES_JSON" <<'PY'
import json
import sys
print(json.loads(sys.argv[1])[0]["host_alias"])
PY
)"
INVENTORY_FILE_ABS="$(python3 - "$MATCHES_JSON" <<'PY'
import json
import sys
print(json.loads(sys.argv[1])[0]["inventory_file"])
PY
)"
INVENTORY_FILE_REL="ops/ansible/inventory/$(python3 - "$MATCHES_JSON" <<'PY'
import json
import sys
print(json.loads(sys.argv[1])[0]["inventory_rel"])
PY
)"
ANSIBLE_USER="$(python3 - "$MATCHES_JSON" <<'PY'
import json
import sys
print(json.loads(sys.argv[1])[0]["ansible_user"])
PY
)"
ANSIBLE_PORT="$(python3 - "$MATCHES_JSON" <<'PY'
import json
import sys
print(json.loads(sys.argv[1])[0]["ansible_port"])
PY
)"

[ -n "$ANSIBLE_USER" ] || ANSIBLE_USER="virgil"
[ -n "$ANSIBLE_PORT" ] || ANSIBLE_PORT="22"

pass "inventory_identity: $HOST_ALIAS in $INVENTORY_FILE_REL ($ANSIBLE_USER@$LAN_IP:$ANSIBLE_PORT)"

HOST_VARS_FILE="$HOST_VARS_DIR/$HOST_ALIAS.yml"
if [ -f "$HOST_VARS_FILE" ]; then
  pass "host_vars_present: ops/ansible/host_vars/$HOST_ALIAS.yml"
else
  fail "host_vars_present: missing ops/ansible/host_vars/$HOST_ALIAS.yml"
fi

SITE_JSON="$(python3 - "$REQUIRED_SITES_FILE" "$HOST_ALIAS" "$INVENTORY_FILE_REL" <<'PY'
import json
import sys

site_file = sys.argv[1]
host_alias = sys.argv[2]
inventory_file = sys.argv[3]
records = json.loads(open(site_file, "r", encoding="utf-8").read())

match = None
for r in records:
    if r.get("host_alias") == host_alias and r.get("inventory_file") == inventory_file:
        match = r
        break

print(json.dumps(match if match is not None else {}))
PY
)"

SITE_FOUND="$(python3 - "$SITE_JSON" <<'PY'
import json
import sys
obj = json.loads(sys.argv[1])
print("yes" if obj else "no")
PY
)"

if [ "$SITE_FOUND" = "yes" ]; then
  SITE_SLUG="$(python3 - "$SITE_JSON" <<'PY'
import json
import sys
print(json.loads(sys.argv[1]).get("slug",""))
PY
)"
  SITE_DISPLAY_NAME="$(python3 - "$SITE_JSON" <<'PY'
import json
import sys
print(json.loads(sys.argv[1]).get("display_name",""))
PY
)"
  SITE_MODE="$(python3 - "$SITE_JSON" <<'PY'
import json
import sys
print(json.loads(sys.argv[1]).get("connector_mode",""))
PY
)"
  SITE_NEWT="$(python3 - "$SITE_JSON" <<'PY'
import json
import sys
print(str(json.loads(sys.argv[1]).get("newt_enabled","")))
PY
)"
  SITE_OP_ITEM="$(python3 - "$SITE_JSON" <<'PY'
import json
import sys
print(json.loads(sys.argv[1]).get("op_item_title",""))
PY
)"
  pass "required_site_record: slug=$SITE_SLUG connector_mode=$SITE_MODE newt_enabled=$SITE_NEWT op_item_title=$SITE_OP_ITEM"

  if [ "$SITE_DISPLAY_NAME" = "$HOST_ALIAS" ]; then
    pass "naming_display_name: display_name matches host_alias ($HOST_ALIAS)"
  else
    warn "naming_display_name: display_name ($SITE_DISPLAY_NAME) differs from host_alias ($HOST_ALIAS)"
  fi
else
  fail "required_site_record: missing record for host_alias=$HOST_ALIAS inventory_file=$INVENTORY_FILE_REL"
fi

NODE_DOC_MATCHES="$(grep -rl -- "Host alias: \`$HOST_ALIAS\`" "$NODES_DIR"/*.md 2>/dev/null || true)"
if [ -n "$NODE_DOC_MATCHES" ]; then
  NODE_DOC_FILE="$(printf '%s\n' "$NODE_DOC_MATCHES" | head -n1)"
  NODE_DOC_BASE="$(basename "$NODE_DOC_FILE")"
  pass "node_doc_present: docs/nodes/$NODE_DOC_BASE declares host alias $HOST_ALIAS"
  if grep -q "/docs/nodes/$NODE_DOC_BASE" "$LAB_NODES_FILE"; then
    pass "node_doc_indexed: docs/platform/lab-nodes.md references $NODE_DOC_BASE"
  else
    fail "node_doc_indexed: docs/platform/lab-nodes.md missing reference to $NODE_DOC_BASE"
  fi
else
  fail "node_doc_present: no docs/nodes/*.md file declares host alias $HOST_ALIAS"
fi

if nc -vz -G 2 "$LAN_IP" "$ANSIBLE_PORT" >/dev/null 2>&1; then
  pass "tcp_reachability: $LAN_IP:$ANSIBLE_PORT open"
else
  fail "tcp_reachability: cannot connect to $LAN_IP:$ANSIBLE_PORT"
fi

SSH_LOG="$(mktemp)"
if ssh \
  -o BatchMode=yes \
  -o StrictHostKeyChecking=accept-new \
  -o ConnectTimeout=5 \
  -p "$ANSIBLE_PORT" \
  "${ANSIBLE_USER}@${LAN_IP}" \
  "true" >"$SSH_LOG" 2>&1; then
  pass "ssh_auth: ssh command succeeded (${ANSIBLE_USER}@${LAN_IP})"
else
  if grep -Eq "Permission denied|publickey" "$SSH_LOG"; then
    fail "ssh_auth: host reachable but auth failed for ${ANSIBLE_USER}@${LAN_IP}"
  else
    fail "ssh_auth: ssh command failed for ${ANSIBLE_USER}@${LAN_IP}"
  fi
fi
rm -f "$SSH_LOG"

if command -v ansible >/dev/null 2>&1; then
  ANSIBLE_LOG="$(mktemp)"
  if ANSIBLE_HOST_KEY_CHECKING=False ansible -i "$INVENTORY_FILE_ABS" "$HOST_ALIAS" -m ping >"$ANSIBLE_LOG" 2>&1; then
    pass "ansible_ping: $HOST_ALIAS reachable via $INVENTORY_FILE_REL"
  else
    fail "ansible_ping: failed for $HOST_ALIAS via $INVENTORY_FILE_REL"
  fi
  rm -f "$ANSIBLE_LOG"
else
  warn "ansible_ping: skipped (ansible not installed)"
fi

echo
echo "[SUMMARY] pass=$PASS_COUNT fail=$FAIL_COUNT warn=$WARN_COUNT"
[ "$FAIL_COUNT" -eq 0 ] || exit 1
echo "[OK] Machine SoT validation passed for $HOST_ALIAS ($LAN_IP)"
