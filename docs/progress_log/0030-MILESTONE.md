0030-MILESTONE: Environment & 1Password Core
Status: ✅ COMPLETE
Date: 2026-02-26
Scope: Establishing the "Secure Bridge" between the local Mac host and the Dev Container.

🎯 Objective

To create a reproducible development environment where sensitive credentials (secrets) are never stored in plain text, but are instantly available to CLI tools and scripts using a 1Password Service Account.

🏗️ Architecture Components

Host-to-Container Injection: Configured devcontainer.json to pipe OP_SERVICE_ACCOUNT_TOKEN from the Mac’s environment into the Docker container.

Configuration Logic: Implemented .labrc and .user.ctx as the primary sources for non-sensitive environment variables (e.g., OP_VAULT_ID, PANGOLIN_ENDPOINT).

The "Orchestrator" Pattern: look in 1-session-setup for current.

🧪 Verification Results

The following "Proof of Life" tests were successful inside the container:

Identity Check: op whoami correctly identifies the 1Password Service Account.

Vault Visibility: The CLI successfully targets the rita-v4 vault using the injected $OP_VAULT_ID.

Secret Retrieval: Successfully retrieved the value "bar" from the test item using:
op item get "test" --vault "rita-v4" --fields label="foo" --reveal.

🛠️ Key Commands Established

Intent	Command
Initialize Session	scripts/1-session/06-pangolin-up.sh
Direct Secret Pull	op read "op://rita-v4/test/foo"
Re-sync Config	source .labrc
⏭️ Next Step: Block 2

With the "Secure Bridge" verified, the next phase moves from Identity to Infrastructure. We will spin up a local Kubernetes instance (k3d/Kind) to test the External Secrets Operator—ensuring we can move "bar" from 1Password into a K8s pod without manual script intervention.
