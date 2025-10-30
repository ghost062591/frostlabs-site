---
title: "Docker Swarm Service Deployment Workflow"
date: 2025-10-30T00:00:00Z
tags:
  - docker
  - swarm
  - workflow
  - best-practices
description: A practical guide to deploying services in Docker Swarm, including when to pin services, resource allocation, networking decisions, and troubleshooting.
categories:
  - homelab
  - tutorials
---

## Introduction

Deploying a new service to Docker Swarm isn't just about running `docker stack deploy`. There are important decisions to make about placement, resources, networking, and storage. This guide walks through my practical workflow for deploying services to my 4-node Frostlabs cluster.

---

## Pre-Deployment Planning

### 1. Understand the Service Requirements

Before writing your compose file, answer these questions:

**Resource Requirements:**
- How much CPU does it need?
- Memory requirements (minimum and maximum)?
- Does it need persistent storage?
- Does it require a GPU?
- Network bandwidth requirements?

**State and Data:**
- Is it stateless or stateful?
- What data needs to persist?
- Can it run multiple replicas?
- Does it need a database?

**Availability:**
- How critical is uptime?
- Can it tolerate brief interruptions?
- Does it need high availability (multiple replicas)?

**Security:**
- Does it need secrets (passwords, API keys)?
- What ports need to be exposed?
- Should it be internet-facing?

### 2. Choose Your Deployment Method

**Stack (Recommended):**
- Use for multi-service applications
- Easier to version control
- Can be redeployed easily
- Example: Authentik (server + worker + redis)

**Single Service:**
- Use for simple, standalone services
- Quick testing or one-off deployments
- Example: A monitoring agent

---

## Service Placement Decisions

### When to Pin Services to Specific Nodes

**Always Pin These:**

1. **Reverse Proxies (Traefik, Nginx)**
   - Need consistent ingress routing
   - Prevent routing issues during rebalancing
   - Pin to manager node for stability

```yaml
deploy:
  placement:
    constraints:
      - node.hostname == p0
```

2. **Stateful Databases**
   - Local storage is node-specific
   - Moving databases can cause data loss
   - Pin to node with adequate storage

```yaml
deploy:
  placement:
    constraints:
      - node.hostname == p0
      - node.labels.storage == true
```

3. **Services Requiring Specific Hardware**
   - GPU workloads
   - High-memory services
   - Special network interfaces

```yaml
deploy:
  placement:
    constraints:
      - node.labels.gpu == true
```

4. **Single-Instance Services**
   - Services that can't run multiple replicas
   - Legacy applications without clustering support
   - Services with file locks

```yaml
deploy:
  replicas: 1
  placement:
    constraints:
      - node.hostname == p0
```

**Don't Pin These:**

1. **Stateless Web Services**
   - Can run anywhere in the cluster
   - Let Swarm distribute for load balancing
   - Better fault tolerance

2. **Worker/Background Jobs**
   - Benefit from distributed processing
   - Can scale across multiple nodes
   - No specific node requirements

3. **Caching Services (Redis for sessions)**
   - If configured for HA/clustering
   - Can failover to other nodes

### Using Node Labels for Placement

**Set up node labels first:**

```bash
# Label nodes by function
docker node update --label-add role=infrastructure p0
docker node update --label-add role=worker p1
docker node update --label-add role=worker p2
docker node update --label-add role=worker p3

# Label nodes by capability
docker node update --label-add storage=true p0
docker node update --label-add gpu=true p0

# Label nodes by resource tier
docker node update --label-add tier=high-memory p0
docker node update --label-add tier=standard p1
```

**Use labels in compose:**

```yaml
deploy:
  placement:
    constraints:
      - node.labels.role == infrastructure
```

---

## Resource Allocation

### Memory Limits

**Always set memory limits** to prevent one service from consuming all node memory:

```yaml
deploy:
  resources:
    reservations:
      memory: 512M      # Guaranteed minimum
    limits:
      memory: 2G        # Maximum allowed
```

**Guidelines by service type:**

| Service Type | Reservation | Limit | Notes |
|--------------|-------------|-------|-------|
| Static website | 64M | 256M | Nginx, static content |
| API service | 256M | 1G | Node.js, Python APIs |
| Database | 512M | 4G | PostgreSQL, MySQL |
| Heavy processing | 1G | 8G | N8N, document processing |
| Caching | 256M | 1G | Redis, Memcached |

