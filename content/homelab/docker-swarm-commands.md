---
title: "Docker Swarm Command Reference"
date: 2025-10-30T00:00:00Z
tags:
  - docker
  - swarm
  - reference
  - commands
description: A comprehensive reference guide for Docker Swarm commands covering cluster management, services, nodes, stacks, and troubleshooting.
categories:
  - homelab
  - reference
---

## Introduction

This is a practical command reference for managing Docker Swarm clusters. These are the commands I use regularly for managing my 4-node Frostlabs homelab cluster.

---

## Cluster Management

### Initialize a Swarm

```bash
# Initialize swarm on manager node
docker swarm init --advertise-addr <MANAGER-IP>

# Initialize with specific subnet
docker swarm init --advertise-addr <MANAGER-IP> --default-addr-pool 10.0.0.0/8
```

### Join Nodes to Swarm

```bash
# Get join token for workers
docker swarm join-token worker

# Get join token for managers
docker swarm join-token manager

# Join as worker (run on worker node)
docker swarm join --token <TOKEN> <MANAGER-IP>:2377

# Join as manager (run on manager node)
docker swarm join --token <TOKEN> <MANAGER-IP>:2377
```

### Leave Swarm

```bash
# Leave swarm (run on node leaving)
docker swarm leave

# Force leave (if manager)
docker swarm leave --force

# Remove node from swarm (run on manager)
docker node rm <NODE-ID>

# Force remove node
docker node rm --force <NODE-ID>
```

### Swarm Info

```bash
# View swarm details
docker info | grep Swarm -A 20

# Check if swarm is active
docker info | grep "Swarm: active"
```

---

## Node Management

### List Nodes

```bash
# List all nodes in swarm
docker node ls

# List with specific format
docker node ls --format "table {{.ID}}\t{{.Hostname}}\t{{.Status}}\t{{.Availability}}\t{{.ManagerStatus}}"
```

### Inspect Nodes

```bash
# Inspect specific node
docker node inspect <NODE-NAME>

# Pretty print node details
docker node inspect --pretty <NODE-NAME>

# Get node IP
docker node inspect <NODE-NAME> --format '{{ .Status.Addr }}'
```

### Node Availability

```bash
# Drain node (stop scheduling new tasks)
docker node update --availability drain <NODE-NAME>

# Make node active
docker node update --availability active <NODE-NAME>

# Pause node (keep running tasks, no new tasks)
docker node update --availability pause <NODE-NAME>
```

### Node Labels

```bash
# Add label to node
docker node update --label-add <KEY>=<VALUE> <NODE-NAME>

# Remove label from node
docker node update --label-rm <KEY> <NODE-NAME>

# Example: Label for GPU nodes
docker node update --label-add gpu=true p0

# Example: Label for storage nodes
docker node update --label-add storage=true p1
```

### Promote/Demote Nodes

```bash
# Promote worker to manager
docker node promote <NODE-NAME>

# Demote manager to worker
docker node demote <NODE-NAME>
```

---

## Service Management

### Create Services

```bash
# Create simple service
docker service create --name <SERVICE-NAME> <IMAGE>

# Create with replicas
docker service create --name web --replicas 3 nginx:latest

# Create with port mapping
docker service create --name web -p 80:80 nginx:latest

# Create with constraints (specific node)
docker service create --name app \
  --constraint 'node.hostname==p0' \
  myapp:latest

# Create with resource limits
docker service create --name app \
  --reserve-memory 512M \
  --limit-memory 1G \
  myapp:latest

# Create with environment variables
docker service create --name app \
  --env KEY=value \
  --env-file .env \
  myapp:latest

# Create with volume mount
docker service create --name app \
  --mount type=bind,source=/host/path,target=/container/path \
  myapp:latest

# Create with network
docker service create --name app \
  --network homelab \
  myapp:latest

# Create with secrets
docker service create --name app \
  --secret my-secret \
  myapp:latest
```

### List Services

```bash
# List all services
docker service ls

# List services with filter
docker service ls --filter name=web

# Show services in specific format
docker service ls --format "table {{.ID}}\t{{.Name}}\t{{.Replicas}}\t{{.Image}}"
```

### Inspect Services

```bash
# Inspect service
docker service inspect <SERVICE-NAME>

# Pretty print
docker service inspect --pretty <SERVICE-NAME>

# Get specific field
docker service inspect <SERVICE-NAME> --format '{{.Spec.TaskTemplate.ContainerSpec.Image}}'
```

### Update Services

