---
title: "Frostlabs v3: Complete Docker Swarm Infrastructure Rebuild"
date: 2025-10-29T00:00:00Z
draft: false
tags:
  - docker
  - swarm
  - infrastructure
  - homelab
  - devops
description: A complete teardown and rebuild of my Docker Swarm homelab infrastructure, featuring 4 nodes running 12 production services with automated SSL/TLS, centralized authentication, and production-grade monitoring.
categories:
  - infrastructure
  - homelab
---

## Project Overview

Frostlabs v3 represents a complete teardown and rebuild of my homelab Docker Swarm infrastructure. After running previous iterations and learning from their limitations, this version focuses on production-grade practices, security, centralized authentication, and maintainable configuration management.

### Infrastructure at a Glance

| Metric | Value |
|--------|-------|
| **Cluster Nodes** | 4 (1 Manager, 3 Workers) |
| **Total Services** | 12 Production Services |
| **Total Containers** | 16+ (including agents) |
| **Docker Version** | 28.5.1 |
| **Orchestration** | Docker Swarm Mode |
| **SSL/TLS** | Automated via Let's Encrypt |
| **Authentication** | Centralized (Authentik SSO) |
| **Network Type** | Encrypted Overlay |
| **Uptime** | 42+ hours continuous |

## Infrastructure Architecture

### Cluster Nodes

| Node | Role | Status | Engine Version | Services Hosted |
|------|------|--------|----------------|-----------------|
| **p0** | Manager/Leader | Ready/Active | 28.5.1 | Traefik, Authentik, Portainer (main), Rsync |
| **p1** | Worker | Ready/Active | 28.5.1 | Portainer Agent |
| **p2** | Worker | Ready/Active | 28.5.1 | Portainer Agent |
| **p3** | Worker | Ready/Active | 28.5.1 | Portainer Agent, Tracker |

### Network Architecture

| Network | Type | Purpose | Encryption |
|---------|------|---------|------------|
| **homelab** | Overlay | Primary service mesh | ✓ Encrypted |
| **ingress** | Overlay | Built-in Swarm ingress | ✓ Encrypted |

All services communicate through encrypted overlay networks, providing network isolation and secure inter-service communication.

### Storage Layout

| Path | Purpose | Backup Priority |
|------|---------|-----------------|
| `/home/doc/swarm-data/appdata/` | Application data & databases | High |
| `/home/doc/swarm/swarm-production/conf/` | Stack configuration files | Critical |
| `/home/doc/swarm-data/appdata/traefik/certificates/` | SSL/TLS certificates | Medium |

Configuration is separated from data for easier version control and deployment automation. All persistent data survives container restarts and updates.

## Service Stack

### Production Services Overview

| Service | Version | Stack Name | Ports | Replicas | Primary Function |
|---------|---------|------------|-------|----------|------------------|
| **Traefik** | v3.5 | traefik | 80, 443, 8082 | 1/1 | Reverse proxy & SSL/TLS termination |
| **Authentik** | 2025.10.0 | authentik | - | 3/3 | SSO & identity management (server + worker + redis) |
| **Portainer** | CE Latest | portainer | - | 5/5 | Container management (main + 4 agents) |
| **Paperless-ngx** | Latest | paperless | 8000 | 2/2 | Document management with OCR (web + redis) |
| **N8N** | Latest | n8n | 5678 | 1/1 | Workflow automation platform |
| **Adminer** | Latest | adminer | 8091 | 1/1 | Database administration UI |
| **Tracker** | Custom | tracker | 8180 | 1/1 | Custom Nginx web application |
| **Rsync** | Alpine | rsync | - | 1/1 | Backup & synchronization service |

---

### Reverse Proxy & SSL/TLS - Traefik v3.5

Traefik serves as the edge router and load balancer for all services, handling:

**Key Features:**
- Automatic SSL/TLS certificate management via Cloudflare DNS challenge
- HTTP to HTTPS automatic redirection
- Dynamic service discovery via Docker Swarm provider
- Real-time configuration updates without restarts
- Centralized access logging

**Configuration Highlights:**
```yaml
Entrypoints:
  - web (port 80) → Redirects to websecure
  - websecure (port 443) → Production HTTPS traffic
  - dashboard (port 8082) → Traefik monitoring UI

Certificate Resolver: Cloudflare DNS-01 Challenge
  - Automated Let's Encrypt certificate issuance
  - Wildcard certificate support
  - Secure API token via Docker secrets
```

