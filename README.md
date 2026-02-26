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
per session run scripts/1-session-setup scripts
(automate this maybe?)