```bash
# Update service image
docker service update --image nginx:alpine <SERVICE-NAME>

# Scale service
docker service scale <SERVICE-NAME>=5

# Update environment variable
docker service update --env-add NEW_VAR=value <SERVICE-NAME>

# Update resource limits
docker service update --limit-memory 2G <SERVICE-NAME>

# Force update (recreate containers)
docker service update --force <SERVICE-NAME>

# Update with rollback on failure
docker service update --update-failure-action rollback <SERVICE-NAME>

# Update with parallelism
docker service update --update-parallelism 2 <SERVICE-NAME>
```

### Remove Services

```bash
# Remove service
docker service rm <SERVICE-NAME>

# Remove multiple services
docker service rm service1 service2 service3
```

### Service Logs

```bash
# View service logs
docker service logs <SERVICE-NAME>

# Follow logs
docker service logs -f <SERVICE-NAME>

# Show last N lines
docker service logs --tail 100 <SERVICE-NAME>

# Show timestamps
docker service logs -t <SERVICE-NAME>

# Logs from specific task
docker service logs <SERVICE-NAME>.<TASK-ID>
```

### Service Tasks

```bash
# List tasks for service
docker service ps <SERVICE-NAME>

# Show all tasks (including stopped)
docker service ps --no-trunc <SERVICE-NAME>

# Filter failed tasks
docker service ps --filter "desired-state=shutdown" <SERVICE-NAME>
```

---

## Stack Management

### Deploy Stacks

```bash
# Deploy stack from compose file
docker stack deploy -c docker-compose.yml <STACK-NAME>

# Deploy with multiple compose files
docker stack deploy -c docker-compose.yml -c docker-compose.prod.yml <STACK-NAME>

# Deploy with environment file
docker stack deploy --env-file .env -c docker-compose.yml <STACK-NAME>
```

### List Stacks

```bash
# List all stacks
docker stack ls

# Show stack services
docker stack services <STACK-NAME>

# Show stack tasks
docker stack ps <STACK-NAME>

# Show only running tasks
docker stack ps --filter "desired-state=running" <STACK-NAME>
```

### Remove Stacks

```bash
# Remove stack
docker stack rm <STACK-NAME>

# Remove multiple stacks
docker stack rm stack1 stack2 stack3
```

---

## Network Management

### List Networks

```bash
# List all networks
docker network ls

# List overlay networks only
docker network ls --filter driver=overlay

# List with specific format
docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}"
```

### Create Networks

```bash
# Create overlay network
docker network create --driver overlay <NETWORK-NAME>

# Create with subnet
docker network create --driver overlay \
  --subnet 10.10.0.0/16 \
  <NETWORK-NAME>

# Create attachable network (for standalone containers)
docker network create --driver overlay \
  --attachable \
  <NETWORK-NAME>

# Create encrypted overlay network
docker network create --driver overlay \
  --opt encrypted \
  <NETWORK-NAME>
```

### Inspect Networks

```bash
# Inspect network
docker network inspect <NETWORK-NAME>

# Get network subnet
docker network inspect <NETWORK-NAME> --format '{{range .IPAM.Config}}{{.Subnet}}{{end}}'
```

### Remove Networks

```bash
# Remove network
docker network rm <NETWORK-NAME>

# Remove unused networks
docker network prune

# Force remove (with confirmation skip)
docker network prune -f
```

---

## Volume Management

```bash
# List volumes
docker volume ls

# Create volume
docker volume create <VOLUME-NAME>

# Inspect volume
docker volume inspect <VOLUME-NAME>

# Remove volume
docker volume rm <VOLUME-NAME>

# Remove unused volumes
docker volume prune

# Remove all unused volumes (force)
docker volume prune -f
```

---

## Secret Management

### Create Secrets

```bash
# Create secret from stdin
echo "my-secret-value" | docker secret create <SECRET-NAME> -

# Create secret from file
docker secret create <SECRET-NAME> /path/to/secret.txt

# Create from command output
cat ~/.ssh/id_rsa | docker secret create ssh-key -
```

### List Secrets

```bash
# List all secrets
docker secret ls

# List with format
docker secret ls --format "table {{.ID}}\t{{.Name}}\t{{.CreatedAt}}"
```

### Inspect Secrets

```bash
# Inspect secret (no data shown for security)
docker secret inspect <SECRET-NAME>

# Pretty print
docker secret inspect --pretty <SECRET-NAME>
```

### Remove Secrets

```bash
# Remove secret
docker secret rm <SECRET-NAME>

# Note: Cannot remove secrets in use by services
```

---

## Config Management

### Create Configs

```bash
# Create config from file
docker config create <CONFIG-NAME> /path/to/config.conf

# Create from stdin
cat nginx.conf | docker config create nginx-config -
```

### List Configs

```bash
# List all configs
docker config ls

# Format output
docker config ls --format "table {{.ID}}\t{{.Name}}\t{{.CreatedAt}}"
```

