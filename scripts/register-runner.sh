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

# Get authentication token
echo ""
echo -e "${YELLOW}=== GitLab 16.0+ New Runner Registration Workflow ===${NC}"
echo ""
echo -e "${YELLOW}IMPORTANT: You must create the runner in GitLab UI first!${NC}"
echo ""
echo "Follow these steps:"
echo ""
# Determine the correct URL based on setup
if [[ "${GITLAB_HOSTNAME}" == *"."* ]] && [[ -z "${GITLAB_HTTP_PORT}" || "${GITLAB_HTTP_PORT}" == "80" || "${GITLAB_HTTP_PORT}" == "443" ]]; then
    # Production setup with domain (Cloudflare/Nginx)
    echo "  1. Go to https://${GITLAB_HOSTNAME}"
else
    # Local development setup
    echo "  1. Go to http://${GITLAB_HOSTNAME:-gitlab.local}:${GITLAB_HTTP_PORT:-8080}"
fi
echo "  2. Login as root (password from .env or run ./scripts/get-root-password.sh)"
echo "  3. Go to Admin Area → CI/CD → Runners"
echo "  4. Click 'New instance runner'"
echo "  5. Configure runner settings:"
echo "     - Platform: Linux"
echo "     - Tags: docker, linux, arm64 (or any tags you want)"
echo "     - Run untagged jobs: ✓ Enable (recommended for testing)"
echo "     - Protected: Leave unchecked (unless needed)"
echo "  6. Click 'Create runner'"
echo "  7. Copy the authentication token (starts with 'glrt-')"
echo ""
echo -e "${YELLOW}Note: All runner settings (tags, description, etc.) are configured in the UI.${NC}"
echo -e "${YELLOW}This script only registers the runner with the token you provide.${NC}"
echo ""

if [ -n "$GITLAB_RUNNER_REGISTRATION_TOKEN" ]; then
    echo -e "${GREEN}Found token in .env file: GITLAB_RUNNER_REGISTRATION_TOKEN${NC}"
    TOKEN="$GITLAB_RUNNER_REGISTRATION_TOKEN"
else
    read -p "Enter authentication token (glrt-...): " TOKEN
fi

if [ -z "$TOKEN" ]; then
    echo -e "${RED}Error: No token provided!${NC}"
    exit 1
fi

# Validate token format
if [[ ! "$TOKEN" =~ ^glrt- ]]; then
    echo ""
    echo -e "${RED}WARNING: Token doesn't start with 'glrt-'${NC}"
    echo "Make sure you're using the NEW authentication token from 'New instance runner',"
    echo "not the old registration token (which is deprecated)."
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Register the runner
echo ""
echo -e "${YELLOW}Registering runner with GitLab...${NC}"
echo ""

docker exec gitlab-runner gitlab-runner register \
    --non-interactive \
    --url "http://gitlab" \
    --token "$TOKEN" \
    --executor "docker" \
    --docker-image "alpine:latest" \
    --docker-privileged \
    --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" \
    --docker-volumes "/cache" \
    --docker-network-mode "gitlab-network"

if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✓ Runner registered successfully!                            ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "The runner is now active and ready to pick up jobs."
    echo ""
    echo -e "${YELLOW}Configuration Summary:${NC}"
    echo "  • Executor: Docker (with socket mounting)"
    echo "  • Default image: alpine:latest"
    echo "  • Privileged mode: Enabled"
    echo "  • Network: gitlab-network"
    echo "  • Docker socket: Mounted from host"
    echo ""
    echo -e "${YELLOW}View runner status:${NC}"
    echo "  • GitLab UI: Admin Area → CI/CD → Runners"
    echo "  • Command: docker exec gitlab-runner gitlab-runner list"
    echo ""
    echo -e "${YELLOW}Using the runner in .gitlab-ci.yml:${NC}"
    echo "  Use the tags you configured in the GitLab UI, for example:"
    echo ""
    echo "  build:"
    echo "    image: docker:latest"
    echo "    tags:"
    echo "      - docker"
    echo "    script:"
    echo "      - docker build -t my-image ."
    echo ""
    echo -e "${GREEN}All runner settings are managed in GitLab UI (tags, description, etc.)${NC}"
else
    echo ""
    echo -e "${RED}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ✗ Runner registration failed!                                ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Check the error message above for details."
    echo ""
    echo -e "${YELLOW}Common issues:${NC}"
    echo "  • Invalid token (make sure it starts with 'glrt-')"
    echo "  • GitLab not fully initialized (wait 3-5 minutes after startup)"
    echo "  • Network connectivity issues"
    echo ""
    exit 1
fi

