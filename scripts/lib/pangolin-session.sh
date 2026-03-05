#!/bin/bash

set -euo pipefail

runbook_require_pangolin_session() {
  runbook_require_cmd jq

  local accounts_file="${HOME}/.config/pangolin/accounts.json"
  [ -f "$accounts_file" ] || runbook_fail "missing Pangolin accounts file: $accounts_file"

  local active_user
  active_user="$(jq -r '.activeuserid // empty' "$accounts_file")"
  [ -n "$active_user" ] || runbook_fail "could not resolve active Pangolin user from $accounts_file"

  local account_path=".accounts[\"${active_user}\"]"
  local host org_id session_token
  host="$(jq -r "${account_path}.host // empty" "$accounts_file")"
  org_id="$(jq -r "${account_path}.orgId // empty" "$accounts_file")"
  session_token="$(jq -r "${account_path}.sessionToken // empty" "$accounts_file")"

  [ -n "$host" ] || runbook_fail "missing host for active Pangolin user in $accounts_file"
  [ -n "$org_id" ] || runbook_fail "missing orgId for active Pangolin user in $accounts_file"
  [ -n "$session_token" ] || runbook_fail "missing sessionToken for active Pangolin user in $accounts_file"

  export PANGOLIN_SESSION_HOST="${PANGOLIN_SESSION_HOST:-$host}"
  export PANGOLIN_SESSION_ORG_ID="${PANGOLIN_SESSION_ORG_ID:-$org_id}"
  export PANGOLIN_SESSION_TOKEN="${PANGOLIN_SESSION_TOKEN:-$session_token}"
}

runbook_pangolin_api_get() {
  local path="$1"
  curl -fsS \
    -H "Cookie: p_session_token=${PANGOLIN_SESSION_TOKEN}" \
    -H "X-CSRF-Token: x-csrf-protection" \
    "${PANGOLIN_SESSION_HOST%/}/api/v1${path}"
}

runbook_pangolin_api_put_json() {
  local path="$1"
  local payload="$2"
  curl -fsS -X PUT \
    -H "Cookie: p_session_token=${PANGOLIN_SESSION_TOKEN}" \
    -H "X-CSRF-Token: x-csrf-protection" \
    -H "Content-Type: application/json" \
    -d "$payload" \
    "${PANGOLIN_SESSION_HOST%/}/api/v1${path}"
}

runbook_pangolin_api_delete() {
  local path="$1"
  curl -fsS -X DELETE \
    -H "Cookie: p_session_token=${PANGOLIN_SESSION_TOKEN}" \
    -H "X-CSRF-Token: x-csrf-protection" \
    "${PANGOLIN_SESSION_HOST%/}/api/v1${path}"
}
