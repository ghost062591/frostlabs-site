#!/bin/bash
#
# Build and Deploy to Cloudflare Pages
#
# Prerequisites:
#   npm install -g wrangler
#   wrangler login
#
# Usage:
#   ./scripts/build-and-deploy.sh
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_NAME="frostlabs-site"
BRANCH="${1:-main}"

echo -e "${GREEN}Starting FrostLabs Site Deployment${NC}"
echo "=========================================="

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo -e "${RED}Error: wrangler CLI not found${NC}"
    echo "Install with: npm install -g wrangler"
    echo "Then login with: wrangler login"
    exit 1
fi

# Check if Hugo is installed
if ! command -v hugo &> /dev/null; then
    echo -e "${RED}Error: hugo not found${NC}"
    echo "Install Hugo: https://gohugo.io/installation/"
    exit 1
fi

# Clean previous build
echo -e "${YELLOW}Cleaning previous build...${NC}"
rm -rf public/

# Build Hugo site
echo -e "${YELLOW}Building Hugo site...${NC}"
hugo --minify

if [ ! -d "public" ]; then
    echo -e "${RED}Error: Hugo build failed (public/ directory not found)${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build complete${NC}"

# Deploy to Cloudflare Pages
echo -e "${YELLOW}Deploying to Cloudflare Pages...${NC}"
wrangler pages deploy public \
    --project-name "$PROJECT_NAME" \
    --branch "$BRANCH"

echo ""
echo -e "${GREEN}=========================================="
echo "✓ Deployment complete!"
echo "==========================================${NC}"
echo ""
echo "Your site should be live at:"
echo "  https://$PROJECT_NAME.pages.dev"
echo ""
echo "Check deployment status at:"
echo "  https://dash.cloudflare.com/"
