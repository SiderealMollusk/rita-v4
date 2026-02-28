## THIS UNVERIFIED LLM SLOP
It's mostly here just to give me a sense of what commands I should know about

1. Context & Environment

Before running any kubectl commands manually, ensure your shell is pointing to the isolated lab config:

Bash
source scripts/.k8s-env
# Verify you are looking at the right cluster
kubectl config current-context
2. Force Cleanup (The "Nuclear" Options)

When the automated scripts fail or Docker containers hang.

Prune stopped k3d components:

Bash
k3d cluster stop rita-local
docker system prune -f --filter "label=app=k3d"
Remove the isolated Kubeconfig manually:

Bash
rm -f $HOME/.kube/config-rita-local
3. External Secrets Operator (ESO) Troubleshooting

Since this is your primary bridge to 1Password, you'll need these to debug sync issues.

Check ESO Logs (for auth/connection errors):

Bash
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets
Check the status of the SecretStore:

Bash
kubectl describe secretstore onepassword-store
Force a re-sync of a specific secret:

Bash
kubectl annotate externalsecret local-db-credentials force-sync=$(date +%s) --overwrite
4. Cluster Maintenance

Check Node Resource Usage (RAM/CPU):

Bash
kubectl top nodes
View Traefik Ingress Dashboard:
K3d usually sets this up on a random port. Find the entry points:

Bash
kubectl get svc -n kube-system traefik
5. Quick Manifest Application

To apply all your lab logic in the correct order:

Bash
kubectl apply -f manifests/