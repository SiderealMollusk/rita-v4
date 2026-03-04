#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
cd "${REPO_ROOT}"

LABRC="${REPO_ROOT}/.labrc"
if [ -f "${LABRC}" ]; then
  # shellcheck source=/dev/null
  source "${LABRC}"
fi

KUBECONFIG_PATH="${KUBECONFIG:-${KUBECONFIG_INTERNAL:-$HOME/.kube/config-rita-ops-brain}}"
export KUBECONFIG="${KUBECONFIG_PATH}"

NAMESPACE="${NEXTCLOUD_NAMESPACE:-workload}"
DEPLOYMENT="${NEXTCLOUD_DEPLOYMENT:-nextcloud}"
FLOW_RUNTIME_HOST="${FLOW_RUNTIME_HOST:-virgil@192.168.6.181}"
FLOW_IMAGE="${FLOW_IMAGE:-ghcr.io/nextcloud/flow:1.3.1}"
FLOW_CONTAINER_NAME="${FLOW_CONTAINER_NAME:-nc_app_flow}"
FLOW_PATCH_WAIT_SECONDS="${FLOW_PATCH_WAIT_SECONDS:-12}"
FLOW_REENABLE_EXAPP="${FLOW_REENABLE_EXAPP:-1}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "${tmp_dir}"' EXIT
flow_main_path="${tmp_dir}/main.py"

occ() {
  kubectl exec -n "${NAMESPACE}" deployment/"${DEPLOYMENT}" -- bash -lc "cd /var/www/html && $1"
}

echo "[INFO] Using kubeconfig: ${KUBECONFIG}"
echo "[INFO] Fetching clean Flow main.py from ${FLOW_IMAGE} via ${FLOW_RUNTIME_HOST}"
ssh "${FLOW_RUNTIME_HOST}" "\
  cid=\$(sudo docker create ${FLOW_IMAGE}) && \
  sudo rm -f /tmp/flow-main.clean.py && \
  sudo docker cp \${cid}:/ex_app/lib/main.py /tmp/flow-main.clean.py && \
  sudo docker rm \${cid} >/dev/null && \
  sudo cat /tmp/flow-main.clean.py" > "${flow_main_path}"

if ! grep -q 'initialize_windmill' "${flow_main_path}"; then
  echo "[FAIL] Downloaded file does not look like Flow main.py"
  exit 1
fi

if ! grep -q 'keeping default OSS credentials' "${flow_main_path}"; then
  perl -0pi -e '
    s@        default_token = r.text
        new_default_password = generate_random_string\(\)
        r = httpx.post\(
            url=f"\{WINDMILL_URL\}/api/users/setpassword",
            json=\{"password": new_default_password\},
            cookies=\{"token": default_token\},
        \)
        if r.status_code >= 400:
            LOGGER.error\("initialize_windmill: can not change default credentials password: %s", r.text\)
            raise RuntimeError\(f"initialize_windmill: can not change default credentials password, \{r.text\}"\)
        add_user_to_storage\(DEFAULT_USER_EMAIL, new_default_password, default_token\)@        default_token = r.text
        new_default_password = generate_random_string()
        stored_default_password = new_default_password
        r = httpx.post(
            url=f"{WINDMILL_URL}/api/users/setpassword",
            json={"password": new_default_password},
            cookies={"token": default_token},
        )
        if r.status_code >= 400:
            LOGGER.warning(
                "initialize_windmill: can not change default credentials password, keeping default OSS credentials: %s",
                r.text,
            )
            stored_default_password = DEFAULT_USER_PASSWORD
        add_user_to_storage(DEFAULT_USER_EMAIL, stored_default_password, default_token)@s;

    s@        default_token = r.text
        add_user_to_storage\(DEFAULT_USER_EMAIL, new_default_password, default_token\)@        default_token = r.text
        add_user_to_storage(DEFAULT_USER_EMAIL, stored_default_password, default_token)@s;

    s@        r = httpx.post\(
            url=f"\{WINDMILL_URL\}/api/workspaces/create",
            json=\{"id": "nextcloud", "name": "nextcloud"\},
            cookies=\{"token": default_token\},
        \)
        if r.status_code >= 400:
            LOGGER.error\("initialize_windmill: can not create default workspace: %s", r.text\)
            raise RuntimeError\(f"initialize_windmill: can not create default workspace, \{r.text\}"\)
        r = httpx.post\(
            url=f"\{WINDMILL_URL\}/api/w/nextcloud/workspaces/edit_auto_invite",
            json=\{"operator": False, "invite_all": True, "auto_add": True\},
            cookies=\{"token": default_token\},
        \)
        if r.status_code >= 400:
            LOGGER.error\("initialize_windmill: can not create default workspace: %s", r.text\)
            raise RuntimeError\(f"initialize_windmill: can not create default workspace, \{r.text\}"\)@        r = httpx.post(
            url=f"{WINDMILL_URL}/api/workspaces/create",
            json={"id": "nextcloud", "name": "nextcloud"},
            cookies={"token": default_token},
        )
        if r.status_code >= 400:
            LOGGER.warning("initialize_windmill: can not create default workspace, continuing: %s", r.text)
        r = httpx.post(
            url=f"{WINDMILL_URL}/api/w/nextcloud/workspaces/edit_auto_invite",
            json={"operator": False, "invite_all": True, "auto_add": True},
            cookies={"token": default_token},
        )
        if r.status_code >= 400:
            LOGGER.warning("initialize_windmill: can not set workspace auto-invite, continuing: %s", r.text)@s;
  ' "${flow_main_path}"
fi

if ! grep -q 'keeping default OSS credentials' "${flow_main_path}"; then
  echo "[FAIL] Flow OSS workaround patch was not applied"
  exit 1
fi

echo "[INFO] Copying patched Flow main.py into ${FLOW_CONTAINER_NAME} on ${FLOW_RUNTIME_HOST}"
base64 < "${flow_main_path}" | ssh "${FLOW_RUNTIME_HOST}" "\
  base64 -d >/tmp/flow-main.patched.py && \
  sudo docker stop ${FLOW_CONTAINER_NAME} >/dev/null && \
  sudo docker cp /tmp/flow-main.patched.py ${FLOW_CONTAINER_NAME}:/ex_app/lib/main.py && \
  sudo docker start ${FLOW_CONTAINER_NAME} >/dev/null && \
  sleep ${FLOW_PATCH_WAIT_SECONDS} && \
  sudo docker exec ${FLOW_CONTAINER_NAME} sh -lc 'curl --unix-socket /tmp/exapp.sock http://localhost/heartbeat'"

if [ "${FLOW_REENABLE_EXAPP}" = "1" ]; then
  echo "[INFO] Re-enabling Flow in Nextcloud AppAPI"
  occ "php occ app_api:app:enable flow"
fi

echo "[INFO] Current AppAPI app list"
occ "php occ app_api:app:list"
