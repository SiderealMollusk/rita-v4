#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"

KUBECONFIG_PATH="${KUBECONFIG:-$HOME/.kube/config-rita-ops-brain}"
export KUBECONFIG="${KUBECONFIG_PATH}"

echo "[INFO] Using kubeconfig: ${KUBECONFIG}"
echo "[INFO] Bootstrapping Nextcloud database and role on platform-postgres"

platform_password_b64="$(kubectl get secret platform-postgres-auth -n platform -o jsonpath='{.data.postgres-password}')"
db_name_b64="$(kubectl get secret nextcloud-db-secret -n workload -o jsonpath='{.data.db-name}')"
db_user_b64="$(kubectl get secret nextcloud-db-secret -n workload -o jsonpath='{.data.db-user}')"
db_password_b64="$(kubectl get secret nextcloud-db-secret -n workload -o jsonpath='{.data.db-password}')"

platform_password="$(printf '%s' "${platform_password_b64}" | base64 -d)"
db_name="$(printf '%s' "${db_name_b64}" | base64 -d)"
db_user="$(printf '%s' "${db_user_b64}" | base64 -d)"
db_password="$(printf '%s' "${db_password_b64}" | base64 -d)"

kubectl exec -n platform statefulset/platform-postgres -- bash -lc "
export PGPASSWORD='${platform_password}'
/opt/bitnami/postgresql/bin/psql -U postgres -d postgres <<'SQL'
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${db_user}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${db_user}', '${db_password}');
  ELSE
    EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', '${db_user}', '${db_password}');
  END IF;
END
\$\$;

DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${db_name}') THEN
    EXECUTE format('CREATE DATABASE %I OWNER %I', '${db_name}', '${db_user}');
  END IF;
END
\$\$;

GRANT ALL PRIVILEGES ON DATABASE \"${db_name}\" TO \"${db_user}\";
SQL
"

echo "[INFO] Nextcloud database bootstrap completed"