### CPU Limits

Usually **not necessary** unless you need to guarantee resources:

```yaml
deploy:
  resources:
    reservations:
      cpus: '0.5'       # Reserve half a CPU
    limits:
      cpus: '2.0'       # Max 2 CPUs
```

**When to use CPU limits:**
- Multiple CPU-intensive services on same node
- Preventing one service from starving others
- Services with known CPU requirements

---

## Networking Strategy

### Network Selection

**Option 1: Single Overlay Network (Recommended)**

Create one network for all services:

```bash
docker network create --driver overlay --attachable homelab
```

**Advantages:**
- Simplest setup
- Services can communicate easily
- Less network complexity

**Use when:**
- You trust all your services
- Running personal homelab
- Small to medium deployments

**Option 2: Multiple Networks**

Create separate networks for different tiers:

```bash
docker network create --driver overlay frontend
docker network create --driver overlay backend
docker network create --driver overlay data
```

**Advantages:**
- Better security isolation
- Network segmentation
- Fine-grained access control

**Use when:**
- Running untrusted services
- Compliance requirements
- Large production deployments

### Service Discovery

Services automatically discover each other by service name:

```yaml
services:
  web:
    networks:
      - homelab

  api:
    networks:
      - homelab
    environment:
      - DB_HOST=postgres  # Resolves to postgres service
```

### Port Publishing

**Three options:**

1. **Internal only (no ports published)**
```yaml
# Service accessible only within swarm
# Access via Traefik reverse proxy
```

2. **Host mode (specific port on all nodes)**
```yaml
ports:
  - "8080:8080"  # Published on all swarm nodes
```

3. **Ingress mode (load balanced)**
```yaml
ports:
  - target: 80
    published: 8080
    mode: ingress  # Default, load balanced
```

**Best practice:** Use Traefik/reverse proxy for HTTP services, only publish ports for direct access needs.

---

## Storage and Persistence

### Volume Types

**Bind Mounts (Most Common in Homelab):**

```yaml
volumes:
  - /host/path/data:/container/data
  - /host/path/config:/container/config:ro  # Read-only
```

**Advantages:**
- Direct access to data on host
- Easy backups
- Simple path management

**Named Volumes:**

```yaml
volumes:
  - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
    driver: local
```

**Advantages:**
- Docker manages storage
- Portable between environments
- Better for container-first workflow

### Storage Planning Checklist

- [ ] Identify what data needs persistence
- [ ] Choose storage location (which node?)
- [ ] Plan backup strategy
- [ ] Set appropriate permissions
- [ ] Document volume paths
- [ ] Consider storage capacity

**Example directory structure:**

```
/home/doc/swarm-data/appdata/
├── traefik/
│   ├── certificates/
│   └── acme.json
├── authentik/
│   ├── media/
│   └── templates/
├── paperless/
│   ├── data/
│   ├── media/
│   └── consume/
└── portainer/
    └── data/
```

---

## Security Considerations

### Using Secrets

**Never put passwords in compose files.** Use Docker secrets:

```bash
# Create secret from file
echo "my-database-password" | docker secret create db_password -

# Create from existing file
docker secret create ssl_cert ./certificate.pem
```

**Use in compose:**

```yaml
services:
  app:
    secrets:
      - db_password
    environment:
      - DB_PASSWORD_FILE=/run/secrets/db_password

secrets:
  db_password:
    external: true
```

**Access in container:**

```bash
# Secret available at /run/secrets/SECRET_NAME
cat /run/secrets/db_password
```

### Environment Variables

**For non-sensitive config:**

```yaml
environment:
  - TZ=America/New_York
  - LOG_LEVEL=info
  - DOMAIN=example.com
```

**Or use env file:**

```yaml
env_file:
  - .env
```

---

## Deployment Workflow

### Step 1: Create the Compose File

```yaml
version: '3.8'

services:
  myapp:
    image: myapp:latest
    networks:
      - homelab
    environment:
      - TZ=America/New_York
    volumes:
      - /home/doc/swarm-data/appdata/myapp:/data
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.hostname == p0
      resources:
        reservations:
          memory: 256M
        limits:
          memory: 1G
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      rollback_config:
        parallelism: 1
        delay: 5s

networks:
  homelab:
    external: true
```

