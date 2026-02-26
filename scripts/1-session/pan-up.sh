#!/bin/bash

# 1. Load the Global Lab Config
source .labrc || { echo "❌ Missing .labrc"; exit 1; }

# 2. Load the Local User Context
if [ -f .user.ctx ]; then
    source .user.ctx
else
    echo "⚠️  No .user.ctx found. Who are you?"
    echo "LAB_IDENTITY='Default'" > .user.ctx
    echo "Created .user.ctx with 'Default'. Edit it if needed."
    source .user.ctx
fi

echo "🔗 Connecting to Lab: $PANGOLIN_ENDPOINT"
echo "🔑 Using Vault Item: ${PANGOLIN_PREFIX}${LAB_IDENTITY}"

# 3. Inject and Run
op run --env-file=.op-map.tpl -- pangolin up --attach