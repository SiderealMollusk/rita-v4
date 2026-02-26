#!/bin/bash

# 1. Load Global Project Settings
if [ -f "/workspaces/rita-v4/.labrc" ]; then
    source /workspaces/rita-v4/.labrc
    echo "✅ Project settings loaded ($OP_VAULT_ID)"
else
    echo "⚠️  Warning: .labrc not found"
fi

# 2. Load User/Session Context
if [ -f "/workspaces/rita-v4/.user.ctx" ]; then
    source /workspaces/rita-v4/.user.ctx
    echo "✅ User context loaded"
else
    echo "⚠️  Warning: .user.ctx not found"
fi

# 3. Export for Sub-processes
# Ensuring these are available to any scripts called after this one
export OP_VAULT_ID
export PANGOLIN_ENDPOINT