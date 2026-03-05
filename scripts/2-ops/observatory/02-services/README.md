# Observatory Services Phase

This phase installs actual services after the base machine/cluster lane is complete.

Current execution order:
1. `../10-install-newt.sh`

Use `00-run-all.sh` in this directory to run the current services phase.

Notes:
1. This phase may cross operator boundaries such as Pangolin site registration and 1Password-backed credentials.
2. It is expected to fail explicitly if those prerequisites do not exist yet.
