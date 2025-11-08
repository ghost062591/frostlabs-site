# Migrate to Gitea + Cloudflare Pages + Cloudflare Images

This guide will walk you through migrating your FrostLabs site from GitHub Pages to your self-hosted Gitea instance with Cloudflare Pages for building/hosting and Cloudflare Images for media.

## Overview

**Current Setup**:
- Repository: GitHub (`ghost062591/frostlabs-site`)
- Hosting: GitHub Pages
- Images: Local (532 MB in `static/photos/`)

**New Setup**:
- Repository: Your Gitea server
- Hosting: Cloudflare Pages (free, global CDN)
- Images: Cloudflare Images ($5/month)
- Build: Cloudflare (automatic on git push)

## Prerequisites

Before starting, ensure you have:

- [ ] Gitea server running and accessible
- [ ] Cloudflare account with Cloudflare Images enabled
- [ ] Cloudflare Images API credentials (Account ID + API Token)
- [ ] SSH access to your Gitea server (or HTTPS if preferred)

---

## Part 1: Migrate Repository to Gitea

### Step 1: Create New Repository in Gitea

1. Log into your Gitea instance
2. Click **"+"** → **"New Repository"**
3. Settings:
   - **Owner**: Your user/organization
   - **Repository Name**: `frostlabs-site`
   - **Visibility**: Private or Public (your choice)
   - **Initialize**: Leave unchecked (we're pushing existing repo)
4. Click **"Create Repository"**
5. Copy the repository URL (SSH or HTTPS)

Example URLs:
- SSH: `git@your-gitea-domain.com:username/frostlabs-site.git`
- HTTPS: `https://your-gitea-domain.com/username/frostlabs-site.git`

### Step 2: Add Gitea as Remote

In your local repository:

```bash
# Add Gitea as a new remote
git remote add gitea git@your-gitea-domain.com:username/frostlabs-site.git

# Verify remotes
git remote -v

# Should show:
# origin    git@github.com:ghost062591/frostlabs-site.git (fetch)
# origin    git@github.com:ghost062591/frostlabs-site.git (push)
# gitea     git@your-gitea-domain.com:username/frostlabs-site.git (fetch)
# gitea     git@your-gitea-domain.com:username/frostlabs-site.git (push)
```

### Step 3: Push to Gitea

```bash
# Push all branches to Gitea
git push gitea --all

# Push all tags to Gitea
git push gitea --tags

# Verify in Gitea web UI that all branches/commits are there
```

### Step 4: Update Default Remote

Once verified Gitea has everything:

```bash
# Remove GitHub remote
git remote remove origin

# Rename Gitea to origin
git remote rename gitea origin

# Verify
git remote -v
# Should show only Gitea as origin
```

### Step 5: Update Local Branches to Track Gitea

```bash
# Update main branch to track Gitea
git branch --set-upstream-to=origin/main main

# Pull to verify connection
git pull
```

---

## Part 2: Upload Images to Cloudflare Images

### Step 1: Get Cloudflare Credentials

You should already have these from purchasing Cloudflare Images.

**If not, see**: `CLOUDFLARE-IMAGES-MIGRATION.md` for detailed instructions on:
- Finding your Account ID
- Creating an API token
- Creating variants (`thumbnail` and `public`)

### Step 2: Configure Hugo

Add your Cloudflare account hash to Hugo config:

**File**: `config/_default/params.toml`

```toml
[cloudflare]
  [cloudflare.images]
    # Find this by uploading a test image in Cloudflare dashboard
    # URL format: https://imagedelivery.net/YOUR-HASH-HERE/image-id/variant
    accountHash = "your-account-hash-here"
```

### Step 3: Upload Images

```bash
# Set credentials
export CF_ACCOUNT_ID="your-account-id"
export CF_API_TOKEN="your-api-token"

# Start with one directory to test
./scripts/upload-to-cloudflare.sh static/photos/house-project/delivery

# If that works, upload everything
./scripts/upload-to-cloudflare.sh static/photos
```

This creates: `cloudflare-image-mapping.csv` with all image IDs.

### Step 4: Update Content Files

Update your markdown files to use Cloudflare Images.

**Example**: `content/projects/house-project.md`

**Before**:
```markdown
{{< lightbox-carousel >}}
  <img src="/photos/house-project/delivery/Delivery_001.jpg" alt="Delivery 1" data-caption="Caption" />
{{< /lightbox-carousel >}}
```

**After**:
```markdown
{{< lightbox-carousel >}}
  <img src="cf:house-project-delivery-Delivery_001" alt="Delivery 1" data-caption="Caption" />
{{< /lightbox-carousel >}}
```

Use `cloudflare-image-mapping.csv` to find the correct image IDs.

### Step 5: Test Locally

```bash
hugo server

# Verify:
# - Images load correctly
# - Carousel thumbnails work
# - Lightbox shows full images
# - No console errors
```

### Step 6: Commit Changes

```bash
git add .
git commit -m "Migrate to Cloudflare Images CDN"
git push origin main
```

---

## Part 3: Set Up Cloudflare Pages

### Step 1: Create Cloudflare Pages Project

1. Go to https://dash.cloudflare.com/
2. Click **"Workers & Pages"** in left sidebar
3. Click **"Create application"** → **"Pages"** tab → **"Connect to Git"**
4. Click **"Add account"** → **"Gitea"**

**Note**: Cloudflare doesn't have native Gitea integration, so we'll use **Generic Git**.

#### Alternative: Use Cloudflare API or Manual Uploads

Since Cloudflare Pages doesn't natively support Gitea, you have two options:

**Option A: Use Cloudflare Wrangler CLI** (Recommended)
- Build locally or in Gitea Actions
- Deploy via CLI: `wrangler pages deploy`
- Automated with Gitea Actions/webhooks

**Option B: Use GitHub as Mirror**
- Keep GitHub repo as deploy-only mirror
- Push to Gitea (primary)
- Auto-sync Gitea → GitHub via webhook
- Cloudflare Pages builds from GitHub

**I'll document Option A below (Wrangler CLI)** since you want to delete GitHub.

### Step 2: Install Wrangler CLI

On your local machine (or in Gitea Actions):

```bash
npm install -g wrangler

# Login to Cloudflare
wrangler login

# This opens a browser for authentication
```

### Step 3: Create Pages Project

```bash
# Create new Pages project
wrangler pages project create frostlabs-site

# Follow prompts:
# - Production branch: main
```

### Step 4: Configure Build Settings

Create a build script in your repo.

**File**: `scripts/build-and-deploy.sh`

```bash
#!/bin/bash
set -e

echo "Building Hugo site..."
hugo --minify

echo "Deploying to Cloudflare Pages..."
wrangler pages deploy public --project-name frostlabs-site

echo "Deployment complete!"
```

Make it executable:

```bash
chmod +x scripts/build-and-deploy.sh
```

### Step 5: Deploy Manually (First Time)

```bash
# Build Hugo
hugo --minify

# Deploy to Cloudflare Pages
wrangler pages deploy public --project-name frostlabs-site --branch main

# You'll get a URL like: https://frostlabs-site.pages.dev
```

### Step 6: Configure Custom Domain (Optional)

1. In Cloudflare Pages dashboard
2. Go to your project → **"Custom domains"**
3. Click **"Set up a custom domain"**
4. Enter: `frostlabs.com` (or your domain)
5. Cloudflare automatically configures DNS

---

## Part 4: Automate Deployments with Gitea Actions

Gitea Actions (similar to GitHub Actions) can auto-deploy on push.

### Step 1: Enable Gitea Actions

If not already enabled in your Gitea instance, check with your admin or enable it.

### Step 2: Create Gitea Actions Workflow

**File**: `.gitea/workflows/deploy.yml`

```yaml
name: Deploy to Cloudflare Pages

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v2
        with:
          hugo-version: 'latest'
          extended: true

      - name: Build site
        run: hugo --minify

      - name: Deploy to Cloudflare Pages
        uses: cloudflare/pages-action@v1
        with:
          apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
          projectName: frostlabs-site
          directory: public
          gitHubToken: ${{ secrets.GITHUB_TOKEN }}
```

### Step 3: Add Secrets to Gitea

1. In Gitea, go to your repository
2. **Settings** → **Secrets** → **Actions**
3. Add these secrets:
   - `CLOUDFLARE_API_TOKEN`: Your Cloudflare API token
   - `CLOUDFLARE_ACCOUNT_ID`: Your Cloudflare account ID

### Step 4: Test Auto-Deploy

```bash
# Make a small change
echo "Test deploy" >> README.md

# Commit and push
git add README.md
git commit -m "Test Gitea Actions deployment"
git push origin main

# Check Gitea Actions tab to see workflow run
# Site should auto-deploy to Cloudflare Pages
```

---

## Part 5: Clean Up GitHub

### Step 1: Verify Everything Works

Before deleting GitHub repo, verify:

- [ ] Gitea has all branches and tags
- [ ] Cloudflare Pages is building successfully
- [ ] Images load from Cloudflare Images
- [ ] Site is accessible at your domain/Pages URL
- [ ] Gitea Actions deploys automatically

### Step 2: Archive GitHub Repo (Optional)

Before deleting, you could archive it temporarily:

1. Go to GitHub repo settings
2. Scroll to **"Danger Zone"**
3. Click **"Archive this repository"**
4. Wait a week to ensure everything works

### Step 3: Delete GitHub Repo

Once confident:

1. Go to https://github.com/ghost062591/frostlabs-site/settings
2. Scroll to **"Danger Zone"**
3. Click **"Delete this repository"**
4. Type the repo name to confirm
5. Done!

---

## Architecture Summary

```
┌─────────────────┐
│   You (local)   │
│   git push      │
└────────┬────────┘
         │
         v
┌─────────────────┐      ┌──────────────────┐
│  Gitea Server   │      │ Cloudflare Pages │
│  (git hosting)  │─────>│ (auto-build)     │
└─────────────────┘      └──────────────────┘
                                  │
                                  v
                         ┌──────────────────┐
                         │   Global CDN     │
                         │ (pages.dev or    │
                         │  custom domain)  │
                         └──────────────────┘

┌─────────────────┐
│ Cloudflare      │
│ Images CDN      │◄─── Images served globally
│ ($5/month)      │     from edge locations
└─────────────────┘
```

---

## Cost Breakdown

| Service | Cost | Notes |
|---------|------|-------|
| Gitea hosting | $0* | Self-hosted in your homelab |
| Cloudflare Pages | $0 | Free tier (unlimited bandwidth!) |
| Cloudflare Images | $5/month | 100k images, unlimited transforms |
| **Total** | **$5/month** | vs GitHub Pages (free but slower) |

*Electricity costs for homelab not included 😄

---

## Troubleshooting

### Gitea Actions not working

Check if Actions are enabled:
- Gitea admin panel → Configuration → Actions

Or deploy manually via Wrangler:
```bash
./scripts/build-and-deploy.sh
```

### Cloudflare Pages build fails

Check Hugo version compatibility:
- Cloudflare uses Hugo extended
- May need to specify version in workflow

### Images not loading

Verify in browser console:
- Check `accountHash` in `params.toml`
- Verify variants exist: `thumbnail`, `public`
- Check image IDs match Cloudflare dashboard

### Can't push to Gitea

Check SSH key:
```bash
ssh -T git@your-gitea-domain.com
# Should return: Hi there, username!
```

---

## Next Steps

1. [ ] Create repository in Gitea
2. [ ] Push code to Gitea
3. [ ] Upload images to Cloudflare Images
4. [ ] Update Hugo content to use `cf:` image syntax
5. [ ] Test locally
6. [ ] Set up Cloudflare Pages (Wrangler or Actions)
7. [ ] Deploy and verify
8. [ ] Configure custom domain
9. [ ] Delete GitHub repo

---

## Quick Command Reference

```bash
# Migrate to Gitea
git remote add gitea git@your-gitea.com:user/frostlabs-site.git
git push gitea --all --tags
git remote remove origin
git remote rename gitea origin

# Upload images
export CF_ACCOUNT_ID="..." CF_API_TOKEN="..."
./scripts/upload-to-cloudflare.sh static/photos

# Deploy to Cloudflare Pages
hugo --minify
wrangler pages deploy public --project-name frostlabs-site
```

---

Ready to start? Let me know if you need help with any specific step!
