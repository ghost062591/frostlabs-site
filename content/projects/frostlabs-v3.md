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

The infrastructure runs on a 4-node Docker Swarm cluster, hosting 12 services across multiple domains with automatic SSL/TLS certificates, centralized identity management, and comprehensive monitoring capabilities.

## Infrastructure Architecture

### Swarm Cluster Configuration

**Node Topology:**
- **p0** (Manager/Leader) - Primary orchestration node running Docker Engine 28.5.1
- **p1** (Worker) - General workload node
- **p2** (Worker) - General workload node
- **p3** (Worker) - General workload node

**Network Architecture:**
- **homelab** (Overlay Network) - Primary service mesh for all applications
- **caddy** (Overlay Network) - Legacy network (retained for compatibility)
- **ingress** (Overlay Network) - Built-in Docker Swarm ingress network

All services communicate through the encrypted overlay network, providing network isolation and secure inter-service communication.

### Storage Strategy

**Data Persistence:**
- Application data: `/home/doc/swarm-data/appdata/`
- Configuration files: `/home/doc/swarm/swarm-production/conf/`
- Certificates: `/home/doc/swarm-data/appdata/traefik/certificates/`

Each service maintains its own persistent volume mounts, ensuring data survives container restarts and updates. Configuration is separated from data for easier version control and deployment automation.

## Service Stack

### Reverse Proxy & SSL/TLS - Traefik v3.5

**Hostname:** `proxy.frostlabs.me`

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

**Hostname:** `auth.frostlabs.me`

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

**Hostname:** `portainer.frostlabs.me`

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

**Hostname:** `docs.frostlabs.me`
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
- Allowed hosts: `docs.frostlabs.me`, `docs.frostlabs.home`

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

**Hostname:** `n8n.bitfrost.me`
**Port:** 5678/tcp

N8N is a workflow automation tool enabling complex automation between various services and APIs.

**Features:**
- Visual workflow builder
- 400+ integrations (APIs, databases, services)
- Webhook support for event-driven automation
- Scheduled workflows via cron expressions
- JavaScript function nodes for custom logic

**Resource Allocation:**
- Memory Reservation: 512MB
- Memory Limit: 2GB
- Enables runner mode for isolated workflow execution

**Configuration:**
- Protocol: HTTPS
- Webhook URL: `https://n8n.bitfrost.me/`
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

**Active Secrets:**
- `cloudflare_api_token` - Traefik DNS challenge authentication
- `auth-key` - Authentik secret key
- `postgres-master` - PostgreSQL admin password
- `paperless-admin-pass` - Paperless admin password
- `paperless-secret-key` - Paperless Django secret key

Secrets are never stored in compose files or environment variables, reducing the risk of credential exposure.

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

Services are organized into logical stacks:
- `traefik` - Reverse proxy and ingress
- `authentik` - Identity management
- `portainer` - Container management
- `paperless` - Document management
- `n8n` - Workflow automation
- `tracker` - Custom application
- `adminer` - Database tools
- `rsync` - Backup services

Each stack has its own Docker Compose file in the configuration repository, enabling independent versioning and deployment.

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

### Traefik Dashboard

Access point: `https://proxy.frostlabs.me`

Real-time visibility into:
- Active routers and services
- HTTP request metrics
- Certificate status
- Backend health checks

### Portainer Monitoring

Access point: `https://portainer.frostlabs.me`

Cluster-wide visibility into:
- Container resource usage (CPU, memory, network)
- Service replica status
- Node health and availability
- Stack deployment status
- Container logs (centralized)

### Access Logging

Traefik maintains comprehensive access logs for all HTTP traffic, enabling:
- Traffic analysis
- Security auditing
- Performance troubleshooting
- Rate limiting and abuse detection

## Technical Achievements

### Automated Certificate Management

Traefik handles Let's Encrypt certificates automatically via Cloudflare DNS-01 challenges, supporting:
- Wildcard certificates (`*.frostlabs.me`)
- Automatic renewal (60 days before expiration)
- Zero manual intervention
- No exposed ports for HTTP-01 challenges

### Dynamic Service Discovery

Traefik automatically discovers new services via Docker Swarm labels:

```yaml
labels:
  - traefik.enable=true
  - traefik.http.routers.service.entrypoints=websecure
  - traefik.http.routers.service.rule=Host(`service.frostlabs.me`)
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

**Cluster Uptime:** 42+ hours continuous operation
**Total Services:** 12 (all healthy)
**Total Containers:** 16+ (including agents and workers)
**Network Latency:** Sub-millisecond inter-service communication via overlay network
**Certificate Management:** 100% automated, zero manual renewals

## Future Enhancements

### Planned Improvements

1. **Metrics & Monitoring**
   - Prometheus for time-series metrics
   - Grafana for visualization dashboards
   - AlertManager for proactive notifications

2. **Centralized Logging**
   - Loki for log aggregation
   - Integration with Grafana for unified observability

3. **Backup Automation**
   - Automated database backups
   - Application data snapshots
   - Off-site backup replication

4. **High Availability**
   - Additional manager nodes (3-node manager quorum)
   - Load balancing across multiple Traefik instances
   - PostgreSQL clustering with automatic failover

5. **Security Enhancements**
   - Authentik integration for all services
   - Network policies for microsegmentation
   - Automated vulnerability scanning

6. **CI/CD Pipeline**
   - GitOps workflow for infrastructure changes
   - Automated testing of compose files
   - Staged deployments (dev → staging → production)

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
