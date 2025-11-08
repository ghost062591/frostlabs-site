#!/bin/bash
#
# Quick Publish Script - From Obsidian to Live Site
#
# This script handles the complete workflow:
#   1. Commits your changes to git
#   2. Pushes to Gitea
#   3. Builds Hugo site
#   4. Deploys to Cloudflare Pages
#
# Usage:
#   ./scripts/publish.sh "Your commit message"
#   ./scripts/publish.sh (will use default message)
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Configuration
PROJECT_NAME="frostlabs-site"
BRANCH="main"  # Production branch

# Cloudflare credentials
export CLOUDFLARE_ACCOUNT_ID="478c5f86904a5dd27b66b051cde8d51a"
export CLOUDFLARE_API_TOKEN="3sanRhqZV1-RtJukxXy-DpiU_ZazpSSufvbJzTvb"

# Get commit message from argument or use default
COMMIT_MSG="${1:-Update content from Obsidian}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   FrostLabs Quick Publish Workflow    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Git Status
echo -e "${YELLOW}📋 Checking git status...${NC}"
git status --short
echo ""

# Step 2: Commit changes
echo -e "${YELLOW}💾 Committing changes...${NC}"
git add .
if git diff --staged --quiet; then
    echo -e "${GREEN}✓ No changes to commit${NC}"
else
    git commit -m "$COMMIT_MSG"
    echo -e "${GREEN}✓ Changes committed${NC}"
fi
echo ""

# Step 3: Push to Gitea
echo -e "${YELLOW}📤 Pushing to Gitea...${NC}"
git push origin "$BRANCH"
echo -e "${GREEN}✓ Pushed to git.frostlabs.me${NC}"
echo ""

# Step 4: Load nvm and use Node 20
echo -e "${YELLOW}🔧 Loading Node.js environment...${NC}"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
nvm use 20 > /dev/null 2>&1
echo -e "${GREEN}✓ Node $(node --version) ready${NC}"
echo ""

# Step 5: Build Hugo site
echo -e "${YELLOW}🔨 Building Hugo site...${NC}"
rm -rf public/
hugo --gc --minify
if [ ! -d "public" ]; then
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Site built successfully${NC}"
echo ""

# Step 6: Deploy to Cloudflare Pages
echo -e "${YELLOW}🚀 Deploying to Cloudflare Pages...${NC}"
wrangler pages deploy public \
    --project-name "$PROJECT_NAME" \
    --branch "$BRANCH" \
    --commit-dirty=true 2>&1 | grep -E "(Success|Deployment complete|https://)"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          🎉 Publish Complete!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Your site is live at:${NC}"
echo "  https://blog.frostlabs.me"
echo ""
