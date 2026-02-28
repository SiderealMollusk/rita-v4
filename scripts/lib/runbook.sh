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
