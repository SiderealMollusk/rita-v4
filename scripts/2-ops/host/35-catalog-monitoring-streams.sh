#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_require_host_terminal
runbook_require_cmd ssh
runbook_require_cmd python3

INV="$REPO_ROOT/ops/ansible/inventory/observatory.ini"
[ -f "$INV" ] || runbook_fail "inventory not found: $INV"

runbook_refresh_known_hosts_from_inventory "$INV"

OBS_HOST="$(runbook_inventory_get_field "$INV" "observatory" "ansible_host")"
OBS_USER="$(runbook_inventory_get_field "$INV" "observatory" "ansible_user")"
OBS_PORT="$(runbook_inventory_get_field "$INV" "observatory" "ansible_port")"

[ -n "$OBS_HOST" ] || runbook_fail "missing ansible_host for observatory in $INV"
[ -n "$OBS_USER" ] || OBS_USER="virgil"
[ -n "$OBS_PORT" ] || OBS_PORT="22"

SSH_BASE=(ssh -p "$OBS_PORT" "${OBS_USER}@${OBS_HOST}")

echo "[INFO] Cataloging monitoring streams from observatory (${OBS_USER}@${OBS_HOST}:${OBS_PORT})"

LOKI_IP="$("${SSH_BASE[@]}" 'export KUBECONFIG=/home/'"$OBS_USER"'/.kube/config; kubectl get svc -n monitoring observatory-loki -o jsonpath="{.spec.clusterIP}"; echo')"
[ -n "$LOKI_IP" ] || runbook_fail "could not resolve observatory-loki ClusterIP"

TMP_DIR="$(mktemp -d /tmp/rita-monitoring-stream-catalog.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

"${SSH_BASE[@]}" "curl -s \"http://${LOKI_IP}:3100/loki/api/v1/labels\"" > "$TMP_DIR/labels.json"
"${SSH_BASE[@]}" "curl -s \"http://${LOKI_IP}:3100/loki/api/v1/label/namespace/values\"" > "$TMP_DIR/namespaces.json"
"${SSH_BASE[@]}" "curl -s \"http://${LOKI_IP}:3100/loki/api/v1/label/job/values\"" > "$TMP_DIR/jobs.json"
"${SSH_BASE[@]}" "curl -s \"http://${LOKI_IP}:3100/loki/api/v1/label/node_name/values\"" > "$TMP_DIR/nodes.json"
"${SSH_BASE[@]}" "curl -s \"http://${LOKI_IP}:3100/loki/api/v1/label/pod/values\"" > "$TMP_DIR/pods.json"
"${SSH_BASE[@]}" "export KUBECONFIG=/home/${OBS_USER}/.kube/config; kubectl get pods -A --field-selector=status.phase=Running -o json" > "$TMP_DIR/running-pods.json"

python3 - "$TMP_DIR" <<'PY'
import json
import pathlib
import sys

tmp = pathlib.Path(sys.argv[1])

labels = json.loads((tmp / "labels.json").read_text(encoding="utf-8")).get("data", [])
namespaces = sorted(json.loads((tmp / "namespaces.json").read_text(encoding="utf-8")).get("data", []))
jobs = sorted(json.loads((tmp / "jobs.json").read_text(encoding="utf-8")).get("data", []))
nodes = sorted(json.loads((tmp / "nodes.json").read_text(encoding="utf-8")).get("data", []))
pods = sorted(json.loads((tmp / "pods.json").read_text(encoding="utf-8")).get("data", []))
running = json.loads((tmp / "running-pods.json").read_text(encoding="utf-8")).get("items", [])
running_pods = sorted(
    f"{p['metadata']['namespace']}/{p['metadata']['name']}"
    for p in running
)

print(f"[INFO] labels={len(labels)} namespaces={len(namespaces)} jobs={len(jobs)} nodes={len(nodes)} stream_pods={len(pods)} running_pods={len(running_pods)}")
print("[INFO] Namespaces:")
for ns in namespaces:
    print(f"  - {ns}")
print("[INFO] Nodes:")
for node in nodes:
    print(f"  - {node}")
print("[INFO] Jobs:")
for job in jobs:
    print(f"  - {job}")
print("[INFO] Pods with Loki stream labels:")
for pod in pods:
    print(f"  - {pod}")
PY

echo "[OK] Monitoring stream catalog complete"
