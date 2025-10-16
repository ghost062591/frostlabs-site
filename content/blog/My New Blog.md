---
title: '"From Self-Hosted Complexity to GitHub Pages Simplicity: Building a Hugo Site with Blowfish"'
date: 2025-10-16T14:50:55Z
draft: false
tags:
  - hugo
  - blowfish
  - github-pages
  - docker
  - homelab
description: Detailed Post Explaining my process so far launching a blog site.
categories:
  - web-development
feature: img/site/Gemini_Generated_Image_7ijmfo7ijmfo7ijm.png
---

---

Building a personal blog should be straightforward, but like many homelab enthusiasts, I initially overcomplicated things. What started as a simple Hugo site deployment turned into a learning experience about when to embrace simplicity over self-hosted complexity.

## The Original Plan: Docker Swarm All The Things

My initial vision was ambitious: deploy a Hugo site with the Blowfish theme to my existing Docker Swarm homelab infrastructure, complete with:

- Self-hosted deployment on `blog.frostlabs.me`
- Nginx serving static files from shared storage
- Decap CMS for content management
- GitHub Actions for automated builds
- Traefik handling SSL termination

The plan made sense on paper. I already had the infrastructure, so why not use it?

## Setting Up Hugo and Blowfish

The initial Hugo setup went smoothly:


```bash
hugo new site frostlabs-site
cd frostlabs-site
git init
git submodule add -b main https://github.com/nunocoracao/blowfish.git themes/blowfish
```

Blowfish's configuration system is well-designed. Instead of a single monolithic config file, it uses multiple TOML files in `config/_default/`:

- `hugo.toml` - Basic site settings
- `params.toml` - Theme-specific parameters
- `menus.en.toml` - Navigation structure
- `languages.en.toml` - Language and author settings
- `markup.toml` - Markdown rendering configuration

I structured the site around four main content areas: Blog, Projects, Homelab documentation, and a Photo Gallery. This required creating corresponding content directories and configuring the navigation menus.

## The Self-Hosting Rabbit Hole

The complexity started creeping in when I attempted to deploy this to my Docker Swarm cluster. What seemed like a simple nginx container deployment quickly became a debugging session involving:

### Docker Stack Configuration


```yaml
version: '3.8'
services:
  frostlabs-site:
    image: nginx:alpine
    volumes:
      - path/to/webfiles:/usr/share/nginx/html:ro
    networks:
      - homelab
    deploy:
      labels:
        - traefik.enable=true
        - traefik.docker.network=homelab
        - traefik.http.routers.frostlabs-sites.rule=Host(`blog.frostlabs.me`)
        - traefik.http.routers.frostlabs-site.entrypoints=websecure
        - traefik.http.routers.frostlabs-site.tls=true
        - traefik.http.routers.frostlabs-site.tls.certresolver=
        - traefik.http.services.frostlabs-site.loadbalancer.server.port=80
```

### File Permission Headaches

Getting the built Hugo files from my local machine to the shared storage with correct permissions became unnecessarily complex:


```bash
hugo --minify
sudo cp -r public/* path/to/webfiles
sudo chown -R 33:33 path/to/webfiles
```

### Decap CMS Authentication Issues

The biggest pain point was getting Decap CMS to work with GitHub OAuth in a self-hosted environment. Despite multiple attempts with different configurations:


```yaml
backend:
  name: github
  repo: ghost062591/frostlabs-site
  branch: main
  auth_type: implicit
  app_id: (client-ID)
```

The authentication consistently failed with "Not Found" errors, likely due to CORS issues or GitHub OAuth's restrictions with non-standard hosting environments.

## The Pivot: Embracing GitHub Pages

After spending hours troubleshooting OAuth flows, CORS headers, and file permissions, I made a decision that should have been obvious from the start: use GitHub Pages.

The migration was surprisingly simple:

### GitHub Actions Workflow


