#!/bin/bash

# Define colors for feedback
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔍 Checking Docker socket availability..."

# 1. Check if the socket file even exists
if [ ! -S /var/run/docker.sock ]; then
    echo -e "${RED}❌ Error: /var/run/docker.sock not found.${NC}"
    echo "Check your devcontainer.json mounts."
    exit 1
fi

# 2. Attempt to fix permissions if they are restricted
# We use sudo here because the socket is owned by root
if [ ! -w /var/run/docker.sock ]; then
    echo "🔐 Socket permissions are restricted. Adjusting..."
    sudo chmod 666 /var/run/docker.sock
fi

# 3. Final verification test
if docker ps > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Docker is alive and reachable without sudo.${NC}"
    
    # Optional: Show a quick count of running containers
    COUNT=$(docker ps -q | wc -l)
    echo "📊 Currently running containers: $COUNT"
else
    echo -e "${RED}❌ Error: Cannot connect to Docker daemon.${NC}"
    echo "Is Docker Desktop running on your Mac?"
    exit 1
fi