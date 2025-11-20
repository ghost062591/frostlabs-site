# Sveltia CMS Setup with Authentik

This site uses Sveltia CMS for content management, authenticated via your Authentik instance.

## Authentik Configuration

You need to create an OAuth2/OIDC Provider and Application in Authentik:

### 1. Create OAuth2/OIDC Provider

1. Log into Authentik at https://auth.frostlabs.me
2. Go to **Applications** → **Providers**
3. Click **Create** and select **OAuth2/OpenID Provider**
4. Configure:
   - **Name**: `Blog CMS`
   - **Authorization flow**: `default-provider-authorization-implicit-consent`
   - **Client type**: `Confidential`
   - **Redirect URIs**:
     ```
     https://blog.frostlabs.me/api/callback
     ```
   - **Scopes**: `openid`, `profile`, `email`
5. Click **Finish**
6. **Save the Client ID and Client Secret** - you'll need these for Cloudflare

### 2. Create Application

1. Go to **Applications** → **Applications**
2. Click **Create**
3. Configure:
   - **Name**: `Blog CMS`
   - **Slug**: `blog-cms`
   - **Provider**: Select the provider you just created
   - **Launch URL**: `https://blog.frostlabs.me/admin/`
4. Click **Create**

### 3. Create GitHub Personal Access Token

The CMS needs a GitHub token to interact with your repository:

1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Tokens (classic)**
2. Click **Generate new token** → **Generate new token (classic)**
3. Configure:
   - **Note**: `Sveltia CMS`
   - **Expiration**: No expiration (or your preference)
   - **Scopes**: Select `repo` (full control of repositories)
4. Click **Generate token**
5. **Copy the token** - you'll need it in the next step

### 4. Configure Cloudflare Pages Environment Variables

1. Go to your Cloudflare Pages dashboard
2. Select your `frostlabs-site` project
3. Go to **Settings** → **Environment variables**
4. Add these variables (for **Production** environment):
   - `OAUTH_CLIENT_ID`: Your Client ID from Authentik
   - `OAUTH_CLIENT_SECRET`: Your Client Secret from Authentik
   - `AUTHENTIK_URL`: `https://auth.frostlabs.me`
   - `GITHUB_TOKEN`: Your GitHub Personal Access Token from step 3

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

## How Authentication Works

This CMS uses a two-layer authentication approach:

1. **Authentik OAuth** - Controls who can access the CMS (user authentication)
2. **GitHub Token** - Allows the CMS to read/write to your repository (API access)

When you log in:
- You authenticate via Authentik (proves your identity)
- If successful, the system provides the GitHub token to the CMS
- The CMS uses that token to interact with your GitHub repository

This means Authentik controls access, but all authenticated users share the same GitHub token for repository operations.
