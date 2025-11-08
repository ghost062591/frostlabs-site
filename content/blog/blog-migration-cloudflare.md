---
title: "Migrating to Cloudflare: From GitHub Pages to Modern Edge Infrastructure"
date: 2025-11-08
draft: false
description: "How I migrated my Hugo blog from GitHub Pages to Cloudflare Pages, moved 104 images to Cloudflare Images CDN, and solved a tricky CSP issue with serverless functions."
tags: ["cloudflare", "hugo", "migration", "cdn", "devops"]
categories: ["Infrastructure"]
author: "Johnathan Allison"
---

## The Challenge

My blog was running on GitHub Pages with a Hugo static site generator and Obsidian as my writing environment. While this setup worked, I wanted:

1. **Better performance** - Edge delivery with Cloudflare's global network
2. **Self-hosted git** - Move from GitHub to my own Gitea instance
3. **Optimized images** - Use Cloudflare Images CDN instead of storing 533 MB of photos in my repo
4. **Simpler workflow** - One command to publish from Obsidian to live site

This is the story of that migration, including a particularly interesting CSP issue that required creative problem-solving.

## Part 1: Repository Migration to Gitea

First step: moving from GitHub to my self-hosted Gitea instance.

### The Process

```bash
# Add new Gitea remote
git remote rename origin github
git remote add origin ssh://git@git.frostlabs.me:2222/jpallison0625/frostlabs-site.git

# Push everything
git push -u origin --all
git push -u origin --tags
```

**Result:** Repository now hosted at `git.frostlabs.me` with full control over my infrastructure.

## Part 2: Cloudflare Pages Deployment

Setting up Cloudflare Pages was straightforward - until I hit authentication issues.

### Initial Setup

```bash
# Install Wrangler CLI
npm install -g wrangler

# Upgrade to Node 20 (Wrangler requirement)
nvm install 20
nvm use 20

# Create Pages project
wrangler pages project create frostlabs-site
```

### Authentication Gotcha

The first API token I created didn't have the right permissions. Cloudflare's error messages pointed me in the right direction:

**Required Permissions:**
- Account Settings: Read
- Cloudflare Pages: Edit

### Deployment Script

I created a simple deployment workflow:

```bash
#!/bin/bash
hugo --gc --minify
wrangler pages deploy public \
    --project-name frostlabs-site \
    --branch master
```

**Result:** Site live at `frostlabs-site.pages.dev` and custom domain `blog.frostlabs.me`

## Part 3: Image Migration to Cloudflare Images

This was the most complex part - migrating 104 images (533 MB) from local storage to Cloudflare Images CDN.

### The Upload Process

Created a bash script to batch upload images:

```bash
#!/bin/bash
for img in static/photos/**/*.jpg; do
    # Generate consistent IDs from file paths
    ID=$(echo "$img" | sed 's/static\/photos\///' | sed 's/\//-/g' | sed 's/\.jpg$//')

    # Upload to Cloudflare Images
    curl -X POST "https://api.cloudflare.com/client/v4/accounts/$ACCOUNT_ID/images/v1" \
        -H "Authorization: Bearer $API_TOKEN" \
        -F "file=@$img" \
        -F "id=$ID"
done
```

**Challenge:** The script's error parsing was broken (grep pattern didn't match multi-line JSON), so it reported all uploads as "Failed" even though they succeeded. Verified actual success through the Cloudflare dashboard.

### Creating Image Variants

Cloudflare Images needs variants defined for different use cases:

```bash
# Thumbnail variant (300x300px) for carousel display
wrangler images variants create thumbnail --width 300 --height 300 --fit scale-down

# Public variant (full-size) for lightbox
wrangler images variants create public --fit scale-down --metadata none
```

**Important:** The `public` variant needed `neverRequireSignedURLs: true` to avoid 403 errors.

### Hugo Shortcode Integration

Updated the lightbox shortcode to support Cloudflare Images with `cf:` prefix:

```markdown
{{</* lightbox-carousel */>}}
  <img src="cf:house-project-delivery-Delivery_001" alt="Delivery day" />
  <img src="cf:house-project-site-prep-excavation_001" alt="Site prep" />
{{</* /lightbox-carousel */>}}
```

The shortcode transforms these into proper Cloudflare Images URLs:
- Thumbnail: `https://imagedelivery.net/{hash}/{id}/thumbnail`
- Full-size: `/api/image/{id}/public` (proxied through Pages Function)

