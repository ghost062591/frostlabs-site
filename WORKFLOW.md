# FrostLabs Blog Publishing Workflow

Quick reference for editing content in Obsidian and publishing to your live site.

## 🚀 Quick Publish

After editing content in Obsidian, publish to your live site:

```bash
./publish
```

Or with a custom commit message:

```bash
./publish "Added new homelab article"
```

That's it! This single command will:
1. ✅ Commit your changes to git
2. ✅ Push to Gitea (git.frostlabs.me)
3. ✅ Build the Hugo site
4. ✅ Deploy to Cloudflare Pages
5. ✅ Make your changes live at blog.frostlabs.me

## 📝 Content Organization

Your Obsidian vault structure:
```
frostlabs-site/
├── content/
│   ├── blog/          # Blog posts
│   ├── projects/      # Project documentation
│   └── homelab/       # Homelab articles
├── static/
│   └── img/           # Images (not photos)
└── .obsidian/         # Obsidian configuration
```

## ✍️ Writing Workflow

### Option 1: Simple Edit & Publish
```bash
# 1. Edit your markdown files in Obsidian
# 2. Run publish
./publish "Updated blog post"
```

### Option 2: Review Before Publishing
```bash
# 1. Edit in Obsidian
# 2. Check what changed
git status

# 3. Preview locally (optional)
./serve
# Visit: http://10.0.4.11:1313

# 4. Publish
./publish "My updates"
```

## 📸 Working with Images

### Using Cloudflare Images (for photo galleries)

1. Upload images to Cloudflare:
```bash
# Upload a batch of images
# (Manual upload via Cloudflare dashboard recommended)
```

2. Reference in markdown:
```markdown
{{< lightbox-carousel >}}
  <img src="cf:image-id-here" alt="Description" data-caption="Caption" />
{{< /lightbox-carousel >}}
```

### Using Local Images (for diagrams, icons, etc.)

Place images in `static/img/` and reference them:
```markdown
![Description](/img/my-image.png)
```

## 🎨 Front Matter Template

Copy this for new blog posts:

```yaml
---
title: "Your Post Title"
date: 2025-11-08
draft: false
description: "Brief description for SEO"
tags: ["tag1", "tag2"]
categories: ["category"]
author: "Johnathan Allison"
---

Your content here...
```

## 🔧 Troubleshooting

### Build fails
```bash
# Check Hugo syntax
hugo --buildDrafts

# View errors
hugo --verbose
```

### Deploy fails
```bash
# Check Cloudflare credentials
echo $CLOUDFLARE_ACCOUNT_ID
# Should show: 478c5f86904a5dd27b66b051cde8d51a

# Manually deploy
./scripts/build-and-deploy.sh
```

### Git push fails
```bash
# Check git status
git status

# Check remote
git remote -v
# Should show: git.frostlabs.me
```

## 📁 Useful Commands

```bash
# Preview site locally (headless server)
./serve
# Visit: http://10.0.4.11:1313

# Check git changes
git status

# View recent commits
git log --oneline -5

# Publish with message
./publish "Your message here"

# Just build (don't deploy)
hugo --gc --minify
```

## 🎯 Best Practices

1. **Write in Obsidian** - Use all Obsidian features (links, tags, templates)
2. **Preview before publishing** - Run `hugo server -D` to see changes locally
3. **Use descriptive commit messages** - Makes it easier to track changes
4. **Test lightbox galleries** - After deploying, check that images load
5. **Keep images optimized** - Cloudflare Images handles this automatically

## 🌐 Your Sites

- **Live Site**: https://blog.frostlabs.me
- **Gitea Repo**: https://git.frostlabs.me/jpallison0625/frostlabs-site
- **Cloudflare Dashboard**: https://dash.cloudflare.com/

---

*Last Updated: 2025-11-08*
