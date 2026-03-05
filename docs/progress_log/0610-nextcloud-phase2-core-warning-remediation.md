# 0610 - Nextcloud Phase 2 Core Warning Remediation

Date: 2026-03-05

## Summary

Completed the first execution slice of plan 0650 on `cloud.virgil.info`:
1. reverse proxy header config in Nextcloud
2. HSTS + `.mjs` MIME in Nginx
3. OCS provider routing fix
4. PHP memory and core system config defaults

## Changes Applied

1. Updated managed vars:
- [nextcloud.yml](/Users/virgil/Dev/rita-v4/ops/ansible/group_vars/nextcloud.yml)
  - `nextcloud_forwarded_for_headers`
  - `nextcloud_maintenance_window_start`
  - `nextcloud_default_phone_region`
  - `nextcloud_php_memory_limit`
  - `nextcloud_hsts_max_age`

2. Updated templates:
- [nextcloud-php.ini.j2](/Users/virgil/Dev/rita-v4/ops/ansible/templates/nextcloud/nextcloud-php.ini.j2)
  - `memory_limit={{ nextcloud_php_memory_limit }}`
- [nginx-site.conf.j2](/Users/virgil/Dev/rita-v4/ops/ansible/templates/nextcloud/nginx-site.conf.j2)
  - HSTS header
  - `.mjs` MIME mapping
  - corrected `/ocs-provider/` route handling

3. Updated install playbook:
- [33-install-nextcloud-core.yml](/Users/virgil/Dev/rita-v4/ops/ansible/playbooks/33-install-nextcloud-core.yml)
  - managed `trusted_proxies`
  - managed `forwarded_for_headers`
  - managed `maintenance_window_start`
  - managed `default_phone_region`

## Verification Evidence

1. `occ config:system:get forwarded_for_headers` => `HTTP_X_FORWARDED_FOR`
2. `occ config:system:get maintenance_window_start` => `3`
3. `occ config:system:get default_phone_region` => `US`
4. `php -i | grep '^memory_limit'` => `memory_limit => 512M => 512M`
5. `curl -si https://cloud.virgil.info/` includes `strict-transport-security: max-age=15552000; includeSubDomains`
6. `curl -si https://cloud.virgil.info/apps/collectives/js/collectives-init.mjs` => `content-type: application/javascript`
7. `curl -si https://cloud.virgil.info/ocs-provider/` => `HTTP/2 200`, `content-type: application/json`

## Operational Note

Initial `/ocs-provider/` implementation introduced an Nginx rewrite loop (`/ocs-provider/index.php/ocs-provider/`), observed in `/var/log/nginx/error.log`.  
It was corrected by switching to exact-match locations for `/ocs-provider` and `/ocs-provider/`.

## Next Focus

Continue plan 0650 Phase 2/3:
1. DB maintenance (`occ db:add-missing-indices`, `occ maintenance:repair --include-expensive`)
2. Talk reliability stack (`HPB`, `STUN/TURN`, `notify_push`)