**Published Ports:**
- 80/tcp → HTTP (redirects to 443)
- 443/tcp → HTTPS
- 8082/tcp → Traefik dashboard

The service is constrained to run on the manager node (p0) to maintain consistent ingress routing.

### Identity & Access Management - Authentik 2025.10.0

Authentik provides centralized authentication and single sign-on (SSO) for all homelab services.

**Components:**
- **authentik_server** - Main application server handling authentication flows
- **authentik_worker** - Background task processor for email, LDAP sync, and scheduled jobs
- **authentik_redis** - Session storage and caching layer (published on port 6379)

**Key Capabilities:**
- OAuth2/OIDC provider for modern applications
- LDAP/SAML support for legacy systems
- Multi-factor authentication (MFA)
- User self-service portal
- Application proxy for legacy apps without auth

**Backend Configuration:**
- PostgreSQL database at `10.0.4.10:5432`
- Database: `authentik` (credentials via Docker secrets)
- Media storage: `/home/doc/swarm-data/appdata/authentik/media`
- Custom templates: `/home/doc/swarm-data/appdata/authentik/templates`

All sensitive credentials (database password, secret keys) are managed through Docker Swarm secrets for enhanced security.

### Container Management - Portainer CE

Portainer provides a web-based management interface for the entire Docker Swarm cluster.

**Architecture:**
- **portainer_portainer** - Management server running on manager node
- **portainer_agent** - Monitoring agent deployed globally (1 per node)

**Features:**
- Visual stack deployment and management
- Real-time container logs and stats
- Docker Swarm service scaling
- Image registry integration
- Role-based access control

The agent architecture enables Portainer to monitor and manage containers across all nodes without requiring direct SSH access to each host.

### Document Management - Paperless-ngx

**Port:** 8000/tcp

Paperless-ngx is a document management system with OCR capabilities for digitizing and organizing paperwork.

**Components:**
- **paperless_webserver** - Main Django application
- **paperless_redis** - Task queue and caching

**Key Features:**
- Automatic OCR (Optical Character Recognition) for scanned documents
- Full-text search across all documents
- Tag-based organization with auto-tagging rules
- Duplicate detection and handling
- Email import via mail rules
- RESTful API for automation

**Configuration:**
- Database: PostgreSQL at `10.0.4.10:5432` (database: `paperless`)
- OCR Language: English
- Timezone: America/New_York
- Consumer: 5-second polling interval with recursive directory monitoring

**Storage Structure:**
```
/home/doc/swarm-data/appdata/paperless/
├── data/       # Document metadata and index
├── media/      # Original and archived documents
├── export/     # Bulk export location
└── consume/    # Document ingestion directory
```

Documents placed in the `consume/` directory are automatically processed, OCR'd, and added to the system.

### Workflow Automation - N8N

**Port:** 5678/tcp

N8N is a workflow automation tool enabling complex automation between various services and APIs.

**Features:**
- Visual workflow builder
- 400+ integrations (APIs, databases, services)
- Webhook support for event-driven automation
- Scheduled workflows via cron expressions
- JavaScript function nodes for custom logic
- **CI/CD Integration:** Receives webhooks from Gitea on push events and executes `docker stack deploy` commands for automated deployments

**Resource Allocation:**
- Memory Reservation: 512MB
- Memory Limit: 2GB
- Enables runner mode for isolated workflow execution

**Configuration:**
- Protocol: HTTPS
- Timezone: America/New_York
- Data persistence: `/home/doc/swarm-data/appdata/n8n`

The service has access to the Docker socket for Docker-based automation workflows.

### Database Management - Adminer

**Port:** 8091/tcp (HTTP)

Adminer provides a lightweight web interface for database administration.

**Supported Databases:**
- PostgreSQL
- MySQL/MariaDB
- SQLite
- MongoDB
- Elasticsearch

Simple, single-container deployment with no persistent storage requirements. Access is network-restricted and not publicly exposed.

### Custom Web Application - Tracker

**Port:** 8180/tcp

A custom Nginx-based web application serving static content from `/home/doc/swarm-data/appdata/webfiles/production/taylors-development`.

**Configuration:**
- Web server: Nginx (Alpine-based)
- Custom nginx.conf with application-specific routing
- Read-only filesystem for security
- Deployed to worker nodes only (load distribution)

This service demonstrates the ability to deploy custom applications alongside pre-built solutions in the same infrastructure.

