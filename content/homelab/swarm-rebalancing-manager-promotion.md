---
title: Rebalancing Docker Swarm - Promoting All Nodes to Managers
date: 2025-10-30T08:45:00Z
tags:
  - docker
  - swarm
  - homelab
  - high-availability
description: How I transformed my Docker Swarm cluster from a single-manager setup to a fully distributed 4-node manager quorum with automatic load balancing.
---

## The Problem

My Docker Swarm cluster had a critical issue - everything was pinned to `p0`. While this worked initially, it created several problems:

- **Single point of failure**: All services running on one node
- **Resource imbalance**: p0 was heavily loaded while p1, p2, p3 sat idle
- **No redundancy**: Losing p0 meant losing everything
- **Memory pressure**: Multiple heavy services competing for resources

## The Solution

### Phase 1: Promote All Nodes to Managers

Originally, only p0 was a manager. I promoted p1, p2, and p3 to managers:

```bash
docker node promote p1 p2 p3
```

This created a **4-node manager quorum**, which can tolerate losing 2 nodes while maintaining cluster operations.

### Phase 2: Verify Shared Storage

Since my cluster uses GlusterFS mounted at `/home/doc/swarm-data/`, I verified all nodes could access the shared storage:

```bash
docker service create --name gluster-test \
  --mode global \
  --constraint 'node.role==manager' \
  --mount type=bind,src=/home/doc/swarm-data,dst=/data \
  alpine ls /data
```

All nodes successfully accessed the shared filesystem.

### Phase 3: Remove Hostname Constraints

I removed unnecessary `node.hostname == p0` constraints from service configurations:

**Services Updated:**
- adminer
- n8n
- paperless (webserver + redis)
- authentik (server, worker, redis)
- uptime-kuma
- tracker-nginx

**Services Left Pinned:**
- `traefik` (p0) - Needs published ports 80/443 with stable IP
- `portainer` (p0) - Management UI convenience
- `rsync` - Already flexible with `node.role == manager`

### Phase 4: Redeploy Services

I force-updated services to redistribute them:

```bash
docker service update --force adminer_adminer
docker service update --force n8n_n8n
docker service update --force authentik_redis
docker service update --force authentik_authentik_server
docker service update --force authentik_authentik_worker
docker service update --force paperless_paperless_redis
```

### Phase 5: Fix Portainer Connectivity

After promoting nodes to managers, Portainer agents couldn't find manager nodes (they cached the old worker role). Fixed by restarting the agents:

```bash
docker service update --force portainer_agent
```

## Results

### Before
```
p0: traefik, portainer, uptime-kuma, adminer, n8n, paperless, authentik (all 3 services)
p1: (mostly idle)
p2: (mostly idle)
p3: (mostly idle)
```

### After
```
p0: traefik, portainer, rsync
p1: authentik_redis, paperless_redis, tracker-nginx
p2: adminer, authentik_server, uptime-kuma
p3: authentik_worker, n8n, paperless_webserver
```

## Benefits Achieved

✅ **Balanced workload** - Services distributed across all 4 nodes
✅ **High availability** - 4-node manager quorum (can lose 2 nodes)
✅ **Self-balancing** - Services automatically redistribute on node failures
✅ **Better resource utilization** - All nodes actively participating

## Lessons Learned

1. **GlusterFS enables true flexibility** - Shared storage means services can run anywhere without storage constraints

2. **Manager overhead is minimal** - With only 4 nodes, the Raft consensus overhead is negligible

3. **Portainer agents cache node roles** - Always restart agents after promoting nodes to managers

4. **Pin only what's necessary** - Only services with published ports or specific requirements need constraints

5. **Let Swarm do its job** - Without constraints, the scheduler does a good job distributing workload

## Related Documentation

- [Docker Swarm Deployment Workflow](../docker-swarm-deployment-workflow)
- [Homelab Infrastructure Overview](../homelab-infrastructure)
- [Docker Swarm Commands Reference](../docker-swarm-commands)
