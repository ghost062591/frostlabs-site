---
title: "Frostlabs: Complete Docker Swarm"
date: 2025-10-29T00:00:00Z
draft: false
tags:
  - docker
  - swarm
  - infrastructure
  - homelab
  - devops
description: A redesigned, production-ready Docker Swarm cluster running self-hosted productivity tools and services with enterprise-grade security, automated SSL/TLS, and distributed storage.
categories:
  - infrastructure
  - homelab
---

## **Current Version:** `V4`

## **Previous Versions:**

- **V1:** Initial deployment: `2 nodes`
- **V2:** Deployed 2 more nodes: `4 Nodes`
- **V3:** Deployed 1 node & implemented GitOps: `5 Nodes` `1 VM`


## Overview
**Frostlabs is a 6-node Docker Swarm cluster designed for self-hosted productivity tools and experimental learning. The infrastructure emphasizes:**

- **High Availability**: Multi-node swarm with replicated managers
- **Security First**: SSO authentication, intrusion detection, and network isolation
- **Automated SSL**: Cloudflare DNS challenge for automatic HTTPS certificates
- **Distributed Storage**: GlusterFS for persistent data across nodes
- **GitOps Ready**: Infrastructure-as-code with webhook-based deployments

**Primary Use Cases:**
- Self-hosted productivity applications (document management, automation)
- Learning platform for experimenting with new technologies
- Production-ready personal services

## Infrastructure Architecture

### Cluster Topology

The swarm consists of 6 nodes organized by role:

| Node | Role | Availability |  Labels |
|------|------|--------------|---------|
| p1-control | Manager | Active  | `task=control` |
| p2-control | Manager | Active  | `task=control` |
| p3-control | Manager | Active  | `task=control` |
| p0-compute | Manager | Active  | `task=compute` |
| p4-compute | Manager | Active  | `task=compute` |
| p5-compute | Manager | Active  | `task=compute` |
<br>

**Mixed Architecture** 

| Node | Machine | Model | RAM | CPU | Cores / Threads |
|------|---------|-------|-----|-----|-----------------|
| p1-control | ARM64 | Raspberry Pi 5 | 8 GB | Arm Cortex-A76 |  4C |
| p2-control | ARM64 | Raspberry Pi 5 | 16 GB | Arm Cortex-A76 |  4C |
| p3-control | ARM64 | Raspberry Pi 5 | 16 GB | Arm Cortex-A76 |  4C |
| p0-compute | ADM64 | Beelink SER 5 MAX (2023) | 32 GB | Ryzen 7 5800H | 8C / 16T |
| p4-compute | AMD64 | Unraid VM | 25 GB | 12th Gen Intel® Core™ i5-12600K | 5C / 11T |
| p5-compute | AMD64 | Unraid VM | 25 GB | 12th Gen Intel® Core™ i5-12600K | 5C / 11T |

|**Totals:** | `122 GB RAM` | `30 Cores / 38 Threads` |
|------------|--------------|-------------------------|

<br>

**Node Label Strategy:**
- `task=control`: Infrastructure services (Traefik, Portainer, CrowdSec)
- `task=compute`: Application workloads (Authentik, Paperless, n8n, etc.)

This separation ensures critical infrastructure services remain on manager nodes while compute-intensive applications run on dedicated "worker" nodes.

**NOTE**: Worker Node in this case is a node labeled as `task=compute` All nodes are managers insuring maximum uptime. 

### Networking

**Overlay Network: `frostlabs`**
- Driver: Overlay (encrypted by default in swarm mode)
- Scope: Swarm-wide
- Purpose: Inter-service communication across all nodes

**Unraid Host: `frostlabs`**

**Services Provided to Swarm**

| Postgres | NFS Volumes | VM's p4 & p5 |
|----------|-------------|--------------|

<br>

**Exposed Ports:**
- `80/tcp` - HTTP (redirects to HTTPS)
- `443/tcp` - HTTPS (Traefik entrypoint)
- `****/tcp` - Traefik dashboard
- `9000/tcp` - Portainer UI
- `5678/tcp` - n8n webhook endpoint

### Storage

**GlusterFS Distributed Filesystem**

