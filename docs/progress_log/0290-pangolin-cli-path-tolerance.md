# 0290 Pangolin CLI Path Tolerance

As of this update, the host/operator scripts no longer assume the Pangolin CLI is immediately available on the interactive shell `PATH` after installation.

## What changed

1. shared Pangolin CLI lookup was added to:
   - `/Users/virgil/Dev/rita-v4/scripts/lib/runbook.sh`
2. the host Pangolin install script now treats this as a valid success state:
   - binary installed at `~/.local/bin/pangolin`
   - shell `PATH` not yet updated
3. the host blueprint apply script now resolves Pangolin from:
   - `PATH`
   - or `~/.local/bin/pangolin`

## Why

The installer's normal successful behavior on the Mac is:
1. install Pangolin into `~/.local/bin`
2. warn that the shell `PATH` still needs updating

That is not an error condition and should not break follow-on host automation.
