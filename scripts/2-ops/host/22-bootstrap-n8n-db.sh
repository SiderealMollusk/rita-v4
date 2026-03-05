#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
# shellcheck source=/dev/null
source "${SCRIPT_DIR}/../../lib/runbook.sh"
cd "${REPO_ROOT}"

runbook_source_labrc "${REPO_ROOT}"
runbook_export_default_kubeconfig

echo "[INFO] Using kubeconfig: ${KUBECONFIG}"
echo "[INFO] Bootstrapping n8n database and role on platform-postgres"

platform_password_b64="$(kubectl get secret platform-postgres-auth -n platform -o jsonpath='{.data.postgres-password}')"
n8n_password_b64="$(kubectl get secret n8n-secrets -n platform -o jsonpath='{.data.db-password}')"

platform_password="$(printf '%s' "${platform_password_b64}" | base64 -d)"
n8n_password="$(printf '%s' "${n8n_password_b64}" | base64 -d)"

db_name="n8n"
db_user="n8n"

kubectl exec -n platform statefulset/platform-postgres -- bash -lc "
export PGPASSWORD='${platform_password}'
/opt/bitnami/postgresql/bin/psql -v ON_ERROR_STOP=1 -U postgres -d postgres <<'SQL'
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '${db_user}') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', '${db_user}', '${n8n_password}');
  ELSE
    EXECUTE format('ALTER ROLE %I WITH LOGIN PASSWORD %L', '${db_user}', '${n8n_password}');
  END IF;
END
\$\$;
SQL

if ! /opt/bitnami/postgresql/bin/psql -tAc \"SELECT 1 FROM pg_database WHERE datname='${db_name}'\" -U postgres -d postgres | grep -q 1; then
  /opt/bitnami/postgresql/bin/createdb -U postgres -O '${db_user}' '${db_name}'
fi

/opt/bitnami/postgresql/bin/psql -v ON_ERROR_STOP=1 -U postgres -d postgres -c \"GRANT ALL PRIVILEGES ON DATABASE \\\"${db_name}\\\" TO \\\"${db_user}\\\";\"
"

echo "[INFO] n8n database bootstrap completed"
