# Sveltia CMS Setup with GitHub

This site uses Sveltia CMS for content management, authenticated via GitHub.

## Setup Instructions

The CMS uses GitHub's built-in OAuth for authentication. Anyone who can access your GitHub repository can use the CMS.

## Accessing the CMS

Once configured, you can access the CMS at:

**https://blog.frostlabs.me/admin/**

1. Click the login button
2. You'll be redirected to Authentik
3. Log in with your Authentik credentials
4. You'll be redirected back to the CMS

## Using the CMS

The CMS provides an interface to:

- Create and edit blog posts
- Manage house project updates
- Add homelab documentation
- Create new projects
- Manage Frostlabs content

All changes are committed directly to your GitHub repository, which triggers a Cloudflare Pages rebuild automatically.

## Authentication

The CMS uses GitHub OAuth for authentication. When you log in:
1. You'll be redirected to GitHub
2. Authorize the application (first time only)
3. You'll be redirected back to the CMS with access

Only users with write access to the `ghost062591/frostlabs-site` repository can use the CMS.
