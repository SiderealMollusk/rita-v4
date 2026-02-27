I created a 1password service accound

a script that will help you put that token into your host system

passes it into the dev container.

scripts/1-session-setup/01-load-variables.sh is used to load project and user variables.

```bash
 op item get "test" --vault "rita-v4" --fields label="foo" --reveal
"bar
"
vscode ➜ /workspaces/rita-v4 (master) $ 
```
works

did some document chores

actually created the repo

## 2026-02-27 Update
- Historical checkpoint only.
- Secret bridge is now validated through VPS Ansible flow as well.
- See latest logs: `0060-vps-ansible-bootstrap.md`, `0070-vps-reset-and-reseed.md`.
