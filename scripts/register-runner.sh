#!/bin/bash
# GitLab Runner Registration Script
# 
# This script registers a GitLab Runner with Docker executor
# Run this after GitLab is fully initialized (usually 3-5 minutes after docker compose up)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Default values
GITLAB_URL="http://${GITLAB_HOSTNAME:-gitlab.local}"
RUNNER_NAME="${RUNNER_DESCRIPTION:-docker-runner}"
RUNNER_TAGS="${RUNNER_TAGS:-docker,linux,arm64}"

echo -e "${YELLOW}=== GitLab Runner Registration ===${NC}"
echo ""

# Check if GitLab is running
echo -e "${YELLOW}Checking if GitLab is running...${NC}"
if ! docker ps | grep -q "gitlab"; then
    echo -e "${RED}Error: GitLab container is not running!${NC}"
    echo "Run 'docker compose up -d' first and wait for GitLab to initialize."
    exit 1
fi

# Check GitLab health
echo -e "${YELLOW}Checking GitLab health...${NC}"
HEALTH_STATUS=$(docker inspect --format='{{.State.Health.Status}}' gitlab 2>/dev/null || echo "unknown")
if [ "$HEALTH_STATUS" != "healthy" ]; then
    echo -e "${YELLOW}Warning: GitLab is not fully healthy yet (status: $HEALTH_STATUS)${NC}"
    echo "GitLab may still be initializing. This can take 3-5 minutes."
    echo ""
    read -p "Do you want to continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Get registration token
echo ""
echo -e "${YELLOW}To register the runner, you need a registration token.${NC}"
echo ""
echo "Get it from GitLab:"
# Determine the correct URL based on setup
if [[ "${GITLAB_HOSTNAME}" == *"."* ]] && [[ -z "${GITLAB_HTTP_PORT}" || "${GITLAB_HTTP_PORT}" == "80" || "${GITLAB_HTTP_PORT}" == "443" ]]; then
    # Production setup with domain (Cloudflare/Nginx)
    echo "  1. Go to https://${GITLAB_HOSTNAME}"
else
    # Local development setup
    echo "  1. Go to http://${GITLAB_HOSTNAME:-gitlab.local}:${GITLAB_HTTP_PORT:-8080}"
fi
echo "  2. Login as root (password from .env or initial_root_password)"
echo "  3. Go to Admin Area -> CI/CD -> Runners"
echo "  4. Click 'New instance runner' and copy the token"
echo ""

if [ -n "$GITLAB_RUNNER_REGISTRATION_TOKEN" ]; then
    echo -e "${GREEN}Found token in .env file${NC}"
    TOKEN="$GITLAB_RUNNER_REGISTRATION_TOKEN"
else
    read -p "Enter registration token: " TOKEN
fi

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: No token provided!${NC}"
    exit 1
fi

# Register the runner
echo ""
echo -e "${YELLOW}Registering runner...${NC}"
echo ""
echo -e "${YELLOW}Note: GitLab 16.0+ uses new runner registration workflow.${NC}"
echo -e "${YELLOW}Tags, description, and other settings are configured in GitLab UI.${NC}"
echo ""

docker exec gitlab-runner gitlab-runner register \
    --non-interactive \
    --url "http://gitlab" \
    --token "$TOKEN" \
    --executor "docker" \
    --docker-image "docker:latest" \
    --docker-privileged \
    --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
    --docker-volumes "/cache" \
    --docker-network-mode "gitlab-network"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=== Runner registered successfully! ===${NC}"
    echo ""
    echo "The runner is now available in GitLab."
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "1. Go to Admin Area → CI/CD → Runners"
    echo "2. Find your runner and click 'Edit'"
    echo "3. Configure:"
    echo "   - Description: docker-runner (or any name)"
    echo "   - Tags: docker, linux, arm64"
    echo "   - Run untagged jobs: Enable if needed"
    echo ""
    echo "To use this runner in your .gitlab-ci.yml, add tags:"
    echo "  tags:"
    echo "    - docker"
    echo "    - linux"
    echo "    - arm64"
else
    echo ""
    echo -e "${RED}=== Runner registration failed! ===${NC}"
    echo ""
    echo "Check the error message above for details."
    exit 1
fi