### Backup & Synchronization - Rsync Service

A lightweight backup service based on Alpine Linux, handling automated data synchronization tasks across the cluster.

**Use Cases:**
- Cross-node data replication
- External backup synchronization
- Configuration file distribution

Deployed on the manager node to coordinate backup operations across the cluster.

## Security Architecture

### Secrets Management

All sensitive credentials are managed through Docker Swarm secrets:

| Secret Name | Purpose | Used By |
|-------------|---------|---------|
| `cloudflare_api_token` | DNS-01 challenge authentication | Traefik |
| `auth-key` | Application secret key | Authentik |
| `postgres-master` | Database admin credentials | PostgreSQL, Authentik, Paperless |
| `paperless-admin-pass` | Admin account password | Paperless-ngx |
| `paperless-secret-key` | Django application secret | Paperless-ngx |

**Security Benefits:**
- ✓ Never stored in compose files or environment variables
- ✓ Encrypted at rest and in transit
- ✓ Mounted as read-only files in containers
- ✓ Not exposed via `docker inspect`

### Network Isolation

Services communicate exclusively through the encrypted `homelab` overlay network. External access is only possible through Traefik's reverse proxy, which enforces:
- Automatic HTTPS redirection
- Valid SSL/TLS certificates
- Domain-based routing rules
- Access logging

### Service Constraints

Critical infrastructure services (Traefik, Authentik, Portainer server) are constrained to the manager node (p0) using placement constraints:

```yaml
deploy:
  placement:
    constraints:
      - node.hostname == p0
```

This ensures consistent routing and prevents services from migrating during updates or node failures.

## Deployment Strategy

### Stack-Based Organization

| Stack | Services | Config File | Update Independence |
|-------|----------|-------------|---------------------|
| `traefik` | Reverse proxy & ingress | `traefik-compose.yml` | ✓ Independent |
| `authentik` | Identity management (3 containers) | `authentik-compose.yml` | ✓ Independent |
| `portainer` | Container management (5 containers) | `portainer-compose.yml` | ✓ Independent |
| `paperless` | Document management (2 containers) | `paperless-compose.yml` | ✓ Independent |
| `n8n` | Workflow automation | `n8n-compose.yml` | ✓ Independent |
| `tracker` | Custom web application | `tracker-compose.yml` | ✓ Independent |
| `adminer` | Database administration | `adminer-compose.yml` | ✓ Independent |
| `rsync` | Backup & sync services | `rsync-compose.yml` | ✓ Independent |

Each stack has its own Docker Compose file in the configuration repository, enabling independent versioning and deployment without affecting other services.

### Update Configuration

All services use a consistent update strategy:
```yaml
deploy:
  update_config:
    parallelism: 1          # Update one container at a time
    on_failure: pause       # Stop updates if deployment fails
    monitor: 5s             # Wait 5 seconds to verify health
    order: stop-first       # Stop old container before starting new
  rollback_config:
    parallelism: 1
    on_failure: pause
    order: stop-first
```

This ensures zero-downtime updates with automatic rollback on failure.

## Monitoring & Observability

| Component | Access Method | Monitoring Capabilities |
|-----------|---------------|------------------------|
| **Traefik Dashboard** | Web UI (port 8082) | Active routers, HTTP metrics, certificate status, backend health |
| **Portainer** | Web UI (via Traefik) | Container resource usage, replica status, node health, stack deployments, centralized logs |
| **Access Logs** | Via Traefik | Traffic analysis, security auditing, performance troubleshooting, abuse detection |

### Key Metrics Tracked

| Metric Category | Data Points | Retention |
|-----------------|-------------|-----------|
| **Container Resources** | CPU, memory, network I/O | Real-time |
| **Service Health** | Replica count, restart count, update status | Real-time |
| **HTTP Traffic** | Request count, response times, status codes | Log files |
| **Cluster State** | Node availability, service distribution, network status | Real-time |
| **Certificates** | Expiration dates, renewal status, issuer info | Real-time |

## Technical Achievements

### Automated Certificate Management

Traefik handles Let's Encrypt certificates automatically via Cloudflare DNS-01 challenges, supporting:
- Wildcard certificates for all domains
- Automatic renewal (60 days before expiration)
- Zero manual intervention
- No exposed ports for HTTP-01 challenges

### Dynamic Service Discovery

Traefik automatically discovers new services via Docker Swarm labels:

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.service.entrypoints=websecure
  - traefik.http.routers.service.rule=Host(`service.example.com`)
  - traefik.http.routers.service.tls.certresolver=cloudflare