## Part 4: The CSP Challenge

Everything was working - thumbnails loaded, lightbox opened - but full-size images wouldn't display. The browser console revealed the culprit:

```
Refused to apply inline style because it violates the following
Content Security Policy directive: "default-src 'none'"
```

### The Problem

Cloudflare Images serves images with extremely restrictive CSP headers:

```
content-security-policy: default-src 'none'; navigate-to 'none';
  form-action 'none'; img-src data:;
```

This CSP blocks images from displaying in GLightbox modals because:
1. GLightbox tries to load the image from the `href` URL
2. Cloudflare Images' CSP only allows `data:` URIs for images
3. The lightbox modal couldn't display the actual image URL

### The Solution: Cloudflare Pages Functions

Instead of serving images directly from Cloudflare Images, I created a serverless proxy using Pages Functions:

```javascript
// functions/api/image/[id]/[variant].js
export async function onRequest(context) {
  const { id: imageId, variant } = context.params;
  const accountHash = 'sFNd_vzb3SAtjIIqbbqbmQ';

  const imageUrl = `https://imagedelivery.net/${accountHash}/${imageId}/${variant}`;

  const imageResponse = await fetch(imageUrl, {
    cf: {
      cacheTtl: 86400,
      cacheEverything: true,
    }
  });

  const imageBody = await imageResponse.arrayBuffer();
  const contentType = imageResponse.headers.get('Content-Type');

  return new Response(imageBody, {
    headers: {
      'Content-Type': contentType,
      'Cache-Control': 'public, max-age=86400, immutable',
      'Access-Control-Allow-Origin': '*',
      // No CSP header! That's the key!
    }
  });
}
```

**Why This Works:**
- Pages Functions run on Cloudflare's edge (same infrastructure as Images)
- The function fetches from Cloudflare Images (server-to-server, no CSP issues)
- Returns the image with **modified headers** (no restrictive CSP)
- Maintains caching at both edge and browser level
- Zero latency penalty after first load

### The Final Fix

Updated the lightbox shortcode to use the Pages Function proxy:

```go-html-template
{{</* /*/>}} For Cloudflare Images {{</* */>}}
{{</* */>}} $cfImageID := strings.TrimPrefix "cf:" $srcValue {{</* */>}}

{{</* /*/>}} Thumbnail: direct from Cloudflare Images (works fine) {{</* */>}}
{{</* */>}} $srcValueThumb = printf "https://imagedelivery.net/%s/%s/thumbnail"
    $accountHash $cfImageID {{</* */>}}

{{</* /*/>}} Full-size: proxied through Pages Function (bypasses CSP) {{</* */>}}
{{</* */>}} $srcValueFull = printf "/api/image/%s/public" $cfImageID {{</* */>}}
```

**Critical Addition:** Added `data-type="image"` to tell GLightbox to actually fetch the `href` URL:

```go-html-template
{{</* */>}} $lightboxAttrs := printf `href="%s" class="glightbox carousel-item"
    data-type="image" data-gallery="%s"` $srcValueFull $id {{</* */>}}
```

Without `data-type="image"`, GLightbox wasn't making network requests to the image URLs at all!

## Part 5: Streamlined Publishing Workflow

The final piece: making it dead simple to publish from Obsidian.

### The One-Command Publish Script

```bash
#!/bin/bash
# ./publish - One command to go from edit to live

# 1. Commit changes
git add .
git commit -m "${1:-Update content from Obsidian}"

# 2. Push to Gitea
git push origin master

# 3. Build Hugo site
hugo --gc --minify

# 4. Deploy to Cloudflare Pages
wrangler pages deploy public \
    --project-name frostlabs-site \
    --branch master
```

**Usage:**

```bash
# Quick publish
./publish

# With custom message
./publish "Added migration blog post"
```

### Local Preview for Headless Server

```bash
#!/bin/bash
# ./serve - Preview on headless server

hugo server -D --bind 10.0.4.11 --baseURL http://10.0.4.11:1313
```

Access from any machine on the network at `http://10.0.4.11:1313`

## Results & Performance

### Before (GitHub Pages)
- **Hosting:** GitHub's servers (US-focused)
- **Images:** 533 MB in git repo
- **CDN:** GitHub's CDN (limited)
- **Deploy:** Manual git push, wait for GitHub Actions
- **TTFB:** ~200-400ms (varies by location)

