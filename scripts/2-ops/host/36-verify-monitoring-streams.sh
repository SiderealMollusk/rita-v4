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
CONTRACT="$REPO_ROOT/ops/monitoring/loki/stream-contract.json"

[ -f "$INV" ] || runbook_fail "inventory not found: $INV"
[ -f "$CONTRACT" ] || runbook_fail "stream contract not found: $CONTRACT"

runbook_refresh_known_hosts_from_inventory "$INV"

OBS_HOST="$(runbook_inventory_get_field "$INV" "observatory" "ansible_host")"
OBS_USER="$(runbook_inventory_get_field "$INV" "observatory" "ansible_user")"
OBS_PORT="$(runbook_inventory_get_field "$INV" "observatory" "ansible_port")"

[ -n "$OBS_HOST" ] || runbook_fail "missing ansible_host for observatory in $INV"
[ -n "$OBS_USER" ] || OBS_USER="virgil"
[ -n "$OBS_PORT" ] || OBS_PORT="22"

SSH_BASE=(ssh -p "$OBS_PORT" "${OBS_USER}@${OBS_HOST}")

echo "[INFO] Verifying monitoring streams against contract: $CONTRACT"

LOKI_IP="$("${SSH_BASE[@]}" 'export KUBECONFIG=/home/'"$OBS_USER"'/.kube/config; kubectl get svc -n monitoring observatory-loki -o jsonpath="{.spec.clusterIP}"; echo')"
[ -n "$LOKI_IP" ] || runbook_fail "could not resolve observatory-loki ClusterIP"

TMP_DIR="$(mktemp -d /tmp/rita-monitoring-stream-verify.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

"${SSH_BASE[@]}" "curl -s \"http://${LOKI_IP}:3100/loki/api/v1/label/namespace/values\"" > "$TMP_DIR/namespaces.json"
"${SSH_BASE[@]}" "curl -s \"http://${LOKI_IP}:3100/loki/api/v1/label/job/values\"" > "$TMP_DIR/jobs.json"
"${SSH_BASE[@]}" "curl -s \"http://${LOKI_IP}:3100/loki/api/v1/label/node_name/values\"" > "$TMP_DIR/nodes.json"
"${SSH_BASE[@]}" "curl -s \"http://${LOKI_IP}:3100/loki/api/v1/label/pod/values\"" > "$TMP_DIR/stream-pods.json"
"${SSH_BASE[@]}" "export KUBECONFIG=/home/${OBS_USER}/.kube/config; kubectl get pods -A --field-selector=status.phase=Running -o json" > "$TMP_DIR/running-pods.json"

python3 - "$CONTRACT" "$TMP_DIR" <<'PY'
import json
import pathlib
import re
import sys

contract = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
tmp = pathlib.Path(sys.argv[2])

namespaces = set(json.loads((tmp / "namespaces.json").read_text(encoding="utf-8")).get("data", []))
jobs = set(json.loads((tmp / "jobs.json").read_text(encoding="utf-8")).get("data", []))
nodes = set(json.loads((tmp / "nodes.json").read_text(encoding="utf-8")).get("data", []))
stream_pods = set(json.loads((tmp / "stream-pods.json").read_text(encoding="utf-8")).get("data", []))
running = json.loads((tmp / "running-pods.json").read_text(encoding="utf-8")).get("items", [])
running_pairs = sorted(f"{p['metadata']['namespace']}/{p['metadata']['name']}" for p in running)

required_namespaces = contract.get("required_namespaces", [])
required_nodes = contract.get("required_node_names", [])
required_job_patterns = [re.compile(p) for p in contract.get("required_job_patterns", [])]
allow_missing_patterns = [re.compile(p) for p in contract.get("allow_missing_pod_patterns", [])]

pass_count = 0
fail_count = 0
warn_count = 0

def ok(msg):
    global pass_count
    pass_count += 1
    print(f"[PASS] {msg}")

def fail(msg):
    global fail_count
    fail_count += 1
    print(f"[FAIL] {msg}")

def warn(msg):
    global warn_count
    warn_count += 1
    print(f"[WARN] {msg}")

for ns in required_namespaces:
    if ns in namespaces:
        ok(f"namespace_streams_present: {ns}")
    else:
        fail(f"namespace_streams_missing: {ns}")

for node in required_nodes:
    if node in nodes:
        ok(f"node_streams_present: {node}")
    else:
        fail(f"node_streams_missing: {node}")

for pattern in required_job_patterns:
    matched = sorted([j for j in jobs if pattern.search(j)])
    if matched:
        ok(f"job_pattern_present: {pattern.pattern} -> {', '.join(matched)}")
    else:
        fail(f"job_pattern_missing: {pattern.pattern}")

missing_running = []
for pair in running_pairs:
    _, pod_name = pair.split("/", 1)
    if pod_name in stream_pods:
        continue
    if any(p.search(pair) for p in allow_missing_patterns):
        continue
    missing_running.append(pair)

if missing_running:
    warn("running_pods_without_stream_label:")
    for pair in missing_running:
        warn(f"  - {pair}")
else:
    ok("running_pods_without_stream_label: none")

legacy_newt_jobs = sorted([j for j in jobs if j.startswith("newt/ops-brain-")])
legacy_newt_running = [p for p in running_pairs if p.startswith("newt/ops-brain-")]
if legacy_newt_jobs and legacy_newt_running:
    warn("legacy_newt_job_names_detected_with_running_pods:")
    for j in legacy_newt_jobs:
        warn(f"  - {j}")

print()
print(f"[SUMMARY] pass={pass_count} fail={fail_count} warn={warn_count}")
if fail_count:
    raise SystemExit(1)
print("[OK] Monitoring stream verification passed")
PY
