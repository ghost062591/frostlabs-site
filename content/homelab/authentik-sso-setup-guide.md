---
title: Complete Guide to Setting Up SSO with Authentik
date: 2025-10-30T10:00:00Z
tags:
  - authentik
  - sso
  - docker
  - homelab
  - security
description: A comprehensive step-by-step guide to configuring Authentik for Single Sign-On (SSO) in a Docker Swarm homelab environment, from initial setup to integrating applications.
---

## Overview

Authentik is a powerful open-source Identity Provider (IdP) that provides Single Sign-On (SSO), authentication, and authorization for your homelab services. This guide walks through the complete setup process, from initial deployment to integrating your first application.

## What You'll Learn

- Initial Authentik configuration and admin setup
- Understanding Authentik's architecture (Providers, Applications, Flows)
- Configuring OAuth2/OIDC providers for modern applications
- Setting up LDAP for legacy applications
- Implementing the Forward Auth proxy for apps without native SSO
- User and group management
- Best practices for security and maintenance

## Prerequisites

Before starting, ensure you have:

- Docker Swarm cluster running (or standalone Docker)
- Authentik deployed and accessible via HTTPS
- PostgreSQL database configured for Authentik
- Redis instance for session management
- Reverse proxy (Traefik recommended) with valid SSL certificates

## Architecture Overview

Authentik consists of three main components:

```
authentik_server   → Main application server (handles auth flows)
authentik_worker   → Background tasks (email, LDAP sync, scheduled jobs)
authentik_redis    → Session storage and caching
```

**Key Concepts:**

- **Providers** - Authentication protocols (OAuth2, SAML, LDAP, Proxy)
- **Applications** - Services you want to protect with SSO
- **Flows** - Authentication workflows (login, enrollment, recovery)
- **Policies** - Access control rules
- **Bindings** - Links between flows and policies

## Initial Setup

### Step 1: Access Authentik Admin Interface

Navigate to your Authentik instance:

```
https://auth.yourdomain.com/if/flow/initial-setup/
```

**Important:** This URL is only available on first launch. If you've already accessed Authentik, use the admin login instead:

```
https://auth.yourdomain.com/if/flow/authentication/
```

### Step 2: Create Admin Account

On the initial setup page:

1. **Username:** Choose your admin username (e.g., `admin`)
2. **Email:** Your admin email address
3. **Password:** Strong password (minimum 12 characters recommended)
4. Click **Create Account**

You'll be automatically logged in as the administrator.

### Step 3: Explore the Admin Interface

The Authentik admin interface consists of several key sections:

**Main Navigation:**

- **Dashboard** - System overview and recent events
- **Applications** - Manage your SSO-enabled applications
- **Events** - Audit logs and monitoring
- **Flows & Stages** - Authentication workflow configuration
- **Directory** - Users, groups, and organizational structure
- **System** - Settings, certificates, and system tasks

## Understanding Authentik's Authentication Model

### Providers

Providers define **how** applications authenticate:

| Provider Type | Use Case | Examples |
|---------------|----------|----------|
| **OAuth2/OIDC** | Modern web apps | Grafana, Portainer, Gitea |
| **SAML** | Enterprise applications | AWS, Google Workspace |
| **LDAP** | Legacy applications | OpenVPN, FreeRADUS |
| **Proxy** | Apps without SSO support | Legacy web apps |

### Applications

Applications are the services you want users to access. Each application:

- Has a display name and icon
- Links to a provider (authentication method)
- Has an associated policy for access control
- Appears in the user's application portal

### Flows

Flows define authentication workflows:

- **Authentication Flow** - How users log in
- **Authorization Flow** - OAuth2 consent screens
- **Enrollment Flow** - User registration process
- **Recovery Flow** - Password reset process
- **Invalidation Flow** - Logout process

## Setting Up Your First SSO Application

Let's configure OAuth2/OIDC SSO for a common application. I'll use **Portainer** as an example, but the process is similar for most modern applications.

### Step 1: Create an OAuth2 Provider

1. Navigate to **Applications → Providers**
2. Click **Create**
3. Select **OAuth2/OpenID Provider**

