#!/bin/bash
# Generate self-signed SSL certificate for GitLab with Cloudflare
# This script creates a self-signed certificate that Cloudflare can use in Full (Strict) mode

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  GitLab Self-Signed SSL Certificate Generator                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: This script must be run as root${NC}"
    exit 1
fi

# Get domain names
read -p "Enter your GitLab domain (e.g., git.example.com): " GITLAB_DOMAIN
read -p "Enter your Registry domain (e.g., registry.example.com): " REGISTRY_DOMAIN

# Certificate directory
CERT_DIR="/etc/nginx/ssl"
mkdir -p "$CERT_DIR"

echo ""
echo -e "${YELLOW}Generating self-signed certificate...${NC}"
echo ""

# Generate private key
openssl genrsa -out "$CERT_DIR/gitlab.key" 4096

# Generate certificate signing request (CSR)
openssl req -new -key "$CERT_DIR/gitlab.key" -out "$CERT_DIR/gitlab.csr" \
    -subj "/C=US/ST=State/L=City/O=Organization/CN=$GITLAB_DOMAIN"

# Create config file for SAN (Subject Alternative Names)
cat > "$CERT_DIR/gitlab.ext" << EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $GITLAB_DOMAIN
DNS.2 = $REGISTRY_DOMAIN
EOF

# Generate self-signed certificate (valid for 10 years)
openssl x509 -req -in "$CERT_DIR/gitlab.csr" \
    -signkey "$CERT_DIR/gitlab.key" \
    -out "$CERT_DIR/gitlab.crt" \
    -days 3650 \
    -sha256 \
    -extfile "$CERT_DIR/gitlab.ext"

# Set proper permissions
chmod 600 "$CERT_DIR/gitlab.key"
chmod 644 "$CERT_DIR/gitlab.crt"

# Clean up CSR and extension file
rm -f "$CERT_DIR/gitlab.csr" "$CERT_DIR/gitlab.ext"

echo ""
echo -e "${GREEN}✓ Certificate generated successfully!${NC}"
echo ""
echo -e "${YELLOW}Certificate details:${NC}"
echo "  Location: $CERT_DIR/gitlab.crt"
echo "  Key:      $CERT_DIR/gitlab.key"
echo "  Valid for: 10 years"
echo "  Domains:   $GITLAB_DOMAIN, $REGISTRY_DOMAIN"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Update Nginx configuration to use these certificates"
echo "  2. Reload Nginx: systemctl reload nginx"
echo "  3. Set Cloudflare SSL/TLS mode to 'Full (Strict)'"
echo ""
echo -e "${GREEN}Done!${NC}"

