# Cloudflare Images Migration Guide

This guide will walk you through migrating your site images from local hosting to Cloudflare Images.

## Overview

**Current state**: 532 MB of images stored in `static/photos/`
**Goal**: Offload images to Cloudflare Images CDN for faster global delivery

## Prerequisites

### 1. Get Your Cloudflare Account Information

You'll need two pieces of information from your Cloudflare dashboard:

#### A. Account ID
1. Go to https://dash.cloudflare.com/
2. Select any site (or go to Account Home)
3. Your Account ID is shown in the right sidebar or in the URL

#### B. API Token
1. Go to https://dash.cloudflare.com/profile/api-tokens
2. Click "Create Token"
3. Use the **"Edit Cloudflare Images"** template (recommended)
   - OR create a custom token with: `Account > Cloudflare Images > Edit` permission
4. Click "Continue to summary" → "Create Token"
5. **IMPORTANT**: Copy the token immediately (you won't see it again!)

### 2. Create Variants in Cloudflare Dashboard

Variants are pre-defined image transformations. Create these two:

1. Go to https://dash.cloudflare.com/ → Cloudflare Images → Variants
2. Create these variants:

| Variant Name | Width | Height | Fit Mode | Purpose |
|--------------|-------|--------|----------|---------|
| `thumbnail` | 300 | - | scale-down | Carousel thumbnails |
| `public` | - | - | scale-down | Full-size lightbox images |

**Note**: The `public` variant is usually created by default.

---

## Migration Steps

### Step 1: Configure Hugo Site

Add your Cloudflare account hash to your Hugo config:

**File**: `config/_default/params.toml`

```toml
# Add this section (create if it doesn't exist)
[cloudflare]
  [cloudflare.images]
    accountHash = "your-account-hash-here"
```

**How to find your account hash**:
- It's in the Cloudflare Images URLs
- Upload a test image in the dashboard, copy its URL
- Extract from: `https://imagedelivery.net/YOUR-ACCOUNT-HASH/image-id/variant`

### Step 2: Upload Images to Cloudflare

Set your credentials as environment variables:

```bash
# In your terminal
export CF_ACCOUNT_ID="your-account-id-here"
export CF_API_TOKEN="your-api-token-here"
```

**Option A: Upload specific directory** (recommended for testing)

```bash
# Upload just delivery photos first (23 images)
./scripts/upload-to-cloudflare.sh static/photos/house-project/delivery
```

**Option B: Upload all photos** (104+ images)

```bash
# Upload everything
./scripts/upload-to-cloudflare.sh static/photos
```

The script will:
- ✅ Upload each image to Cloudflare
- ✅ Generate semantic IDs (e.g., `house-project-delivery-Delivery_001`)
- ✅ Create a mapping file: `cloudflare-image-mapping.csv`
- ✅ Skip already-uploaded images (safe to re-run)
- ✅ Handle rate limiting automatically

### Step 3: Update Your Content Files

You have two options for referencing Cloudflare images:

#### Option A: Use `cf:` prefix (Recommended)

Update your existing lightbox-carousel shortcodes:

**Before**:
```markdown
{{< lightbox-carousel >}}
  <img src="/photos/house-project/delivery/Delivery_001.jpg" alt="Delivery 1" data-caption="Home arrives on site" />
  <img src="/photos/house-project/delivery/Delivery_002.jpg" alt="Delivery 2" data-caption="First section" />
{{< /lightbox-carousel >}}
```

**After**:
```markdown
{{< lightbox-carousel >}}
  <img src="cf:house-project-delivery-Delivery_001" alt="Delivery 1" data-caption="Home arrives on site" />
  <img src="cf:house-project-delivery-Delivery_002" alt="Delivery 2" data-caption="First section" />
{{< /lightbox-carousel >}}
```

The carousel shortcode will automatically:
- Use the `thumbnail` variant (300px) for carousel display
- Use the `public` variant (full-size) for lightbox viewing

#### Option B: Use the `cfimg` shortcode

For standalone images (not in carousel):

```markdown
{{< cfimg id="house-project-delivery-Delivery_001"
    variant="public"
    alt="House delivery"
    caption="Home arrives on site" >}}
```

With custom sizing:

```markdown
{{< cfimg id="house-project-delivery-Delivery_001"
    width="800"
    format="webp"
    quality="90"
    alt="House delivery" >}}
```

### Step 4: Reference the Mapping File

Open `cloudflare-image-mapping.csv` to find your image IDs:

```csv
original_path,cloudflare_id,cloudflare_url,upload_date
static/photos/house-project/delivery/Delivery_001.jpg,house-project-delivery-Delivery_001,https://imagedelivery.net/...,2025-11-08T...
```

Use the `cloudflare_id` column when updating your content.

### Step 5: Test Locally

```bash
# Build and serve locally
hugo server

# Check for any errors in the console
# Verify images load correctly
# Test lightbox functionality
```

Visit http://localhost:1313 and verify:
- ✅ Carousel thumbnails load
- ✅ Lightbox shows full-size images
- ✅ No broken images
- ✅ Console has no errors

### Step 6: Deploy

Once verified locally:

```bash
# Commit changes
git add .
git commit -m "Migrate to Cloudflare Images CDN"
git push

# Your site will rebuild with Cloudflare Images
```

### Step 7: Clean Up (Optional)

After confirming everything works in production for a week:

```bash
# Back up locally first!
tar -czf photos-backup.tar.gz static/photos/

# Remove from git (keep local backup)
git rm -r static/photos/
git commit -m "Remove local images after Cloudflare migration"
git push
```

This saves **532 MB** in your git repository!

---

## Advanced Usage

### Custom Variants

Create additional variants in Cloudflare dashboard for specific use cases:

| Variant | Use Case | Settings |
|---------|----------|----------|
| `hero` | Homepage banners | 1920px width, cover |
| `card` | Post thumbnails | 400x300, cover |
| `avatar` | Profile pictures | 150x150, crop |

### On-Demand Resizing

You can skip variants and resize on-the-fly:

```markdown
{{< cfimg id="image-id" width="500" height="300" fit="cover" format="avif" >}}
```

Supported parameters:
- `width`, `height`: Dimensions in pixels
- `fit`: `scale-down`, `contain`, `cover`, `crop`, `pad`
- `format`: `webp`, `avif`, `jpeg`, `png`
- `quality`: 1-100 (default: 85)

### Migration Script Options

The upload script supports re-running safely:

```bash
# Script automatically skips already-uploaded images
# Safe to run multiple times
./scripts/upload-to-cloudflare.sh static/photos

# Check the mapping file to see what's been uploaded
cat cloudflare-image-mapping.csv
```

---

## Troubleshooting

### Error: "CF_ACCOUNT_ID not set"

```bash
export CF_ACCOUNT_ID="your-account-id"
export CF_API_TOKEN="your-token"
```

### Error: "Cloudflare Images account hash not set"

Add to `config/_default/params.toml`:

```toml
[cloudflare.images]
  accountHash = "your-hash"
```

### Images not loading

1. Check browser console for errors
2. Verify the account hash in `params.toml` is correct
3. Check that image IDs match what's in Cloudflare dashboard
4. Ensure variants `public` and `thumbnail` exist in Cloudflare

### Upload fails with "unauthorized"

- Verify your API token has "Cloudflare Images > Edit" permission
- Check token hasn't expired
- Ensure CF_ACCOUNT_ID matches the account for your token

---

## Cost Estimate

**Cloudflare Images Pricing**: $5/month

- Includes: 100,000 images stored
- Includes: Unlimited transformations/variants
- Includes: Unlimited bandwidth via Cloudflare CDN

**Your usage**: ~104 images (well under limit)

**Savings**:
- Faster page loads globally
- Reduced hosting bandwidth
- Smaller git repository (532 MB saved)
- Automatic WebP/AVIF conversion
- No server-side image processing needed

---

## Example Migration: House Project Page

Here's a real example from `content/projects/house-project.md`:

### Before (Local Images - 23 images, ~85 MB)

```markdown
{{< lightbox-carousel >}}
  <img src="/photos/house-project/delivery/Delivery_001.jpg" alt="Delivery 1" />
  <img src="/photos/house-project/delivery/Delivery_002.jpg" alt="Delivery 2" />
  <!-- ... 21 more images ... -->
{{< /lightbox-carousel >}}
```

### After (Cloudflare Images)

```markdown
{{< lightbox-carousel >}}
  <img src="cf:house-project-delivery-Delivery_001" alt="Delivery 1" />
  <img src="cf:house-project-delivery-Delivery_002" alt="Delivery 2" />
  <!-- ... 21 more images ... -->
{{< /lightbox-carousel >}}
```

**Result**:
- Page loads 3-5x faster globally
- Thumbnails auto-optimized to 300px WebP
- Full images served via CDN on-demand
- No changes to lightbox functionality

---

## Quick Reference

### Upload Script
```bash
export CF_ACCOUNT_ID="..." && export CF_API_TOKEN="..."
./scripts/upload-to-cloudflare.sh static/photos/house-project/delivery
```

### Carousel Syntax
```markdown
{{< lightbox-carousel >}}
  <img src="cf:image-id" alt="Description" data-caption="Caption" />
{{< /lightbox-carousel >}}
```

### Standalone Image
```markdown
{{< cfimg id="image-id" variant="public" alt="Description" >}}
```

### Check Uploaded Images
```bash
cat cloudflare-image-mapping.csv
```

---

## Need Help?

- **Cloudflare Images Docs**: https://developers.cloudflare.com/images/
- **Hugo Image Processing**: https://gohugo.io/content-management/image-processing/
- **Your mapping file**: `cloudflare-image-mapping.csv`

Happy migrating! 🚀