### After (Cloudflare)
- **Hosting:** Cloudflare's global edge network (300+ locations)
- **Images:** Cloudflare Images CDN with automatic optimization
- **CDN:** Cloudflare's enterprise CDN
- **Deploy:** One command (`./publish`)
- **TTFB:** ~50-100ms globally
- **Repo size:** 533 MB smaller (no images in git)

### Image Optimization Benefits

Cloudflare Images automatically:
- Serves WebP/AVIF to modern browsers
- Generates responsive variants on-the-fly
- Optimizes compression per-image
- Caches at edge globally
- Handles HTTPS/HTTP2/HTTP3 automatically

## Key Lessons Learned

### 1. CSP Headers Can Break Legitimate Use Cases

Content Security Policy is important for security, but overly restrictive CSP can break expected functionality. The solution isn't to disable CSP - it's to proxy through your own infrastructure where you control the headers.

### 2. Edge Functions Are Incredibly Powerful

Cloudflare Pages Functions gave me the ability to modify response headers without managing servers. The function runs at the edge (same location as the images), so there's no latency penalty.

### 3. Debugging CSP Issues

When images load in network tab but don't display:
- Check browser console for CSP violations
- Inspect the response headers
- Test direct image URLs vs proxied URLs
- Use `curl -I` to see headers without browser caching

### 4. GLightbox Configuration Matters

The `data-type="image"` attribute was crucial. Without it, GLightbox wasn't even attempting to fetch the images from the `href` URLs. Always check library documentation for required attributes.

### 5. Automation Saves Time (Eventually)

Setting up the publish workflow took time upfront, but now publishing is literally one command. The cognitive load reduction is worth the initial investment.

## Technical Architecture

Here's how it all fits together:

```
┌─────────────┐
│  Obsidian   │  (Write content)
└──────┬──────┘
       │
       │  ./publish
       ▼
┌─────────────┐
│   Gitea     │  (Version control)
└──────┬──────┘
       │
       │  Hugo build
       ▼
┌─────────────┐
│ Cloudflare  │  (Static hosting)
│   Pages     │
└──────┬──────┘
       │
       │  ┌──────────────────────────────┐
       │  │  Pages Function              │
       │  │  /api/image/[id]/[variant]   │
       │  └─────────┬────────────────────┘
       │            │
       │            ▼
       │     ┌─────────────┐
       │     │ Cloudflare  │  (Image CDN)
       │     │   Images    │
       │     └─────────────┘
       │
       ▼
┌─────────────┐
│   Visitor   │  (blog.frostlabs.me)
└─────────────┘
```

## Cost Analysis

### Before (GitHub Pages)
- **Hosting:** Free
- **Bandwidth:** Free (with soft limits)
- **Total:** $0/month

### After (Cloudflare)
- **Pages:** Free tier (500 builds/month, unlimited bandwidth)
- **Images:** $5/month (100k images, 100k delivery/month)
- **DNS:** Free (Cloudflare DNS)
- **Total:** ~$5/month

**Worth it?** Absolutely. For $5/month I get:
- Global edge delivery
- Automatic image optimization
- Unlimited bandwidth
- Serverless functions
- Enterprise CDN
- Better performance worldwide

## Conclusion

This migration took an afternoon but resulted in:
- ✅ Faster global performance
- ✅ Optimized image delivery
- ✅ Self-hosted git repository
- ✅ One-command publishing workflow
- ✅ Better understanding of CSP and edge computing

The CSP challenge was frustrating at first, but solving it taught me a lot about:
- How browsers enforce security policies
- The power of edge functions for header manipulation
- The importance of proper library configuration
- Creative problem-solving in web development

If you're running a static site on GitHub Pages and looking for better performance, Cloudflare Pages is worth considering. The migration process is straightforward, and the Pages Functions feature gives you serverless capabilities when you need them.

## Resources

- [Cloudflare Pages Documentation](https://developers.cloudflare.com/pages/)
- [Cloudflare Images Documentation](https://developers.cloudflare.com/images/)
- [Hugo Static Site Generator](https://gohugo.io/)
- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/)
- [Content Security Policy (CSP)](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)

---

*Have questions about the migration? Find me on GitHub or reach out via the contact page.*