**Provider Configuration:**

```
Name: Portainer OAuth
Authorization Flow: default-provider-authorization-implicit-consent
Client Type: Confidential
Client ID: portainer (will be auto-generated, you can customize)
Client Secret: (automatically generated - SAVE THIS!)
Redirect URIs: https://portainer.yourdomain.com/
Signing Key: authentik Self-signed Certificate
```

**Advanced Settings (optional but recommended):**

```
Scopes: email, openid, profile
Subject Mode: Based on the User's hashed ID
Include claims in id_token: ✓ (checked)
```

4. Click **Finish**

**Important:** Save the **Client ID** and **Client Secret** - you'll need these for the application configuration.

### Step 2: Create the Application

1. Navigate to **Applications → Applications**
2. Click **Create**

**Application Configuration:**

```
Name: Portainer
Slug: portainer (URL-friendly identifier)
Group: (optional - for organizing apps in the portal)
Provider: Portainer OAuth (select the provider you just created)
Policy Engine Mode: any (allows any matching policy to grant access)
```

**UI Settings (optional):**

```
Launch URL: https://portainer.yourdomain.com/
Icon: (upload a Portainer icon or leave blank)
```

3. Click **Create**

### Step 3: Configure the Application Side

Now configure Portainer to use Authentik for authentication.

**In Portainer Settings → Authentication:**

```
Authentication Method: OAuth
Client ID: portainer
Client Secret: (paste the secret from Step 1)
Authorization URL: https://auth.yourdomain.com/application/o/authorize/
Access Token URL: https://auth.yourdomain.com/application/o/token/
Resource URL: https://auth.yourdomain.com/application/o/userinfo/
Redirect URL: https://portainer.yourdomain.com/
Logout URL: https://auth.yourdomain.com/application/o/portainer/end-session/
User Identifier: preferred_username
Scopes: openid profile email
```

4. Save the configuration
5. Log out of Portainer
6. You should now see "Login with OAuth" button

### Step 4: Test the Integration

1. Click **Login with OAuth** in Portainer
2. You'll be redirected to Authentik
3. Log in with your Authentik credentials
4. Grant consent (if prompted)
5. You'll be redirected back to Portainer, now logged in

## Common OAuth2 Configurations

### Grafana

**Provider Settings:**
```
Name: Grafana OAuth
Redirect URIs: https://grafana.yourdomain.com/login/generic_oauth
```

**Grafana Configuration (grafana.ini):**
```ini
[auth.generic_oauth]
enabled = true
name = Authentik
client_id = grafana
client_secret = YOUR_SECRET_HERE
scopes = openid profile email
auth_url = https://auth.yourdomain.com/application/o/authorize/
token_url = https://auth.yourdomain.com/application/o/token/
api_url = https://auth.yourdomain.com/application/o/userinfo/
role_attribute_path = contains(groups[*], 'Grafana Admins') && 'Admin' || contains(groups[*], 'Grafana Editors') && 'Editor' || 'Viewer'
```

### Gitea

**Provider Settings:**
```
Name: Gitea OAuth
Redirect URIs: https://gitea.yourdomain.com/user/oauth2/authentik/callback
```

**Gitea Configuration (app.ini):**
```ini
[oauth2_client]
REGISTER_EMAIL_CONFIRM = false
OPENID_CONNECT_SCOPES = openid profile email
ENABLE_AUTO_REGISTRATION = true
USERNAME = preferred_username
```

Then add the OAuth2 source via Gitea's admin panel:
```
Authentication Source: OAuth2
Authentication Name: Authentik
OAuth2 Provider: OpenID Connect
Client ID: gitea
Client Secret: YOUR_SECRET_HERE
OpenID Connect Auto Discovery URL: https://auth.yourdomain.com/application/o/gitea/.well-known/openid-configuration
```

### Paperless-ngx

**Provider Settings:**
```
Name: Paperless OAuth
Redirect URIs: https://paperless.yourdomain.com/accounts/oidc/authentik/callback/
```

