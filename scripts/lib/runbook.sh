#!/bin/bash

set -euo pipefail

runbook_fail() {
  echo "[FAIL] $*"
  exit 1
}

runbook_require_no_args() {
  if [ "$#" -ne 0 ]; then
    runbook_fail "This runbook script takes no arguments."
  fi
}

runbook_detect_repo_root() {
  if [ -d /workspaces/rita-v4 ]; then
    echo "/workspaces/rita-v4"
    return
  fi
  if [ -d /Users/virgil/Dev/rita-v4 ]; then
    echo "/Users/virgil/Dev/rita-v4"
    return
  fi
  runbook_fail "Could not locate repo root."
}

runbook_require_cmd() {
  command -v "$1" >/dev/null 2>&1 || runbook_fail "missing command: $1"
}

runbook_find_pangolin_cli() {
  if command -v pangolin >/dev/null 2>&1; then
    command -v pangolin
    return 0
  fi

  local fallback="${HOME}/.local/bin/pangolin"
  if [ -x "$fallback" ]; then
    printf '%s\n' "$fallback"
    return 0
  fi

  return 1
}

runbook_require_pangolin_cli() {
  local pangolin_bin
  pangolin_bin="$(runbook_find_pangolin_cli)" || runbook_fail "missing command: pangolin"
  printf '%s\n' "$pangolin_bin"
}

runbook_require_host_terminal() {
  if [ -f /.dockerenv ] || grep -q 'docker\|containerd' /proc/1/cgroup 2>/dev/null; then
    runbook_fail "Run this script from your Mac host terminal, not inside the devcontainer."
  fi
}

runbook_require_op_user_session() {
  if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    echo "[FAIL] OP_SERVICE_ACCOUNT_TOKEN is set; this puts op CLI in service-account mode."
    echo "[INFO] Run these first:"
    echo "       unset OP_SERVICE_ACCOUNT_TOKEN"
    echo "       op signin"
    exit 1
  fi
  runbook_require_cmd op
  local whoami_output
  whoami_output="$(op whoami 2>/dev/null || true)"
  [ -n "$whoami_output" ] || runbook_fail "1Password CLI is not authenticated. Run: op signin"
  if printf '%s\n' "$whoami_output" | grep -q "User Type:[[:space:]]*SERVICE_ACCOUNT"; then
    echo "[FAIL] 1Password CLI is currently authenticated as SERVICE_ACCOUNT."
    echo "[INFO] This write path requires a human operator session."
    echo "[INFO] Run these first:"
    echo "       unset OP_SERVICE_ACCOUNT_TOKEN"
    echo "       op signin"
    exit 1
  fi
}

runbook_require_op_write_access() {
  runbook_require_op_user_session
}

runbook_require_op_access() {
  runbook_require_cmd op

  if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
    op vault list >/dev/null
    return 0
  fi

  op whoami >/dev/null
}

runbook_source_labrc() {
  local repo_root
  repo_root="${1:-$(runbook_detect_repo_root)}"
  local labrc_path="${repo_root}/.labrc"
  if [ -f "$labrc_path" ]; then
    # shellcheck source=/dev/null
    source "$labrc_path"
  fi
}

runbook_export_default_kubeconfig() {
  local fallback_path="${1:-$HOME/.kube/config-rita-observatory}"
  export KUBECONFIG="${KUBECONFIG:-${KUBECONFIG_INTERNAL:-$fallback_path}}"
}

runbook_build_op_ref() {
  local vault_id="$1"
  local item_name="$2"
  local field_name="$3"
  printf 'op://%s/%s/%s\n' "$vault_id" "$item_name" "$field_name"
}

runbook_resolve_secret_from_op() {
  local current_value="${1:-}"
  local op_ref="${2:-}"
  if [ -n "$current_value" ]; then
    printf '%s\n' "$current_value"
    return 0
  fi
  [ -n "$op_ref" ] || return 1
  runbook_require_op_access
  op read "$op_ref"
}

runbook_require_env() {
  local var_name="$1"
  local hint="${2:-}"
  if [ -z "${!var_name:-}" ]; then
    echo "[FAIL] ${var_name} is not set in this shell."
    if [ -n "$hint" ]; then
      echo "[INFO] ${hint}"
    fi
    exit 1
  fi
}

runbook_refresh_known_hosts_from_inventory() {
  local inventory_path="$1"
  [ -f "$inventory_path" ] || runbook_fail "inventory not found: $inventory_path"

  runbook_require_cmd ssh-keygen
  runbook_require_cmd ssh-keyscan

  local known_hosts_path="${HOME}/.ssh/known_hosts"
  mkdir -p "${HOME}/.ssh"
  touch "$known_hosts_path"
  chmod 600 "$known_hosts_path"

  awk '
    /^\[/ { next }
    $0 !~ /^[[:space:]]*#/ && NF > 0 {
      host=""
      port="22"
      for (i=1; i<=NF; i++) {
        if ($i ~ /^ansible_host=/) { split($i,a,"="); host=a[2] }
        if ($i ~ /^ansible_port=/) { split($i,a,"="); port=a[2] }
      }
      if (host != "") { print host, port }
    }
  ' "$inventory_path" | while read -r host port; do
    [ -n "$host" ] || continue
    echo "[INFO] Refreshing SSH host key for ${host}:${port}"
    ssh-keygen -R "$host" -f "$known_hosts_path" >/dev/null 2>&1 || true
    ssh-keygen -R "[${host}]:${port}" -f "$known_hosts_path" >/dev/null 2>&1 || true
    ssh-keyscan -H -p "$port" "$host" >> "$known_hosts_path" 2>/dev/null || runbook_fail "failed to scan ssh host key for ${host}:${port}"
  done
}

# Extract a simple top-level YAML key value from a file.
# Supports lines like: key: "value" or key: value
runbook_yaml_get() {
  local file_path="$1"
  local key="$2"
  [ -f "$file_path" ] || return 1
  awk -v k="$key" '
    $0 ~ "^[[:space:]]*"k":[[:space:]]*" {
      sub("^[[:space:]]*"k":[[:space:]]*", "", $0)
      gsub(/^"/, "", $0)
      gsub(/"$/, "", $0)
      gsub(/[[:space:]]+$/, "", $0)
      print $0
      exit
    }
  ' "$file_path"
}

runbook_inventory_get_field() {
  local inventory_path="$1"
  local host_alias="$2"
  local field_name="$3"
  [ -f "$inventory_path" ] || return 1
  awk -v host="$host_alias" -v field="$field_name" '
    $1 == host {
      for (i = 2; i <= NF; i++) {
        split($i, a, "=")
        if (a[1] == field) {
          print a[2]
          exit
        }
      }
    }
  ' "$inventory_path"
}
