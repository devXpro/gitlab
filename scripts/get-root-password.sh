#!/bin/bash
# Get GitLab initial root password
# This password is auto-generated on first startup and stored in the container

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== GitLab Root Password ===${NC}"
echo ""

# Check if GitLab container is running
if ! docker ps | grep -q "gitlab"; then
    echo -e "${RED}Error: GitLab container is not running!${NC}"
    echo "Start GitLab with: docker compose up -d"
    exit 1
fi

# Try to get password from container
PASSWORD=$(docker exec gitlab grep 'Password:' /etc/gitlab/initial_root_password 2>/dev/null | awk '{print $2}' || echo "")

if [ -n "$PASSWORD" ]; then
    echo -e "${GREEN}Initial root password:${NC}"
    echo ""
    echo "  $PASSWORD"
    echo ""
    echo -e "${YELLOW}Note:${NC} This password file is automatically deleted 24 hours after first reconfigure."
    echo "If you see this message, save the password now!"
    echo ""
    echo "Login at: http://$(grep GITLAB_HOSTNAME .env 2>/dev/null | cut -d'=' -f2 || echo 'gitlab.local'):$(grep GITLAB_HTTP_PORT .env 2>/dev/null | cut -d'=' -f2 || echo '8080')"
    echo "Username: root"
    echo "Password: $PASSWORD"
else
    # Check if password was set in .env
    if [ -f .env ]; then
        ENV_PASSWORD=$(grep GITLAB_ROOT_PASSWORD .env | cut -d'=' -f2)
        if [ -n "$ENV_PASSWORD" ]; then
            echo -e "${GREEN}Root password from .env file:${NC}"
            echo ""
            echo "  $ENV_PASSWORD"
            echo ""
        else
            echo -e "${RED}Password not found!${NC}"
            echo ""
            echo "Possible reasons:"
            echo "  1. The initial_root_password file was deleted (24h after first start)"
            echo "  2. GitLab is still initializing (wait a few minutes)"
            echo "  3. Password was already changed in GitLab UI"
            echo ""
            echo "If you forgot the password, you can reset it:"
            echo "  docker exec -it gitlab gitlab-rake 'gitlab:password:reset[root]'"
        fi
    else
        echo -e "${RED}Password not found and .env file doesn't exist!${NC}"
        echo ""
        echo "To reset the password:"
        echo "  docker exec -it gitlab gitlab-rake 'gitlab:password:reset[root]'"
    fi
fi

echo ""