**Paperless Environment Variables:**
```bash
PAPERLESS_APPS=allauth.socialaccount.providers.openid_connect
PAPERLESS_SOCIALACCOUNT_PROVIDERS={
  "openid_connect": {
    "APPS": [
      {
        "provider_id": "authentik",
        "name": "Authentik",
        "client_id": "paperless",
        "secret": "YOUR_SECRET_HERE",
        "settings": {
          "server_url": "https://auth.yourdomain.com/application/o/paperless/.well-known/openid-configuration"
        }
      }
    ]
  }
}
```

## Setting Up Forward Authentication Proxy

For applications that don't support OAuth2/OIDC natively, Authentik can act as a forward authentication proxy.

### Step 1: Create Proxy Provider

1. Navigate to **Applications → Providers**
2. Click **Create**
3. Select **Proxy Provider**

**Configuration:**

```
Name: Legacy App Proxy
Authorization Flow: default-provider-authorization-implicit-consent
Type: Forward auth (single application)
External Host: https://legacy.yourdomain.com
```

4. Click **Finish**

### Step 2: Create the Application

```
Name: Legacy Application
Slug: legacy-app
Provider: Legacy App Proxy
```

### Step 3: Configure Traefik for Forward Auth

Add these labels to your application's Docker service:

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.legacy.rule=Host(`legacy.yourdomain.com`)"
  - "traefik.http.routers.legacy.entrypoints=websecure"
  - "traefik.http.routers.legacy.tls.certresolver=cloudflare"

  # Forward authentication to Authentik
  - "traefik.http.routers.legacy.middlewares=authentik@docker"
  - "traefik.http.middlewares.authentik.forwardauth.address=http://authentik_server:9000/outpost.goauthentik.io/auth/traefik"
  - "traefik.http.middlewares.authentik.forwardauth.trustForwardHeader=true"
  - "traefik.http.middlewares.authentik.forwardauth.authResponseHeaders=X-authentik-username,X-authentik-groups,X-authentik-email,X-authentik-name,X-authentik-uid"
```

Now when users access `legacy.yourdomain.com`, they'll be prompted to authenticate via Authentik before reaching the application.

## User Management

### Creating Users

1. Navigate to **Directory → Users**
2. Click **Create**

**User Configuration:**

```
Username: john.doe
Name: John Doe
Email: john.doe@yourdomain.com
Active: ✓ (checked)
Path: users (organizational path)
```

3. Click **Create**
4. Set initial password via **Actions → Set password**

### Creating Groups

Groups simplify access management by applying policies to multiple users.

1. Navigate to **Directory → Groups**
2. Click **Create**

**Group Configuration:**

```
Name: Portainer Admins
Parent: (optional - for nested groups)
```

3. Click **Create**
4. Add users via **Users** tab

### Assigning Application Access via Groups

1. Navigate to **Applications → Applications**
2. Select your application (e.g., Portainer)
3. Click **Policy / Group / User Bindings** tab
4. Click **Bind existing policy**

**Binding Configuration:**

```
Order: 0 (lower = higher priority)
Policy: Group - Portainer Admins
```

Now only users in the "Portainer Admins" group can access Portainer.

## Advanced Configuration

### Configuring LDAP Provider

For legacy applications requiring LDAP authentication:

1. Navigate to **Applications → Providers**
2. Click **Create**
3. Select **LDAP Provider**

**Configuration:**

```
Name: LDAP Provider
Authorization Flow: default-provider-authorization-implicit-consent
Bind Flow: default-authentication-flow
Search Group: (select base group for user search)
TLS Server Name: auth.yourdomain.com
Certificate: authentik Self-signed Certificate
```

**LDAP Connection Details (for applications):**

```
Server: ldap://authentik_server:389 or ldaps://authentik_server:636
Base DN: dc=ldap,dc=goauthentik,dc=io
Bind DN: cn=ldapservice,ou=users,dc=ldap,dc=goauthentik,dc=io
Bind Password: (shown in provider details)
```

### Custom Authentication Flows

To customize the login experience:

1. Navigate to **Flows & Stages → Flows**
2. Duplicate the **default-authentication-flow**
3. Rename it (e.g., "Custom Login Flow")
4. Click **Edit** and add/remove/reorder stages:
   - Identification Stage (username/email entry)
   - Password Stage (password verification)
   - MFA Validation Stage (2FA)
   - User Write Stage (for enrollment)

**Apply the flow:**

1. Navigate to **System → Brands**
2. Edit **authentik-default**
3. Set **Authentication flow** to your custom flow

### Enabling Multi-Factor Authentication

**For All Users (Mandatory):**

1. Navigate to **Flows & Stages → Flows**
2. Edit **default-authentication-flow**
3. Click **Stage Bindings**
4. Add **authenticator-validate-stage** after password stage

**For User Self-Service (Optional):**

Users can enable MFA via their user settings:
```
https://auth.yourdomain.com/if/user/
```

Supported MFA methods:
- TOTP (Google Authenticator, Authy)
- WebAuthn (YubiKey, biometrics)
- Static tokens (backup codes)
- Duo Push

## Monitoring and Troubleshooting

### Event Logs

All authentication events are logged:

1. Navigate to **Events → Logs**
2. Filter by event type:
   - `login` - Successful logins
   - `login_failed` - Failed login attempts
   - `logout` - User logouts
   - `authorize_application` - OAuth2 authorizations

### Common Issues

**Issue: "Redirect URI mismatch"**

- **Cause:** The redirect URI in the application doesn't match the provider configuration
- **Fix:** Ensure the redirect URI in Authentik matches exactly (including trailing slashes)

**Issue: "Invalid client" error**

- **Cause:** Client ID or secret is incorrect
- **Fix:** Verify credentials match between Authentik provider and application config

**Issue: Users can't access application**

- **Cause:** No policy binding or policy evaluation failed
- **Fix:** Check **Policy / Group / User Bindings** tab on the application

**Issue: Forward auth loops (infinite redirects)**

- **Cause:** Authentik is trying to authenticate itself
- **Fix:** Add middleware exception for `auth.yourdomain.com` in Traefik config

### System Health Checks

Monitor Authentik health:

```bash
# Check service status
docker service ls | grep authentik