```

No Traefik restarts required when adding new services.

### Global Agent Deployment

Portainer agents run on all 4 nodes using Docker Swarm's global mode:
```yaml
deploy:
  mode: global
```

Ensures complete visibility regardless of cluster size changes.

## Lessons Learned & Best Practices

### Pin Critical Services

Pinning Traefik and Portainer to the manager node prevents routing issues during Swarm rebalancing. Worker nodes can fail without disrupting ingress traffic.

### Separate Configuration from Data

Storing compose files in `/home/doc/swarm/swarm-production/` separate from application data enables:
- Version control for infrastructure-as-code
- Easy disaster recovery
- Testing changes in development stacks

### Use Secrets for Everything Sensitive

Never hardcode passwords in compose files. Even environment variables can be exposed via `docker inspect`. Docker secrets are encrypted at rest and in transit.

### Implement Resource Limits

Services like N8N can consume excessive memory if unbounded. Resource limits prevent one service from starving others:
```yaml
resources:
  reservations:
    memory: 512M
  limits:
    memory: 2G
```

### Enable Update Rollbacks

The `rollback_config` in deployment specs enables automatic recovery from bad updates. Combined with health checks, this provides deployment confidence.

## Performance Metrics

| Metric | Current Status | Target | Status |
|--------|----------------|--------|--------|
| **Cluster Uptime** | 42+ hours | 99.9% | ✓ On track |
| **Total Services** | 12 | N/A | ✓ All healthy |
| **Total Containers** | 16+ | N/A | ✓ All running |
| **Network Latency** | <1ms | <5ms | ✓ Excellent |
| **Certificate Management** | 100% automated | 100% | ✓ Zero manual renewals |
| **Service Availability** | 100% | 99.5% | ✓ Exceeding target |
| **Failed Deployments** | 0 | <1% | ✓ Perfect record |

## Future Enhancements

| Priority | Category | Enhancement | Estimated Effort | Dependencies |
|----------|----------|-------------|------------------|--------------|
| **High** | Monitoring | Prometheus + Grafana + AlertManager | Medium | None |
| **High** | Logging | Loki for centralized log aggregation | Medium | Grafana |
| **High** | Backup | Automated database & data snapshots | Low | None |
| **Medium** | HA | 3-node manager quorum for fault tolerance | Medium | Additional hardware |
| **Medium** | HA | PostgreSQL clustering with failover | High | Additional nodes |
| **Medium** | Security | Authentik SSO for all services | Medium | Service compatibility |
| **Medium** | Security | Network policies & microsegmentation | Medium | Firewall configuration |
| **Low** | CI/CD | Enhanced GitOps workflow (ArgoCD/Flux) | High | Git repository setup |
| **Low** | CI/CD | Automated compose file testing | Medium | CI/CD pipeline |
| **Low** | Security | Automated vulnerability scanning | Low | Registry integration |

**Note:** Basic CI/CD is already implemented using N8N webhooks from Gitea for automated stack deployments.

### Roadmap Timeline

**Q1 2025:** Prometheus/Grafana monitoring stack, automated backups
**Q2 2025:** Authentik SSO integration across services, Loki logging
**Q3 2025:** High availability improvements, additional manager nodes
**Q4 2025:** Enhanced GitOps workflows (ArgoCD/Flux), automated testing

## Repository & Documentation

**Infrastructure Repository:** Private (contains sensitive configuration)
**Documentation:** This project page + inline comments in compose files

For questions or collaboration opportunities, reach out via the contact information on this blog.

## Conclusion

Frostlabs v3 represents a significant evolution in infrastructure maturity. Moving from ad-hoc container deployments to orchestrated, production-grade infrastructure has provided:

- **Reliability:** Zero-downtime updates and automatic health monitoring
- **Security:** Secrets management, encrypted networks, and centralized authentication
- **Scalability:** Easy addition of new nodes and services
- **Maintainability:** Infrastructure-as-code with version control

The journey from v1 (basic Docker Compose) → v2 (initial Swarm exploration) → v3 (production-ready infrastructure) has been invaluable for understanding container orchestration, networking, and operational best practices.

This infrastructure now serves as a stable foundation for future homelab projects, automation workflows, and self-hosted service deployments.

---

*Last Updated: October 29, 2025*
*Docker Engine Version: 28.5.1*
*Swarm Mode: Active*