Persistent data is stored on GlusterFS volumes mounted at `/home/doc/projects/swarm-data/` with the following structure:

```
/home/doc/projects/swarm-data/
├── traefik/
│   ├── certificates/        # ACME certificates
│   └── logs/               # Access logs for CrowdSec
├── crowdsec/
│   ├── config/             # CrowdSec configuration
│   └── data/               # Decision database
├── portainer/              # Portainer data
├── authentik/
│   ├── media/
│   └── templates/
├── paperless/
│   ├── data/
│   ├── media/
│   ├── export/
│   └── consume/
├── n8n/                    # n8n workflows
├── peertube/
│   ├── data/
│   ├── redis/
│   └── postgres/
└── webservers/production/  # Static site files
```

**Benefits:**
- Data replication across nodes
- High availability for stateful services
- Transparent failover

## Core Services

### Traefik (v3.6.1)

Modern reverse proxy and load balancer handling all ingress traffic.

**Features:**
- Automatic HTTPS via Cloudflare DNS challenge
- HTTP to HTTPS redirection
- Docker Swarm service discovery
- CrowdSec bouncer plugin for threat blocking
- Access logging for security monitoring

**Stack Location:** `core/stack.yml`

**Configuration Files:**
- `core/static.yml` - Static configuration (entrypoints, providers, ACME)
- `core/dynamic.yml` - Dynamic routing for external services

**Exposed Routes:**
All services use `*.frostlabs.me` or `*.bitfrost.me` domains with automatic SSL.

### CrowdSec

Collaborative intrusion detection and prevention system.

**Features:**
- Parses Traefik access logs for threat detection
- Crowdsourced IP reputation database
- Automatic banning via Traefik middleware
- Collections: `crowdsecurity/traefik`, `crowdsecurity/http-cve`

**Stack Location:** `core/stack.yml`

**Integration:**
- Reads Traefik logs from GlusterFS volume
- Bouncer plugin in Traefik blocks malicious IPs
- Metrics available on port 6060

### Portainer CE

Web-based Docker management interface for the entire swarm.

**Features:**
- Multi-node swarm visualization
- Stack deployment via UI
- Container/service management
- Webhook support for automated deployments

**Stack Location:** `core/stack.yml`

**Access:** `https://portainer.frostlabs.me` or `http://10.0.4.10:9000`

**Agent Deployment:**
- Global mode (runs on every node)
- Provides node-level metrics and control

## Application Services

### Authentik (v2025.10.0)

Enterprise SSO and identity provider.

**Components:**
- `authentik_server` - Main application server
- `authentik_worker` - Background task processor
- `redis` - Session cache

**Features:**
- Forward authentication for Traefik
- OIDC/SAML provider
- User/group management
- Protects sensitive services (e.g., Unraid dashboard)

**Stack Location:** `authentik/stack.yml`

**Access:** `https://auth.frostlabs.me`

**Database:** PostgreSQL on Unraid (`10.0.4.10:5432`)

### Paperless-ngx

Document management system with OCR and full-text search.

**Features:**
- Automatic document ingestion from consume folder
- OCR with English language support
- Duplicate detection
- Tagging and classification
- Export functionality

**Stack Location:** `paperless/stack.yml`

**Access:** `https://docs.frostlabs.me`

**Configuration:**
- Time Zone: `America/New_York`
- Database: PostgreSQL on Unraid
- Polling interval: 5 seconds
- Recursive consumption enabled

### n8n

Self-hosted workflow automation platform.

**Features:**
- Visual workflow builder
- 400+ integrations
- Webhook support
- Runner mode enabled

**Stack Location:** `n8n/stack.yml`

**Access:** `https://n8n.bitfrost.me`

**Resources:**
- Memory: 512MB reserved, 2GB limit
- Persistent workflows stored in GlusterFS

### PeerTube

Decentralized video hosting platform.

**Components:**
- `peertube` - Main application
- `postgres` - Database (v17-alpine)
- `redis` - Cache (v7-alpine)

**Stack Location:** `peertube/stack.yml`

**Access:** `https://videos.frostlabs.me`

