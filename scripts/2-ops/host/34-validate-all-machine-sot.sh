#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
runbook_source_labrc "$REPO_ROOT"

REQUIRED_SITES_FILE="$REPO_ROOT/ops/pangolin/sites/required-sites.yaml"
VALIDATOR="$REPO_ROOT/scripts/lib/validate-machine-sot.sh"

runbook_require_cmd python3

echo "[INFO] Validating machine-level SoT for all required-site machine records"
echo "[INFO] Repo root: $REPO_ROOT"

MACHINE_ROWS="$(
  python3 - "$REPO_ROOT" "$REQUIRED_SITES_FILE" <<'PY'
import json
import pathlib
import sys

repo_root = pathlib.Path(sys.argv[1])
required_sites_file = pathlib.Path(sys.argv[2])
records = json.loads(required_sites_file.read_text(encoding="utf-8"))

for record in records:
    host_alias = (record.get("host_alias") or "").strip()
    inventory_rel = (record.get("inventory_file") or "").strip()
    if not host_alias or not inventory_rel:
        continue

    inventory_path = repo_root / inventory_rel
    if not inventory_path.exists():
        print(f"{host_alias}\t{inventory_rel}\t")
        continue

    lan_ip = ""
    for raw in inventory_path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith("["):
            continue
        parts = line.split()
        if not parts or parts[0] != host_alias:
            continue
        for token in parts[1:]:
            if token.startswith("ansible_host="):
                lan_ip = token.split("=", 1)[1]
                break
        break

    print(f"{host_alias}\t{inventory_rel}\t{lan_ip}")
PY
)"

if [ -z "$MACHINE_ROWS" ]; then
  runbook_fail "no machine records discovered from $REQUIRED_SITES_FILE"
fi

total=0
pass=0
fail=0

while IFS=$'\t' read -r host_alias inventory_rel lan_ip; do
  [ -n "$host_alias" ] || continue
  total=$((total + 1))
  echo
  echo "[INFO] [$total] host_alias=$host_alias inventory_file=$inventory_rel lan_ip=${lan_ip:-<missing>}"

  if [ -z "$lan_ip" ]; then
    echo "[FAIL] missing ansible_host for $host_alias in $inventory_rel"
    fail=$((fail + 1))
    continue
  fi

  if "$VALIDATOR" \
    --repo-root "$REPO_ROOT" \
    --lan-ip "$lan_ip" \
    --host-alias "$host_alias" \
    --inventory-file "$inventory_rel" \
    </dev/null; then
    pass=$((pass + 1))
  else
    fail=$((fail + 1))
  fi
done <<< "$MACHINE_ROWS"

echo
echo "[SUMMARY] total=$total pass=$pass fail=$fail"
[ "$fail" -eq 0 ] || exit 1
echo "[OK] All machine-level SoT validations passed"
