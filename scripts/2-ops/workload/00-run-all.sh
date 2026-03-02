#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "[INFO] Running workload runbook pipeline"

for script in \
  01-inspect-proxmox.sh \
  03-ansible-ping.sh \
  04-bootstrap-host.sh \
  05-install-k3s-agent.sh \
  06-label-node.sh \
  07-verify-node.sh
do
  echo "[INFO] >>> ${script}"
  "$SCRIPT_DIR/${script}"
done