**Configuration:**
- SMTP: Gmail integration for notifications
- Database: Dedicated PostgreSQL instance
- Admin email: frostlabs25@example.com

### Adminer

Lightweight database management interface.

**Stack Location:** `adminer/stack.yml`

**Purpose:** Web-based management for PostgreSQL/MySQL databases across the infrastructure.

### Tracker (Static Site)

Nginx-based static website hosting.

**Stack Location:** `tracker/stack.yml`

**Purpose:** Serves static HTML/CSS/JS from `/home/doc/projects/swarm-data/webfiles/production/taylors-development`

**Port:** `8180`

## External Services

Services running outside the swarm but routed through Traefik:

| Service | Host | Internal URL | Public Domain | Middleware |
|---------|------|--------------|---------------|------------|
| Unraid Dashboard | 10.0.4.10 | http://10.0.4.10:80 | unraid.frostlabs.me | Authentik, CrowdSec |
| Emby | 10.0.4.10 | http://10.0.4.10:8096 | movies.frostlabs.me | CrowdSec |
| Media Manager | 10.0.4.10 | http://10.0.4.10:8000 | media.frostlabs.me | CrowdSec |

**Configuration:** `core/dynamic.yml`

## Security

Multi-layered security approach:

### 1. SSO Authentication (Authentik)

- Forward authentication middleware in Traefik
- Protects administrative interfaces (Unraid, etc.)
- Centralized user management
- Session management via Redis

### 2. Intrusion Detection (CrowdSec)

- Real-time log analysis
- Automatic IP banning
- Community-driven threat intelligence
- Integrated with Traefik via bouncer plugin

### 3. Network Isolation

- Internal overlay network (`frostlabs`)
- Services not exposed unless explicitly configured
- Firewall rules limiting external access
- Trusted IP ranges for administrative access

### 4. SSL/TLS Encryption

- Automatic certificate issuance via Let's Encrypt
- Cloudflare DNS challenge (no port 80/443 exposure required)
- HTTPS enforcement (HTTP redirects)
- Certificate storage on GlusterFS for HA

### 5. Secrets Management

Docker secrets for sensitive data:
- `cloudflare_api_token` - DNS challenge authentication
- `auth-key` - Authentik secret key
- `postgres-master` - Database password
- `paperless-secret-key` - Django secret key
- `paperless-admin-pass` - Admin password

### 6. Resource Limits

All services have defined memory/CPU limits to prevent resource exhaustion attacks.

## Deployment Workflow

### Standard Deployment Process

1. **Local Testing**
   - Test stack configuration locally or in development environment
   - Validate service connectivity and configuration
   - Ensure no syntax errors in YAML files

2. **Git Commit**
   - Commit working stack files to Git repository
   - Push to remote (GitHub/Gitea)

3. **Portainer Deployment**
   - Navigate to Portainer UI (`https://portainer.frostlabs.me`)
   - Pull stack from Git repository
   - Deploy or update stack via Portainer interface

4. **Webhook Configuration**
   - Create webhook in Portainer for the stack
   - Future updates trigger automatic redeployment on Git push

### Manual Deployment

For quick updates or testing:

```bash
# SSH to any manager node (p1, p2, or p3)
ssh p1-control

# Deploy a stack
docker stack deploy -c /path/to/stack.yml <stack_name>

# Example: Deploy core infrastructure
docker stack deploy -c ~/projects/homelab/frostlabs/core/stack.yml core

# Update a service
docker service update --image <new_image> <service_name>

# Check service status
docker service ls
docker service ps <service_name>
```

### Stack Management Commands

```bash
# List all stacks
docker stack ls

# View services in a stack
docker stack services <stack_name>

# View tasks in a stack
docker stack ps <stack_name>

# Remove a stack
docker stack rm <stack_name>
```

## Monitoring & Maintenance

### Current Monitoring

**Portainer Dashboard:**
- Service health status
- Resource utilization per node
- Container logs
- Service scaling controls

**Manual Monitoring:**
```bash
# Node status
docker node ls

# Service health
docker service ls

# Check service logs
docker service logs -f <service_name>

# View CrowdSec decisions (banned IPs)
docker exec $(docker ps -q -f name=crowdsec_crowdsec) cscli decisions list

# Check Traefik metrics
curl http://<manager_ip>:8082/metrics
```