# View logs
docker service logs authentik_authentik_server
docker service logs authentik_authentik_worker

# Check Redis connectivity
docker exec $(docker ps -q -f name=authentik_redis) redis-cli ping
# Should return: PONG

# Check PostgreSQL connectivity
docker exec $(docker ps -q -f name=postgres) psql -U authentik -d authentik -c "SELECT 1;"
# Should return: 1
```

## Security Best Practices

### 1. Use Strong Secrets

Generate strong secrets for production:

```bash
# Generate 64-character random secret
openssl rand -base64 64
```

Store in Docker secrets:
```bash
echo "your-secret-here" | docker secret create authentik-secret-key -
```

### 2. Rotate Secrets Regularly

Update secrets every 90 days:

1. Generate new secret
2. Update provider configuration
3. Update application configuration
4. Test authentication
5. Remove old secret

### 3. Enable Rate Limiting

Protect against brute force attacks:

1. Navigate to **Flows & Stages → Stages**
2. Find **default-authentication-password** stage
3. Edit stage
4. Enable **Failed attempts before cancel**: 5
5. Save

### 4. Review Audit Logs

Regularly check for suspicious activity:

```
Events → Logs → Filter by "login_failed"
```

Look for:
- Multiple failed login attempts from same IP
- Login attempts for non-existent users
- Successful logins from unusual locations

### 5. Implement Session Timeout

1. Navigate to **System → Settings**
2. Set **Session duration**: 12 hours (default)
3. Set **Session remember duration**: 30 days

### 6. Use HTTPS Only

Ensure all Authentik URLs use HTTPS:
- Never expose HTTP endpoints externally
- Use valid SSL/TLS certificates (Let's Encrypt recommended)
- Enable HTTP Strict Transport Security (HSTS) in Traefik

### 7. Backup Configuration

Regularly backup Authentik data:

```bash
# Backup PostgreSQL database
docker exec postgres pg_dump -U authentik authentik > authentik-backup-$(date +%Y%m%d).sql

