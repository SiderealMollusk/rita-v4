#!/bin/bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  pangolin-api-readonly-check.sh --api-base <url> --token <token> [--org-id <id>]

Description:
  Read-only Pangolin API probe.
  Validates auth and prints org/site/resource/blueprint inventory summary.

Required:
  --api-base   Pangolin API base URL (for example https://pangolin.example.com/v1)
  --token      Pangolin API bearer token

Optional:
  --org-id     Organization ID. If omitted, exactly one org must be visible.
EOF
}

API_BASE=""
API_TOKEN=""
ORG_ID=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --api-base)
      [ "$#" -ge 2 ] || { usage; exit 1; }
      API_BASE="$2"
      shift 2
      ;;
    --token)
      [ "$#" -ge 2 ] || { usage; exit 1; }
      API_TOKEN="$2"
      shift 2
      ;;
    --org-id)
      [ "$#" -ge 2 ] || { usage; exit 1; }
      ORG_ID="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[FAIL] unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

[ -n "$API_BASE" ] || { echo "[FAIL] --api-base is required"; usage; exit 1; }
[ -n "$API_TOKEN" ] || { echo "[FAIL] --token is required"; usage; exit 1; }

api_get() {
  local path="$1"
  curl -fsS \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H "Accept: application/json" \
    "${API_BASE%/}${path}"
}

OPENAPI_JSON="$(api_get /openapi.json)"
OPENAPI_TITLE="$(printf '%s' "$OPENAPI_JSON" | jq -r '.info.title // "unknown"')"
OPENAPI_VERSION="$(printf '%s' "$OPENAPI_JSON" | jq -r '.info.version // "unknown"')"
PATH_COUNT="$(printf '%s' "$OPENAPI_JSON" | jq '.paths | length')"
echo "[OK] OpenAPI reachable: title='${OPENAPI_TITLE}', version='${OPENAPI_VERSION}', paths=${PATH_COUNT}"

ORGS_JSON="$(api_get /orgs)"
ORG_COUNT="$(printf '%s' "$ORGS_JSON" | jq '.data | if type=="array" then length else 0 end')"
[ "$ORG_COUNT" -gt 0 ] || { echo "[FAIL] token can see zero orgs"; exit 1; }

if [ -z "$ORG_ID" ]; then
  if [ "$ORG_COUNT" -eq 1 ]; then
    ORG_ID="$(printf '%s' "$ORGS_JSON" | jq -r '.data[0].orgId // .data[0].id // empty')"
  else
    echo "[FAIL] multiple orgs visible; pass --org-id"
    printf '%s' "$ORGS_JSON" | jq -r '.data[] | "- orgId=\(.orgId // .id // "unknown") name=\(.name // "unknown")"'
    exit 1
  fi
fi

[ -n "$ORG_ID" ] || { echo "[FAIL] failed to resolve org id"; exit 1; }
ORG_JSON="$(api_get "/org/${ORG_ID}")"
ORG_NAME="$(printf '%s' "$ORG_JSON" | jq -r '.data.name // .name // "unknown"')"
echo "[OK] Org reachable: id='${ORG_ID}' name='${ORG_NAME}'"

SITES_JSON="$(api_get "/org/${ORG_ID}/sites?limit=200&offset=0")"
RESOURCES_JSON="$(api_get "/org/${ORG_ID}/resources?limit=200&offset=0")"
BLUEPRINTS_JSON="$(api_get "/org/${ORG_ID}/blueprints?limit=200&offset=0")"

SITE_COUNT="$(printf '%s' "$SITES_JSON" | jq '.data | if type=="array" then length else 0 end')"
RESOURCE_COUNT="$(printf '%s' "$RESOURCES_JSON" | jq '.data | if type=="array" then length else 0 end')"
BLUEPRINT_COUNT="$(printf '%s' "$BLUEPRINTS_JSON" | jq '.data | if type=="array" then length else 0 end')"

echo
echo "[OK] Pangolin read-only summary"
echo "       org_id: ${ORG_ID}"
echo "       org_name: ${ORG_NAME}"
echo "       sites: ${SITE_COUNT}"
echo "       public_resources: ${RESOURCE_COUNT}"
echo "       blueprints: ${BLUEPRINT_COUNT}"

echo
echo "[INFO] Sites (up to 10):"
printf '%s' "$SITES_JSON" | jq -r '.data // [] | .[:10] | .[] | "- id=\(.siteId // .id // "unknown") niceId=\(.niceId // "unknown") name=\(.name // "unknown")"'

echo
echo "[INFO] Public resources (up to 10):"
printf '%s' "$RESOURCES_JSON" | jq -r '.data // [] | .[:10] | .[] | "- id=\(.resourceId // .id // "unknown") niceId=\(.niceId // "unknown") domain=\(.fullDomain // .domain // "unknown") name=\(.name // "unknown")"'

echo
echo "[INFO] Blueprints (up to 10):"
printf '%s' "$BLUEPRINTS_JSON" | jq -r '.data // [] | .[:10] | .[] | "- id=\(.blueprintId // .id // "unknown") name=\(.name // "unknown")"'

echo
echo "[OK] Pangolin API read-only check completed with no mutations."