```yaml
name: Deploy Hugo site to Pages

on:
  push:
    branches: ["main"]

permissions:
  contents: read
  pages: write
  id-token: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          submodules: recursive

      - name: Setup Hugo
        uses: peaceiris/actions-hugo@v3
        with:
          hugo-version: 'latest'
          extended: true

      - name: Build with Hugo
        run: hugo --minify --baseURL "${{ steps.pages.outputs.base_url }}/"

      - name: Upload artifact
        uses: actions/upload-pages-artifact@v3
        with:
          path: ./public

  deploy:
    environment:
      name: github-pages
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: Deploy to GitHub Pages
        uses: actions/deploy-pages@v4
```

### Custom Domain Configuration

Setting up the custom domain was straightforward:

1. Add CNAME record in Cloudflare: `blog → (user).github.io`
2. Create `static/CNAME` file with `blog.frostlabs.me`
3. Update `baseURL` in `hugo.toml`
4. Enable custom domain in GitHub Pages settings

## Content Creation Strategy: Obsidian Integration

Rather than fighting with web-based CMS systems, I opted for a local-first approach using Obsidian. This workflow provides:

### Template Structure

I created templates for each content type in the `Templates/` folder:

**Blog Post Template:**

```markdown
---
title: "<% tp.file.title %>"
date: <% tp.date.now("YYYY-MM-DDTHH:mm:ss") %>Z
draft: false
tags: 
description: ""
---

# <% tp.file.title %>

## Overview
Brief introduction to the topic.

## Implementation
Step-by-step details or code examples.

## Conclusion
What you learned or achieved.
```

### Useful Obsidian Plugins

- **Obsidian Git** - Auto-sync with GitHub
- **Templater** - Dynamic templates with variables
- **Advanced Tables** - Rich table editing
- **Admonition** - Callout boxes for better formatting

This approach gives me the power of a full markdown editor while maintaining the automated deployment pipeline.

## Theme Customization Lessons

One key discovery was understanding Blowfish's file structure conventions. The background image initially wouldn't display despite correct configuration because I was using the wrong path structure.

Blowfish expects assets in `assets/img/` rather than `static/images/`. Once I moved the background image to the correct location:

```toml
[homepage]
layout = "background"
homepageImage = "img/IMAGE.jpg"
```

The Artist template background display worked perfectly.

## Deployment Debugging

A few configuration issues emerged during deployment:

### Hugo Version Compatibility

GitHub Actions initially failed due to deprecated configuration:


```toml
# Old (deprecated in Hugo v0.151.0)
paginate = 20

# New
[pagination]
pagerSize = 20
```

### GitHub Actions Version Updates

The workflow needed updates for deprecated action versions:


```yaml
# Updated to latest stable versions
- uses: actions/checkout@v4
- uses: peaceiris/actions-hugo@v3
- uses: actions/upload-pages-artifact@v3
- uses: actions/deploy-pages@v4
```

## The Final Result

The completed site at [blog.frostlabs.me](https://blog.frostlabs.me) includes:

- Clean, professional Blowfish theme with neon color scheme
- Custom background image
- Four main content sections (Blog, Projects, Homelab, Gallery)
- Responsive design optimized for both desktop and mobile
- Fast loading via GitHub Pages CDN
- Automated deployment from git pushes

## Lessons Learned

### When to Self-Host vs. Use Managed Services

This project reinforced an important principle: complexity should serve a purpose. My Docker Swarm infrastructure makes sense for applications that require:

- Custom networking configurations
- Persistent data storage
- Integration with other self-hosted services
- Specific security requirements

For a static blog, GitHub Pages provides:

- Zero maintenance overhead
- Global CDN distribution
- Automatic SSL certificates
- Reliable uptime
- No server costs

### The Value of Constraints

GitHub Pages' limitations (static files only, no server-side processing) actually improved the final product by forcing simplicity. The result is a faster, more reliable site than my initial self-hosted approach would have provided.

### Local-First Content Creation

The Obsidian + Git workflow proves that you don't need a web-based CMS for efficient content creation. Local editing provides:

- Offline capability
- Rich markdown editing features
- Template automation
- Full version control integration

## Moving Forward

The site foundation is now solid and maintainable. Future enhancements might include:

- Automated image optimization
- Advanced search functionality
- Comment system integration
- Analytics implementation

But these can be added incrementally without disrupting the core workflow.

Sometimes the best technical solution is the simplest one that meets your actual requirements, not the most technically impressive one you can build.