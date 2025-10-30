---
title: Homelab Infrastructure
date: 2025-10-17T08:27:58Z
tags:
  - homelab
  - docker
  - infrastructure
description: Overview of my homelab infrastructure featuring a 4-node Docker Swarm cluster, 12 production services, and automated multi-tier backup strategy.
---

## Architecture Overview

My homelab runs on a 4-node Docker Swarm cluster hosting 12 production services with automated backups and CI/CD workflows.

{{< mermaid >}}
%%{init: {'theme':'dark', 'themeVariables': { 'fontSize':'30px'}}}%%
graph TB
    subgraph cluster["Docker Swarm Cluster"]
        p0["p0 (Manager/Leader)<br/>BeeLink SER 5<br/>Ryzen 5800H 16c<br/>32GB RAM | 1TB SSD"]
        p1["p1 (Worker)<br/>Raspberry Pi 5<br/>8GB RAM | 512GB SSD"]
        p2["p2 (Worker)<br/>Raspberry Pi 5<br/>16GB RAM"]
        p3["p3 (Worker)<br/>Raspberry Pi 5<br/>16GB RAM"]
    end

    subgraph services["Production Services"]
        traefik["Traefik v3.5<br/>Reverse Proxy"]
        authentik["Authentik<br/>SSO/Auth"]
        portainer["Portainer<br/>Container Mgmt"]
        paperless["Paperless-ngx<br/>Document Mgmt"]
        n8n["N8N<br/>Workflow/CI/CD"]
        gitea["Gitea<br/>Git Server"]
        postgres["PostgreSQL<br/>Database"]
        redis["Redis<br/>Cache"]
        adminer["Adminer<br/>DB Admin"]
        tracker["Tracker<br/>Custom App"]
        rsync["Rsync Service<br/>Backup Sync"]
    end

    subgraph storage["Storage & Backup"]
        local["Local Storage (p0)<br/>~/swarm-data/appdata"]
        nfs["Unraid NFS Share<br/>~/swarm/appdata"]
        unraid["Unraid Host<br/>10c/16t | 64GB RAM<br/>Nvidia 2080 Super"]
        duplicati["Duplicati<br/>Backup Automation"]
        gdrive["Google Drive<br/>Cloud Backup"]
        coldstore["Backup Drive<br/>Cold Storage"]
    end

    p0 --> services
    p0 --> local

    local -->|rsync| nfs
    nfs --> unraid
    unraid --> duplicati
    duplicati --> gdrive
    duplicati --> coldstore

    style p0 fill:#2c3e50,stroke:#34495e,color:#fff
    style p1 fill:#2c3e50,stroke:#34495e,color:#fff
    style p2 fill:#2c3e50,stroke:#34495e,color:#fff
    style p3 fill:#2c3e50,stroke:#34495e,color:#fff
    style traefik fill:#8e44ad,stroke:#7d3c98,color:#fff
    style authentik fill:#8e44ad,stroke:#7d3c98,color:#fff
    style portainer fill:#8e44ad,stroke:#7d3c98,color:#fff
    style paperless fill:#8e44ad,stroke:#7d3c98,color:#fff
    style n8n fill:#8e44ad,stroke:#7d3c98,color:#fff
    style gitea fill:#8e44ad,stroke:#7d3c98,color:#fff
    style postgres fill:#8e44ad,stroke:#7d3c98,color:#fff
    style redis fill:#8e44ad,stroke:#7d3c98,color:#fff
    style adminer fill:#8e44ad,stroke:#7d3c98,color:#fff
    style tracker fill:#8e44ad,stroke:#7d3c98,color:#fff
    style rsync fill:#8e44ad,stroke:#7d3c98,color:#fff
    style local fill:#27ae60,stroke:#229954,color:#fff
    style nfs fill:#27ae60,stroke:#229954,color:#fff
    style unraid fill:#2c3e50,stroke:#34495e,color:#fff
    style duplicati fill:#e67e22,stroke:#d35400,color:#fff
    style gdrive fill:#3498db,stroke:#2980b9,color:#fff
    style coldstore fill:#e67e22,stroke:#d35400,color:#fff
{{< /mermaid >}}

## Infrastructure Components

### Compute Cluster

**Manager Node (p0):**
- BeeLink SER 5
- AMD Ryzen 5800H (16 cores)
- 32GB RAM, 1TB SSD
- Hosts critical services: Traefik, Authentik, Portainer

**Worker Nodes (p1-p3):**
- 3x Raspberry Pi 5
- 8GB-16GB RAM configurations
- Distributed service workloads

### Services Stack

The cluster runs 12 production services including:
- **Traefik v3.5** - Reverse proxy with automated SSL/TLS
- **Authentik** - Centralized SSO and authentication
- **Portainer** - Docker Swarm management interface
- **Paperless-ngx** - Document management with OCR
- **N8N** - Workflow automation and CI/CD orchestration
- **Gitea** - Self-hosted Git server
- **PostgreSQL & Redis** - Database and caching layers
- **Custom applications** - Tracker and other services

### Storage & Backup Strategy

**Three-tier backup approach:**

1. **Local Storage** - Application data on p0: `~/swarm-data/appdata`
2. **Network Storage** - Rsync to Unraid NFS share: `~/swarm/appdata`
3. **Automated Backups via Duplicati:**
   - Cloud backup to Google Drive (off-site)
   - Local cold storage on dedicated drive (spin-up on demand)

This strategy ensures data redundancy with both local and cloud backups while avoiding permission issues through rsync.

### Networking

All services communicate through an encrypted Docker overlay network ("homelab"). Traefik handles:
- SSL/TLS termination via Let's Encrypt
- Automatic certificate renewal using Cloudflare DNS-01 challenge
- Reverse proxy routing for all services

### CI/CD Pipeline

Automated deployment workflow:
1. Push code to Gitea repository
2. Gitea sends webhook to N8N
3. N8N executes `docker stack deploy` commands
4. Services updated with zero manual intervention

## Key Features

- ✓ **Automated CI/CD** - Webhook-driven deployments
- ✓ **Automated SSL/TLS** - Let's Encrypt certificates
- ✓ **Centralized Authentication** - Authentik SSO
- ✓ **Multi-tier Backups** - Local, NFS, and cloud
- ✓ **High Availability** - 4-node swarm cluster
- ✓ **Resource Isolation** - Service constraints per node

For detailed information about the infrastructure build, see the [Frostlabs v3 Project](/projects/frostlabs-v3/).