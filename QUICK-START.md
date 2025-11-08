# Quick Start: Migrate to Gitea + Cloudflare

Fast-track guide to migrate frostlabs-site to git.frostlabs.me + Cloudflare Pages + Cloudflare Images.

## TL;DR Commands

```bash
# 1. Create repo in Gitea first at https://git.frostlabs.me

# 2. Migrate repository
./scripts/migrate-to-gitea.sh YOUR_USERNAME

# 3. Configure Cloudflare account hash in Hugo
# Edit config/_default/params.toml and add:
[cloudflare.images]
  accountHash = "your-hash-here"

# 4. Upload images to Cloudflare
export CF_ACCOUNT_ID="your-account-id"
export CF_API_TOKEN="your-api-token"
./scripts/upload-to-cloudflare.sh static/photos

# 5. Update content files (use cf:image-id syntax)
# See cloudflare-image-mapping.csv for image IDs

# 6. Install Wrangler and deploy
npm install -g wrangler
wrangler login
wrangler pages project create frostlabs-site
./scripts/build-and-deploy.sh

# 7. (Optional) Set up Gitea Actions for auto-deploy
# Add secrets in Gitea: Settings → Secrets → Actions
# - CLOUDFLARE_API_TOKEN
# - CLOUDFLARE_ACCOUNT_ID
# Workflow is already in .gitea/workflows/deploy.yml

# 8. Test and verify
# Visit https://frostlabs-site.pages.dev

# 9. Delete GitHub repo (after 1 week of testing)
```

## Prerequisites Checklist

Before running commands:

- [ ] Gitea instance accessible at https://git.frostlabs.me
- [ ] SSH key added to Gitea (or use HTTPS)
- [ ] Cloudflare account with Images enabled ($5/month)
- [ ] Cloudflare API token created
- [ ] Node.js/npm installed (for Wrangler)

## Step-by-Step

### 1. Create Repository in Gitea

1. Go to https://git.frostlabs.me
2. Click **"+"** → **"New Repository"**
3. Name: `frostlabs-site`
4. Visibility: Your choice
5. **DO NOT** initialize with README
6. Click **"Create Repository"**

### 2. Run Migration Script

```bash
# Replace YOUR_USERNAME with your Gitea username
./scripts/migrate-to-gitea.sh YOUR_USERNAME

# Example:
# ./scripts/migrate-to-gitea.sh doc
```

The script will:
- ✅ Add git.frostlabs.me as remote
- ✅ Push all branches and tags
- ✅ Switch origin from GitHub to Gitea
- ✅ Verify everything worked

### 3. Get Cloudflare Credentials

#### A. Account ID
- Go to https://dash.cloudflare.com/
- Copy Account ID from sidebar

#### B. API Token
- Go to https://dash.cloudflare.com/profile/api-tokens
- Create Token → Use "Edit Cloudflare Images" template
- Copy token immediately

#### C. Account Hash
- Go to Cloudflare Images
- Upload a test image
- Copy URL: `https://imagedelivery.net/YOUR-HASH-HERE/...`
- Extract the hash

### 4. Configure Hugo

Edit `config/_default/params.toml`:

```toml
[cloudflare]
  [cloudflare.images]
    accountHash = "paste-your-hash-here"
```

### 5. Upload Images

```bash
export CF_ACCOUNT_ID="paste-account-id"
export CF_API_TOKEN="paste-api-token"

# Test with one directory first
./scripts/upload-to-cloudflare.sh static/photos/house-project/delivery

# Then upload all
./scripts/upload-to-cloudflare.sh static/photos
```

Check `cloudflare-image-mapping.csv` to see uploaded images.

### 6. Update Content Files

**Before**:
```markdown
<img src="/photos/house-project/delivery/Delivery_001.jpg" alt="..." />
```

**After**:
```markdown
<img src="cf:house-project-delivery-Delivery_001" alt="..." />
```

Use the image IDs from `cloudflare-image-mapping.csv`.

Main file to update: `content/projects/house-project.md`

### 7. Test Locally

```bash
hugo server

# Open http://localhost:1313
# Verify images load
# Check browser console for errors
```

### 8. Commit Changes

```bash
git add .
git commit -m "Migrate to Cloudflare Images CDN"
git push origin main
```

### 9. Set Up Cloudflare Pages

```bash
# Install Wrangler CLI
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Create Pages project
wrangler pages project create frostlabs-site
```

### 10. Deploy

```bash
./scripts/build-and-deploy.sh
```

Your site will be live at: `https://frostlabs-site.pages.dev`

### 11. (Optional) Configure Custom Domain

1. Go to Cloudflare Pages dashboard
2. Your project → Custom domains
3. Add: `frostlabs.me` (or subdomain)
4. DNS configured automatically

### 12. (Optional) Set Up Auto-Deploy

Enable Gitea Actions:

1. In Gitea repo: Settings → Secrets → Actions
2. Add secrets:
   - `CLOUDFLARE_API_TOKEN`
   - `CLOUDFLARE_ACCOUNT_ID`
3. Push to main → auto-deploys!

Workflow already created at `.gitea/workflows/deploy.yml`

### 13. Clean Up GitHub

After 1 week of testing:

1. Go to https://github.com/ghost062591/frostlabs-site/settings
2. Danger Zone → Delete repository
3. Type repo name to confirm

## Troubleshooting

### SSH to Gitea fails

Test connection:
```bash
ssh -T git@git.frostlabs.me
```

If fails, use HTTPS instead (script auto-detects).

### Images not uploading

Check credentials:
```bash
echo $CF_ACCOUNT_ID
echo $CF_API_TOKEN
```

Verify API token has "Cloudflare Images > Edit" permission.

### Build fails

Check Hugo version:
```bash
hugo version
```

Need Hugo Extended. Install from: https://gohugo.io/installation/

### Wrangler not found

Install:
```bash
npm install -g wrangler

# Or with yarn
yarn global add wrangler
```

## Final Architecture

```
Local Repo → Gitea (git.frostlabs.me)
                ↓
           Push to main
                ↓
         Gitea Actions (auto-build)
                ↓
         Cloudflare Pages (global CDN)
                ↓
         Live at: frostlabs-site.pages.dev

Images served from: Cloudflare Images CDN
```

## Cost

- Gitea: $0 (self-hosted)
- Cloudflare Pages: $0 (free tier)
- Cloudflare Images: $5/month
- **Total: $5/month**

## Resources

- Full migration guide: `GITEA-CLOUDFLARE-MIGRATION.md`
- Cloudflare Images guide: `CLOUDFLARE-IMAGES-MIGRATION.md`
- Your Gitea: https://git.frostlabs.me
- Cloudflare Dashboard: https://dash.cloudflare.com/

---

**Need help?** Check the full migration guides or reach out!
