#!/bin/bash

# Configuration
TOKEN_VAR="OP_SERVICE_ACCOUNT_TOKEN"
ZSHRC="$HOME/.zshrc"

echo "---------------------------------------------------"
echo "  1Password Service Account Setup (rita-v4)"
echo "---------------------------------------------------"

# 1. Environment Guard: Abort if inside a container
if [ -f /.dockerenv ] || grep -q 'docker\|containerd' /proc/1/cgroup 2>/dev/null; then
    echo "❌ ERROR: This script must be run on your Mac (Host), not inside the Dev Container."
    echo "   Please exit the Dev Container terminal and run this on your MacBook."
    exit 1
fi

# 2. OS Check: Ensure it's macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ ERROR: This setup script is designed for macOS."
    exit 1
fi

# 3. Check if token is already active
if [ ! -z "${!TOKEN_VAR}" ]; then
    echo "✅ $TOKEN_VAR is already active in this session."
    exit 0
fi

# 4. Check if it exists in .zshrc but isn't sourced
if grep -q "export $TOKEN_VAR=" "$ZSHRC" 2>/dev/null; then
    echo "ℹ️  Found token in $ZSHRC but it isn't in your current shell."
    echo "   Action: Run 'source ~/.zshrc' on your Mac."
    exit 0
fi

echo "❌ No token found. You need a Service Account token."
echo "   Get it here: https://start.1password.com/developer/service-accounts"
echo "---------------------------------------------------"

# 5. Validation Loop
while true; do
    read -rsp "Paste your Service Account Token (starts with ops_): " user_token
    echo "" # Newline after hidden input

    # Validation: Must start with ops_ and be long (JWT format)
    if [[ $user_token =~ ^ops_ ]] && [ ${#user_token} -ge 200 ]; then
        echo "✅ Token format validated (starts with 'ops_', length: ${#user_token})."
        
        # Append to .zshrc
        echo "" >> "$ZSHRC"
        echo "# 1Password Service Account: rita-v4-devcontainer" >> "$ZSHRC"
        echo "export $TOKEN_VAR=\"$user_token\"" >> "$ZSHRC"
        
        echo "✅ Token saved to $ZSHRC"
        echo "🚀 ACTION REQUIRED: Run 'source ~/.zshrc' on your Mac now."
        break
    else
        echo "⚠️  Invalid token. It must start with 'ops_' and be a very long string."
        echo "   Please try again or press Ctrl+C to exit."
    fi
done