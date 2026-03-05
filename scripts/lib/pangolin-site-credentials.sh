#!/bin/bash

set -euo pipefail

runbook_register_pangolin_site_credentials() {
  local repo_root="$1"
  local site_slug="$2"
  local site_name="$3"
  local item_title="$4"
  local vault_id="$5"

  local routes_file="$repo_root/ops/network/routes.yml"
  local ops_brain_vars="$repo_root/ops/ansible/group_vars/ops_brain.yml"

  [ -f "$routes_file" ] || runbook_fail "missing routes file at $routes_file"
  [ -f "$ops_brain_vars" ] || runbook_fail "missing group vars file at $ops_brain_vars"
  [ -n "$site_slug" ] || runbook_fail "site slug is required"
  [ -n "$item_title" ] || runbook_fail "item title is required"
  [ -n "$vault_id" ] || runbook_fail "vault id is required"

  local pangolin_endpoint
  pangolin_endpoint="$(runbook_yaml_get "$routes_file" "pangolin_endpoint" || true)"
  [ -n "$pangolin_endpoint" ] || runbook_fail "pangolin_endpoint missing in $routes_file"

  local site_identifier_field
  site_identifier_field="$(runbook_yaml_get "$ops_brain_vars" "pangolin_newt_site_identifier_field" || true)"
  [ -n "$site_identifier_field" ] || runbook_fail "pangolin_newt_site_identifier_field missing in $ops_brain_vars"

  echo "[INFO] Registering Pangolin site credentials for slug=${site_slug}"
  if [ -n "$site_name" ]; then
    echo "[INFO] Expected site display name: ${site_name}"
  fi
  echo "[INFO] 1Password item title: ${item_title}"
  echo "[INFO] 1Password vault id: ${vault_id}"
  echo "[INFO] Pangolin endpoint: ${pangolin_endpoint}"
  echo "[INFO] This script does not create the site in Pangolin UI."
  echo "[INFO] Create the site first, then paste:"
  echo "       1. site name"
  echo "       2. site identifier"
  echo "       3. full Helm install snippet"

  local pasted_site_name
  read -r -p "Pangolin site name from UI: " pasted_site_name
  [ -n "$pasted_site_name" ] || runbook_fail "Pangolin site name is empty"
  if [ -n "$site_name" ] && [ "$pasted_site_name" != "$site_name" ]; then
    echo "[WARN] Pasted site name '$pasted_site_name' does not match expected '$site_name'. Continuing with pasted value."
  fi

  local site_identifier_value
  read -r -p "Pangolin site identifier from UI: " site_identifier_value
  [ -n "$site_identifier_value" ] || runbook_fail "Pangolin site identifier is empty"

  echo "[INFO] Paste Pangolin Helm snippet, then press Ctrl-D:"
  local helm_snippet
  helm_snippet="$(cat)"
  [ -n "$helm_snippet" ] || runbook_fail "No Helm snippet was pasted"

  extract_quoted_value() {
    local input="$1"
    local key="$2"
    printf '%s\n' "$input" | sed -n "s/.*${key}=\"\\([^\"]*\\)\".*/\\1/p" | tail -n 1
  }

  local extracted_endpoint
  local newt_id_value
  local newt_secret_value
  extracted_endpoint="$(extract_quoted_value "$helm_snippet" "endpointKey")"
  newt_id_value="$(extract_quoted_value "$helm_snippet" "idKey")"
  newt_secret_value="$(extract_quoted_value "$helm_snippet" "secretKey")"

  [ -n "$extracted_endpoint" ] || runbook_fail "Could not extract endpointKey from Helm snippet"
  [ -n "$newt_id_value" ] || runbook_fail "Could not extract idKey from Helm snippet"
  [ -n "$newt_secret_value" ] || runbook_fail "Could not extract secretKey from Helm snippet"

  if [ "$extracted_endpoint" != "$pangolin_endpoint" ]; then
    runbook_fail "Pasted endpoint '$extracted_endpoint' does not match canonical endpoint '$pangolin_endpoint'."
  fi

  if op item get "$item_title" --vault "$vault_id" >/dev/null 2>&1; then
    echo "[INFO] Updating existing 1Password item: $item_title"
    op item edit "$item_title" --vault "$vault_id" \
      "endpoint[text]=$pangolin_endpoint" \
      "name[text]=$pasted_site_name" \
      "${site_identifier_field}[text]=$site_identifier_value" \
      "newt_id[text]=$newt_id_value" \
      "secret[concealed]=$newt_secret_value" >/dev/null
  else
    echo "[INFO] Creating new 1Password item: $item_title"
    op item create --vault "$vault_id" --category "Secure Note" --title "$item_title" \
      "endpoint[text]=$pangolin_endpoint" \
      "name[text]=$pasted_site_name" \
      "${site_identifier_field}[text]=$site_identifier_value" \
      "newt_id[text]=$newt_id_value" \
      "secret[concealed]=$newt_secret_value" >/dev/null
  fi

  echo "[OK] 1Password item is ready: $item_title"
  echo "[INFO] Stored site identifier: ${site_identifier_value}"
  echo "[INFO] Extracted id length: ${#newt_id_value}"
  echo "[INFO] Extracted secret length: ${#newt_secret_value}"
}