# Backup media files (custom icons, templates)
tar -czf authentik-media-$(date +%Y%m%d).tar.gz /home/doc/swarm-data/appdata/authentik/media/
```

## User Portal Customization

Users access their portal at:
```
https://auth.yourdomain.com/if/user/
```

The portal shows:
- Available applications
- User settings
- MFA device management
- Active sessions

**Customize Branding:**

1. Navigate to **System → Brands**
2. Edit **authentik-default**

**Available Options:**

```
Title: Your Company Name
Logo: (upload custom logo)
Favicon: (upload custom favicon)
Footer Links: (JSON array of links)
```

**Example Footer Links:**

```json
[
  {
    "name": "Documentation",
    "href": "https://docs.yourdomain.com"
  },
  {
    "name": "Support",
    "href": "https://support.yourdomain.com"
  }
]
```

## Integration Checklist

When adding a new SSO application:

- [ ] Determine authentication protocol (OAuth2, SAML, LDAP, Proxy)
- [ ] Create provider in Authentik
- [ ] Save Client ID and Client Secret (if OAuth2)
- [ ] Create application in Authentik
- [ ] Configure application to use Authentik
- [ ] Create group for access control (if needed)
- [ ] Bind group policy to application
- [ ] Test login flow
- [ ] Test logout flow
- [ ] Verify user attributes are passed correctly
- [ ] Document configuration for future reference
- [ ] Add application icon to Authentik portal

## Performance Optimization

### Redis Configuration

Ensure Redis has sufficient memory:

```yaml
# In authentik_redis service
deploy:
  resources:
    limits:
      memory: 512M
    reservations:
      memory: 256M
```

### Database Connection Pooling

Configure PostgreSQL for optimal performance:

```bash
# In PostgreSQL configuration
max_connections = 200
shared_buffers = 256MB
effective_cache_size = 1GB
```

### Worker Scaling

Scale worker replicas for background tasks:

```bash
docker service scale authentik_authentik_worker=2
```

Useful when:
- Processing many email notifications
- Running LDAP sync for large directories
- Handling high authentication volumes

## Maintenance Tasks

### Monthly

- Review event logs for suspicious activity
- Check SSL certificate expiration dates
- Verify backup restoration process
- Update Authentik to latest version

### Quarterly

- Rotate OAuth2 secrets
- Review and remove unused applications
- Audit user accounts and groups
- Review and update policies

### Annually

- Review all authentication flows
- Audit all provider configurations
- Document any custom configurations
- Disaster recovery drill

## Upgrading Authentik

To upgrade to the latest version:

```bash
# Pull latest images
docker service update --image ghcr.io/goauthentik/server:latest authentik_authentik_server
docker service update --image ghcr.io/goauthentik/server:latest authentik_authentik_worker

# Or update via compose file
docker stack deploy -c authentik-compose.yml authentik
```

**Important:** Always backup database before upgrading.

## Conclusion

Authentik provides enterprise-grade SSO capabilities for your homelab. By centralizing authentication, you gain:

- **Single Sign-On** - One login for all services
- **Enhanced Security** - MFA, audit logs, access policies
- **User Management** - Centralized user and group administration
- **Flexibility** - Support for multiple authentication protocols
- **Self-Service** - Users can manage their own profiles and MFA

With this guide, you should have a fully functional SSO setup. Start with one or two applications, master the workflow, then gradually migrate all services to centralized authentication.

## Additional Resources

- **Authentik Documentation:** https://goauthentik.io/docs/
- **OAuth2 Specification:** https://oauth.net/2/
- **OpenID Connect:** https://openid.net/connect/
- **Docker Swarm Deployment Workflow:** [../docker-swarm-deployment-workflow](../docker-swarm-deployment-workflow)
- **Homelab Infrastructure:** [../homelab-infrastructure](../homelab-infrastructure)

## Related Homelab Posts

- [Frostlabs v3 Infrastructure](/projects/frostlabs-v3/)
- [Docker Swarm Commands Reference](../docker-swarm-commands)
- [Rebalancing Docker Swarm](../swarm-rebalancing-manager-promotion)
