# Rita V4 
my homelab repo

## Requirements
docker on host system. 
we use a dev container, and k8 testing on host docker

## Setup
one time run scripts/0-local-setup/01-ssh-config.sh from host machine

create a .user.ctx
```
# My local identity suffix
LAB_IDENTITY="Admin"
```

## Per session / restart of devcontainer
run:
```bash
source scripts/1-session/01-load-variables.sh
scripts/1-session/03-k8s-up.sh
scripts/1-session/04-k8s-status.sh
```

If kubectl shows `host.docker.internal:* connection refused`, run:
```bash
scripts/1-session/03-k8s-up.sh
```
This refreshes the isolated kubeconfig at `$HOME/.kube/config-rita-local` and re-checks API reachability.