### Step 2: Pre-Deployment Checks

```bash
# Verify compose syntax
docker compose -f myapp-compose.yml config

# Check if network exists
docker network ls | grep homelab

# Verify storage paths exist
ls -la /home/doc/swarm-data/appdata/myapp

# Check if secrets exist (if needed)
docker secret ls | grep myapp

# Verify node is available
docker node ls
```

### Step 3: Deploy the Stack

```bash
# Deploy stack
docker stack deploy -c myapp-compose.yml myapp

# Watch deployment progress
watch -n 1 'docker service ls | grep myapp'

# Or check specific service
docker service ps myapp_myapp
```

### Step 4: Verify Deployment

```bash
# Check service status
docker service ps myapp_myapp

# Check logs
docker service logs -f myapp_myapp

# Verify replicas are running
docker service ls | grep myapp

# Test connectivity (if web service)
curl http://localhost:PORT
```

### Step 5: Monitor and Adjust

```bash
# Watch logs for errors
docker service logs --tail 100 myapp_myapp | grep -i error

# Check resource usage
docker stats --no-stream | grep myapp

# If issues, check placement
docker service ps myapp_myapp --format "{{.Node}} - {{.CurrentState}}"
```

---

## Common Issues and Solutions

### Issue: Service Won't Start

**Check logs:**
```bash
docker service logs myapp_myapp
```

**Common causes:**
- Missing secrets
- Volume path doesn't exist
- Port already in use
- Memory limit too low
- Image doesn't exist

**Solution:**
```bash
# Create missing directories
mkdir -p /home/doc/swarm-data/appdata/myapp

# Check if port is available
docker service ls | grep PORT_NUMBER

# Increase memory limit
docker service update --limit-memory 2G myapp_myapp
```

### Issue: Service Keeps Restarting

**Check task history:**
```bash
docker service ps --no-trunc myapp_myapp
```

**Common causes:**
- Application crashes immediately
- Health check failing
- Insufficient resources
- Permission issues

**Debug:**
```bash
# Check container directly
docker exec -it $(docker ps -q -f name=myapp) /bin/bash

# Check permissions
ls -la /home/doc/swarm-data/appdata/myapp

# Check available memory on node
docker node inspect NODE_NAME --format '{{.Description.Resources.MemoryBytes}}'
```

### Issue: Can't Connect to Service

**Check network:**
```bash
# Verify service is on correct network
docker service inspect myapp_myapp --format '{{range .Spec.TaskTemplate.Networks}}{{.Target}}{{end}}'

# Test DNS resolution
docker exec -it CONTAINER_ID nslookup OTHER_SERVICE_NAME

# Check if ports are published
docker service inspect myapp_myapp --format '{{range .Endpoint.Ports}}{{.PublishedPort}}:{{.TargetPort}}{{end}}'
```

### Issue: Service Running on Wrong Node

**Update constraints:**
```bash
docker service update \
  --constraint-add 'node.hostname==p0' \
  myapp_myapp
```

### Issue: Out of Memory

**Increase limits:**
```bash
docker service update \
  --limit-memory 4G \
  --reserve-memory 1G \
  myapp_myapp
```

---

## Update and Rollback Workflow

### Performing Updates

**Update image version:**
```bash
# Update to new version
docker service update --image myapp:v2.0 myapp_myapp

# Watch rollout
watch docker service ps myapp_myapp
```

**With zero downtime:**
```yaml
deploy:
  update_config:
    parallelism: 1        # Update one at a time
    delay: 10s            # Wait between updates
    order: start-first    # Start new before stopping old
    failure_action: rollback
```

### Rollback on Failure

**Manual rollback:**
```bash
docker service rollback myapp_myapp
```

**Automatic rollback (in compose):**
```yaml
deploy:
  update_config:
    failure_action: rollback
  rollback_config:
    parallelism: 1
    delay: 5s
```

---

## Best Practices Summary

### DO:
- ✓ Pin critical infrastructure services (Traefik, databases)
- ✓ Set memory limits on all services
- ✓ Use secrets for sensitive data
- ✓ Configure rollback for updates
- ✓ Test in development first
- ✓ Document your compose files
- ✓ Use version control for compose files
- ✓ Monitor logs during deployment
- ✓ Plan storage paths before deploying
- ✓ Label your nodes appropriately

