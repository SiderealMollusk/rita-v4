# 0170 Ansible Python Warning and Helm Jam Cleanup

As of this update, two recurring operational annoyances were cleaned up:

1. Ansible interpreter discovery warnings
2. stuck Helm release state during repeated Newt install attempts

## Ansible warning fix

The active inventories now pin the interpreter explicitly:

1. `ops/ansible/inventory/ops-brain.ini`
2. `ops/ansible/inventory/vps.ini`

Using:

- `ansible_python_interpreter=/usr/bin/python3`

This removes the noisy interpreter discovery warning from ad-hoc commands and runbook scripts.

## Helm jam cleanup

`scripts/2-ops/ops-brain/10-install-newt.sh` now checks for:

1. `pending-install`
2. `pending-upgrade`
3. `pending-rollback`

If a stuck release is found, it automatically runs:

- `helm uninstall <release> -n <namespace>`

before attempting the next install.

## Why this matters

This removes two kinds of low-value friction:

1. warning noise that obscures real failures
2. manual Helm cleanup after interrupted or failed Newt install attempts
