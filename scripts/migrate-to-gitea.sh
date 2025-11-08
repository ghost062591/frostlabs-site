#!/bin/bash
#
# Migrate frostlabs-site from GitHub to Gitea
#
# This script helps migrate your repository from GitHub to your Gitea instance
# at git.frostlabs.me
#
# Usage:
#   ./scripts/migrate-to-gitea.sh [username]
#
# Example:
#   ./scripts/migrate-to-gitea.sh doc
#

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
GITEA_DOMAIN="git.frostlabs.me"
REPO_NAME="frostlabs-site"
GITEA_USER="${1:-}"

if [ -z "$GITEA_USER" ]; then
    echo -e "${RED}Error: Gitea username required${NC}"
    echo "Usage: $0 <username>"
    echo "Example: $0 doc"
    exit 1
fi

GITEA_SSH_URL="git@${GITEA_DOMAIN}:${GITEA_USER}/${REPO_NAME}.git"
GITEA_HTTPS_URL="https://${GITEA_DOMAIN}/${GITEA_USER}/${REPO_NAME}.git"

echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  FrostLabs Site - Gitea Migration Script      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}This script will:${NC}"
echo "  1. Add git.frostlabs.me as a remote"
echo "  2. Push all branches and tags to Gitea"
echo "  3. Update your local repo to use Gitea as origin"
echo ""
echo -e "${YELLOW}Configuration:${NC}"
echo "  Gitea Domain: ${GITEA_DOMAIN}"
echo "  Gitea User:   ${GITEA_USER}"
echo "  Repository:   ${REPO_NAME}"
echo "  SSH URL:      ${GITEA_SSH_URL}"
echo ""

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Check current remotes
echo -e "${YELLOW}Current git remotes:${NC}"
git remote -v
echo ""

# Confirm before proceeding
read -p "Continue with migration? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Migration cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}Step 1: Testing SSH connection to Gitea...${NC}"
if ssh -T git@${GITEA_DOMAIN} 2>&1 | grep -q "Hi there"; then
    echo -e "${GREEN}✓ SSH connection successful${NC}"
    USE_SSH=true
else
    echo -e "${YELLOW}⚠ SSH connection failed, will use HTTPS${NC}"
    echo -e "${YELLOW}  You may be prompted for credentials${NC}"
    USE_SSH=false
fi
echo ""

# Add Gitea remote
echo -e "${GREEN}Step 2: Adding Gitea as remote...${NC}"
if git remote | grep -q "^gitea$"; then
    echo -e "${YELLOW}Remote 'gitea' already exists, removing...${NC}"
    git remote remove gitea
fi

if [ "$USE_SSH" = true ]; then
    git remote add gitea "${GITEA_SSH_URL}"
    echo -e "${GREEN}✓ Added remote: ${GITEA_SSH_URL}${NC}"
else
    git remote add gitea "${GITEA_HTTPS_URL}"
    echo -e "${GREEN}✓ Added remote: ${GITEA_HTTPS_URL}${NC}"
fi
echo ""

# Push all branches
echo -e "${GREEN}Step 3: Pushing all branches to Gitea...${NC}"
if git push gitea --all; then
    echo -e "${GREEN}✓ All branches pushed successfully${NC}"
else
    echo -e "${RED}✗ Failed to push branches${NC}"
    echo -e "${YELLOW}Make sure you've created the repository in Gitea first:${NC}"
    echo -e "${BLUE}  https://${GITEA_DOMAIN}/${GITEA_USER}/${REPO_NAME}${NC}"
    exit 1
fi
echo ""

# Push all tags
echo -e "${GREEN}Step 4: Pushing all tags to Gitea...${NC}"
if git push gitea --tags; then
    echo -e "${GREEN}✓ All tags pushed successfully${NC}"
else
    echo -e "${YELLOW}⚠ Warning: Failed to push tags (this is OK if you have no tags)${NC}"
fi
echo ""

# Verify push
echo -e "${GREEN}Step 5: Verifying remote repository...${NC}"
git ls-remote gitea > /dev/null 2>&1
echo -e "${GREEN}✓ Remote repository verified${NC}"
echo ""

# Ask if user wants to switch origin
echo -e "${YELLOW}Current remotes:${NC}"
git remote -v
echo ""
read -p "Switch 'origin' from GitHub to Gitea? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}Step 6: Switching origin to Gitea...${NC}"

    # Backup current origin URL
    GITHUB_URL=$(git remote get-url origin)
    echo -e "${BLUE}Backing up GitHub URL: ${GITHUB_URL}${NC}"

    # Remove old origin
    git remote remove origin
    echo -e "${GREEN}✓ Removed GitHub remote${NC}"

    # Rename gitea to origin
    git remote rename gitea origin
    echo -e "${GREEN}✓ Renamed 'gitea' to 'origin'${NC}"

    # Update branch tracking
    git branch --set-upstream-to=origin/main main
    echo -e "${GREEN}✓ Updated branch tracking${NC}"

    echo ""
    echo -e "${YELLOW}GitHub remote removed. If needed, you can restore it with:${NC}"
    echo -e "${BLUE}  git remote add github ${GITHUB_URL}${NC}"
else
    echo -e "${YELLOW}Keeping both remotes (GitHub and Gitea)${NC}"
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            Migration Complete! ✓               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "${BLUE}1. Verify in Gitea web UI:${NC}"
echo -e "   https://${GITEA_DOMAIN}/${GITEA_USER}/${REPO_NAME}"
echo ""
echo -e "${BLUE}2. Upload images to Cloudflare:${NC}"
echo "   export CF_ACCOUNT_ID=\"your-account-id\""
echo "   export CF_API_TOKEN=\"your-api-token\""
echo "   ./scripts/upload-to-cloudflare.sh static/photos"
echo ""
echo -e "${BLUE}3. Set up Cloudflare Pages:${NC}"
echo "   npm install -g wrangler"
echo "   wrangler login"
echo "   wrangler pages project create frostlabs-site"
echo ""
echo -e "${BLUE}4. Deploy your site:${NC}"
echo "   ./scripts/build-and-deploy.sh"
echo ""
echo -e "${YELLOW}Current remotes:${NC}"
git remote -v
echo ""
