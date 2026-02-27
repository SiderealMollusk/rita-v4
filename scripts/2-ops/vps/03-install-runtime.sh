#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/../../lib/runbook.sh"

runbook_require_no_args "$@"
REPO_ROOT="$(runbook_detect_repo_root)"

INV="$REPO_ROOT/ops/ansible/inventory/vps.ini"
GROUP_VARS="$REPO_ROOT/ops/ansible/group_vars/vps.yml"

[ -f "$GROUP_VARS" ] || runbook_fail "missing group vars file at $GROUP_VARS"

runbook_refresh_known_hosts_from_inventory "$INV"

PANGOLIN_INSTALL_DIR="$(runbook_yaml_get "$GROUP_VARS" "pangolin_install_dir" || true)"
[ -n "$PANGOLIN_INSTALL_DIR" ] || runbook_fail "pangolin_install_dir missing in $GROUP_VARS"
DOCKER_COMPOSE_VERSION="$(runbook_yaml_get "$GROUP_VARS" "docker_compose_version" || true)"
[ -n "$DOCKER_COMPOSE_VERSION" ] || runbook_fail "docker_compose_version missing in $GROUP_VARS"

echo "[INFO] Installing Docker runtime prerequisites"
ansible -i "$INV" vps -b -m apt -a "update_cache=true name=docker.io,curl,ca-certificates state=present"

echo "[INFO] Removing legacy docker-compose package if present"
ansible -i "$INV" vps -b -m shell -a "apt-get remove -y docker-compose >/dev/null 2>&1 || true"

echo "[INFO] Installing Docker Compose v2 plugin"
ansible -i "$INV" vps -b -m shell -a "set -e
install -d -m 0755 /usr/local/lib/docker/cli-plugins
curl -fsSL https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-linux-x86_64 -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose"

echo "[INFO] Ensuring Docker service is enabled and running"
ansible -i "$INV" vps -b -m service -a "name=docker state=started enabled=true"

echo "[INFO] Verifying Docker Compose v2 plugin availability"
ansible -i "$INV" vps -b -m shell -a "docker compose version"

echo "[INFO] Creating Pangolin directories"
ansible -i "$INV" vps -b -m shell -a "install -d -m 0755 $PANGOLIN_INSTALL_DIR $PANGOLIN_INSTALL_DIR/backups"

echo "[OK] Runtime install complete"
