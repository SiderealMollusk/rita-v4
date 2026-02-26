FROM mcr.microsoft.com/devcontainers/base:debian

# Avoid prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install K8s Tooling, 1Password CLI, and Pangolin
RUN apt-get update && apt-get install -y curl ca-certificates gnupg lsb-release \
    # 1. Install kubectl
    && curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl \
    # 2. Install Helm
    && curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash \
    # 3. Install 1Password CLI
    && curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | tee /etc/apt/sources.list.d/1password.list \
    && apt-get update && apt-get install -y 1password-cli \
    # 4. Install Pangolin & Newt
    && curl -fsSL https://static.pangolin.net/get-cli.sh | bash \
    && curl -fsSL https://static.pangolin.net/get-newt.sh | bash \
    # Clean up
    && apt-get clean && rm -rf /var/lib/apt/lists/* kubectl

# Use the non-root user provided by the base image
USER vscode