### Health Checks

All services include health checks:
- Traefik: Ping endpoint
- CrowdSec: `cscli version`
- Redis: `redis-cli ping`
- Authentik: `ak healthcheck`
- Paperless: HTTP endpoint test
- n8n: `/healthz` endpoint

### Future Monitoring Plans

- **Prometheus**: Metrics collection from all services
- **Grafana**: Visualization dashboards for cluster health
- **Alerting**: Notification system for service failures

## Backup Strategy

### Current Approach

**Configuration Backups:**
- All stack files version-controlled in Git
- Infrastructure-as-code approach ensures reproducibility

**Data Backups:**
- Manual/periodic backups of critical GlusterFS volumes
- Performed before major infrastructure changes

**Critical Data to Backup:**
- Traefik certificates (`/swarm-data/traefik/certificates`)
- Authentik database and media
- Paperless documents (`/swarm-data/paperless/media`)
- n8n workflows (`/swarm-data/n8n`)
- Portainer configuration

### Backup Commands

```bash
# Backup a GlusterFS volume
tar -czf backup-$(date +%Y%m%d).tar.gz /home/doc/projects/swarm-data/<service>

# Backup to remote location
rsync -avz /home/doc/projects/swarm-data/<service> user@backup-server:/backups/
```

### Future Backup Plans

- Automated scheduled backups via cron or dedicated backup service
- Off-site backup replication
- Snapshot-based backups for point-in-time recovery
- Automated testing of backup restoration

## Future Improvements

Planned enhancements to the infrastructure:

1. **Monitoring Stack**
   - Deploy Prometheus for metrics collection
   - Grafana dashboards for visualization
   - Alertmanager for notifications

2. **Automated Backups**
   - Scheduled backup jobs
   - Retention policies
   - Automated restore testing

3. **CI/CD Pipeline**
   - Automated testing of stack deployments
   - Canary deployments for zero-downtime updates
   - Automated rollback on failure

4. **Enhanced Security**
   - Regular vulnerability scanning
   - Automated certificate rotation monitoring
   - Security audit logging

5. **Performance Optimization**
   - Caching layers (Redis, Varnish)
   - CDN integration for static assets
   - Database query optimization

## Quick Start

### Prerequisites

- Docker Swarm initialized across all nodes
- GlusterFS volumes mounted on all nodes
- DNS records pointing to your swarm ingress
- Cloudflare API token for DNS challenge

### Initial Deployment

1. **Clone the repository:**
   ```bash
   git clone <repo_url>
   cd frostlabs
   ```

2. **Create Docker secrets:**
   ```bash
   echo "your_cloudflare_token" | docker secret create cloudflare_api_token -
   echo "your_auth_key" | docker secret create auth-key -
   echo "your_db_password" | docker secret create postgres-master -
   # Add other secrets as needed
   ```

3. **Create the overlay network:**
   ```bash
   docker network create --driver overlay --attachable frostlabs
   ```

4. **Deploy core infrastructure:**
   ```bash
   docker stack deploy -c core/stack.yml core
   ```

5. **Wait for Traefik and Portainer to be healthy:**
   ```bash
   docker service ls
   watch docker service ps core_traefik
   ```

6. **Deploy application stacks:**
   ```bash
   # Via Portainer UI (recommended)
   # or manually:
   docker stack deploy -c authentik/stack.yml authentik
   docker stack deploy -c paperless/stack.yml paperless
   docker stack deploy -c n8n/stack.yml n8n
   # etc.
   ```

### Accessing Services

Once deployed, access your services at:

- Portainer: `https://portainer.frostlabs.me`
- Authentik: `https://auth.frostlabs.me`
- Paperless: `https://docs.frostlabs.me`
- n8n: `https://n8n.bitfrost.me`
- PeerTube: `https://videos.frostlabs.me`
- Traefik Dashboard: `local access only`

---
**Frostlabs Admin:** `Johnathan Allison`
**Last Updated:** `2025-011-16`
**License:** MIT
