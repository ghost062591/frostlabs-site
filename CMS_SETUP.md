# Sveltia CMS Setup with GitHub

This site uses Sveltia CMS for content management, authenticated via GitHub OAuth.

## Setup Instructions

### 1. Create a GitHub OAuth App

1. Go to GitHub → **Settings** → **Developer settings** → **OAuth Apps**
2. Click **New OAuth App**
3. Configure:
   - **Application name**: `FrostLabs Blog CMS`
   - **Homepage URL**: `https://blog.frostlabs.me`
   - **Authorization callback URL**: `https://blog.frostlabs.me/api/callback`
4. Click **Register application**
5. **Copy the Client ID**
6. Click **Generate a new client secret** and **copy the Client Secret**

### 2. Configure Cloudflare Pages Environment Variables

1. Go to your Cloudflare Pages dashboard
2. Select your `frostlabs-site` project
3. Go to **Settings** → **Environment variables**
4. Add these variables (for **Production** environment):
   - `GITHUB_CLIENT_ID`: Your OAuth App Client ID
   - `GITHUB_CLIENT_SECRET`: Your OAuth App Client Secret
5. After adding variables, redeploy your site

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