### Inspect Configs

```bash
# Inspect config
docker config inspect <CONFIG-NAME>

# Pretty print
docker config inspect --pretty <CONFIG-NAME>

# View config data
docker config inspect <CONFIG-NAME> --format '{{.Spec.Data}}' | base64 -d
```

### Remove Configs

```bash
# Remove config
docker config rm <CONFIG-NAME>
```

---

## Troubleshooting Commands

### Check Service Health

```bash
# Check service status
docker service ps <SERVICE-NAME>

# Check logs for errors
docker service logs <SERVICE-NAME> | grep -i error

# Inspect service for issues
docker service inspect <SERVICE-NAME>

# Check node where task is running
docker service ps <SERVICE-NAME> --format "{{.Node}}"
```

### Debug Container Issues

```bash
# Get container ID from service task
docker ps --filter "label=com.docker.swarm.service.name=<SERVICE-NAME>"

# Execute command in service container
docker exec -it <CONTAINER-ID> /bin/bash

# Check container logs directly
docker logs <CONTAINER-ID>
```

### Network Debugging

```bash
# Test connectivity between services
docker exec <CONTAINER-ID> ping <OTHER-SERVICE-NAME>

# Check DNS resolution
docker exec <CONTAINER-ID> nslookup <SERVICE-NAME>

# View network connections
docker exec <CONTAINER-ID> netstat -tulpn
```

### Resource Usage

```bash
# Check node resource usage
docker node ps <NODE-NAME>

# Check service resource usage (requires stats)
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
```

### View Events

```bash
# Real-time swarm events
docker events

# Filter events by type
docker events --filter type=service

# Filter events by service
docker events --filter service=<SERVICE-NAME>
```

---

## Maintenance Commands

### System Cleanup

```bash
# Remove unused containers, networks, images, volumes
docker system prune

# Force cleanup without confirmation
docker system prune -f

# Include volumes in cleanup
docker system prune --volumes

# Remove all unused images
docker image prune -a
```

### Update All Services

```bash
# Force update all services (recreate containers)
docker service ls --quiet | xargs -I {} docker service update --force {}

# Update specific stack services
docker stack services <STACK-NAME> --quiet | xargs -I {} docker service update --force {}
```

### Backup and Restore

```bash
# Backup swarm certificates (run on manager)
sudo tar czf swarm-backup.tar.gz /var/lib/docker/swarm

# List all compose files for stack backup
docker stack ls --format "{{.Name}}"

# Export service configurations
docker service inspect <SERVICE-NAME> > service-backup.json
```

---

## Useful Filters and Formats

### Common Filters

```bash
# Filter by node
--filter node=<NODE-NAME>

# Filter by name
--filter name=<PATTERN>

# Filter by label
--filter label=<KEY>=<VALUE>

# Filter by desired state
--filter desired-state=running
--filter desired-state=shutdown
```

### Format Output

```bash
# Table format
--format "table {{.ID}}\t{{.Name}}\t{{.Status}}"

# JSON format
--format "{{json .}}"

# Specific field
--format "{{.ID}}"

# Multiple fields
--format "{{.Name}} - {{.Image}} - {{.Replicas}}"
```

---

## Quick Reference Examples

### Deploy a complete stack

```bash
cd ~/swarm/production
docker stack deploy -c traefik-compose.yml traefik
docker stack deploy -c authentik-compose.yml authentik
docker stack deploy -c portainer-compose.yml portainer
```

### Scale services quickly

```bash
docker service scale web=5 api=3 worker=10
```

### Rolling update with zero downtime

```bash
docker service update \
  --image myapp:v2 \
  --update-parallelism 1 \
  --update-delay 10s \
  --update-failure-action rollback \
  myapp
```

### Check cluster health

```bash
docker node ls
docker service ls
docker stack ps $(docker stack ls --format "{{.Name}}")
```

---

## Tips and Best Practices

1. **Always use labels** - Label your nodes for easier service placement
2. **Pin critical services** - Use constraints to keep important services on specific nodes
3. **Use secrets** - Never put passwords in compose files
4. **Enable rollback** - Always configure rollback on failure for updates
5. **Monitor logs** - Use `docker service logs -f` during deployments
6. **Test updates in dev** - Deploy to development stack first
7. **Use health checks** - Define health checks in your compose files
8. **Document your stacks** - Keep compose files in version control

---

## Related Resources

- [Docker Swarm Official Docs](https://docs.docker.com/engine/swarm/)
- [Frostlabs v3 Infrastructure](/projects/frostlabs-v3/)
- [Homelab Infrastructure Overview](/homelab/homelab-infrastructure/)

---

*Last Updated: October 30, 2025*