### DON'T:
- ✗ Put passwords in compose files
- ✗ Deploy without memory limits
- ✗ Pin services unnecessarily
- ✗ Forget to create storage directories
- ✗ Deploy without testing compose syntax
- ✗ Update production without rollback config
- ✗ Expose unnecessary ports
- ✗ Run multiple databases on one node without limits
- ✗ Deploy without checking logs

---

## Example: Complete Deployment

Here's a real-world example of deploying Paperless-ngx to my cluster:

**1. Planning:**
- Needs PostgreSQL database
- Requires Redis for caching
- Needs persistent storage for documents
- Should run on manager node (has more storage)
- Requires secrets for database password

**2. Preparation:**

```bash
# Create storage directories
mkdir -p /home/doc/swarm-data/appdata/paperless/{data,media,consume,export}

# Create secrets
echo "secure-db-password" | docker secret create paperless-db-password -
echo "secure-secret-key" | docker secret create paperless-secret-key -

# Verify network exists
docker network ls | grep homelab
```

**3. Compose File:**

```yaml
version: '3.8'

services:
  paperless_webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    networks:
      - homelab
    environment:
      - PAPERLESS_REDIS=redis://paperless_redis:6379
      - PAPERLESS_DBHOST=10.0.4.10
      - PAPERLESS_DBPORT=5432
      - PAPERLESS_DBNAME=paperless
      - PAPERLESS_DBUSER=paperless
      - PAPERLESS_DBPASS_FILE=/run/secrets/paperless-db-password
      - PAPERLESS_SECRET_KEY_FILE=/run/secrets/paperless-secret-key
      - PAPERLESS_OCR_LANGUAGE=eng
      - PAPERLESS_TIME_ZONE=America/New_York
    volumes:
      - /home/doc/swarm-data/appdata/paperless/data:/usr/src/paperless/data
      - /home/doc/swarm-data/appdata/paperless/media:/usr/src/paperless/media
      - /home/doc/swarm-data/appdata/paperless/export:/usr/src/paperless/export
      - /home/doc/swarm-data/appdata/paperless/consume:/usr/src/paperless/consume
    secrets:
      - paperless-db-password
      - paperless-secret-key
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.hostname == p0
      resources:
        reservations:
          memory: 512M
        limits:
          memory: 2G
      update_config:
        parallelism: 1
        delay: 10s
        failure_action: rollback
      rollback_config:
        parallelism: 1

  paperless_redis:
    image: redis:alpine
    networks:
      - homelab
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.hostname == p0
      resources:
        reservations:
          memory: 128M
        limits:
          memory: 512M

networks:
  homelab:
    external: true

secrets:
  paperless-db-password:
    external: true
  paperless-secret-key:
    external: true
```

**4. Deploy:**

```bash
# Validate compose file
docker compose -f paperless-compose.yml config

# Deploy
docker stack deploy -c paperless-compose.yml paperless

# Monitor
watch -n 2 'docker service ps paperless_paperless_webserver'
docker service logs -f paperless_paperless_webserver
```

**5. Verify:**

```bash
# Check status
docker service ls | grep paperless

# Test access
curl http://10.0.4.11:8000

# Check logs for errors
docker service logs paperless_paperless_webserver | grep -i error
```

---

## Workflow Checklist

Use this checklist for every new service deployment:

**Pre-Deployment:**
- [ ] Service requirements documented
- [ ] Node placement decided
- [ ] Resource limits determined
- [ ] Storage paths planned
- [ ] Secrets created (if needed)
- [ ] Network selected
- [ ] Compose file written
- [ ] Compose syntax validated

**Deployment:**
- [ ] Storage directories created
- [ ] Secrets verified
- [ ] Network verified
- [ ] Stack deployed
- [ ] Service status checked
- [ ] Logs monitored
- [ ] Connectivity tested

**Post-Deployment:**
- [ ] Documentation updated
- [ ] Backup strategy implemented
- [ ] Monitoring configured
- [ ] Compose file committed to git
- [ ] Team notified (if applicable)

---

## Related Resources

- [Docker Swarm Command Reference](/homelab/docker-swarm-commands/)
- [Frostlabs v3 Infrastructure](/projects/frostlabs-v3/)
- [Homelab Architecture](/homelab/homelab-infrastructure/)

---

*Last Updated: October 30, 2025*
