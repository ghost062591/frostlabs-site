---
title: "Docker Swarm Glossary"
date: 2025-10-30T00:00:00Z
tags:
  - docker
  - swarm
  - reference
  - glossary
description: A comprehensive glossary of Docker Swarm terms and definitions for cluster orchestration, services, networking, and more.
categories:
  - homelab
  - reference
---

## Introduction

This glossary covers essential Docker Swarm terminology. Whether you're new to Swarm or need a quick reference, this guide defines the key concepts used in container orchestration.

---

## Core Concepts

### Swarm
A cluster of Docker engines (nodes) running in swarm mode. The swarm provides native clustering, load balancing, and orchestration capabilities. A swarm consists of manager nodes and worker nodes that work together to run containerized services.

### Node
A single Docker engine participating in the swarm. Nodes can be physical machines, virtual machines, or cloud instances. Each node runs the Docker daemon and communicates with other nodes in the swarm.

### Manager Node
A node responsible for cluster management tasks including orchestration, scheduling, and maintaining the desired state of the swarm. Manager nodes implement the Raft consensus algorithm to maintain consistent state across the cluster. They handle API requests and assign tasks to worker nodes.

### Worker Node
A node that executes containers (tasks) assigned by manager nodes. Worker nodes receive and execute tasks but do not participate in cluster management decisions or scheduling. They report their status back to manager nodes.

### Leader
The primary manager node elected through the Raft consensus algorithm. The leader is responsible for orchestration decisions and scheduling. If the leader fails, the remaining managers automatically elect a new leader.

### Quorum
The minimum number of manager nodes that must agree on cluster state changes. Calculated as (N/2)+1, where N is the number of managers. A cluster with 3 managers requires 2 for quorum. Without quorum, the cluster cannot make changes but existing services continue running.

---

## Services and Tasks

### Service
The definition of tasks to execute on nodes. A service specifies which container image to use, how many replicas to run, network and volume configuration, and resource constraints. Services are the primary way to deploy applications in Swarm.

### Task
A single container instance and its configuration. Tasks are atomic scheduling units assigned to nodes by the swarm scheduler. Each task corresponds to one running container. If a task fails, the scheduler creates a new task to maintain the desired state.

### Replica
An instance of a service task. Multiple replicas provide redundancy and load distribution. For example, a service with 3 replicas runs 3 containers across the swarm.

### Global Service
A service that runs exactly one task on every node in the swarm (or subset of nodes matching constraints). Commonly used for monitoring agents, log collectors, or other node-level services. As nodes are added or removed, global services automatically adjust.

### Replicated Service
A service that runs a specified number of replica tasks distributed across the swarm. The default service mode. The scheduler determines which nodes run the replicas based on available resources and constraints.

### Desired State
The intended configuration of a service as defined by the user. The swarm continuously works to reconcile the actual state with the desired state. If a container fails, Swarm creates a replacement to maintain the desired replica count.

### Reconciliation
The process of comparing actual state to desired state and taking corrective action. Swarm continuously monitors services and performs reconciliation to ensure reliability.

---

## Scheduling and Placement

### Scheduler
The component responsible for assigning tasks to nodes. The scheduler considers resource availability, constraints, placement preferences, and spread strategies to make optimal placement decisions.

### Constraint
A hard requirement that determines where tasks can run. Constraints use node attributes to filter eligible nodes. Common constraints include node hostname, labels, role, or platform. Tasks will not run on nodes that don't meet all constraints.

### Placement Preference
A soft guideline for task distribution. Unlike constraints, preferences don't prevent scheduling but influence the scheduler's decisions. Used for spreading tasks across availability zones or resource tiers.

### Node Label
A key-value pair attached to a node for organizing and selecting nodes. Labels are user-defined and commonly used for categorizing nodes by hardware, location, or purpose. Examples: `storage=true`, `gpu=enabled`, `datacenter=us-east`.

### Node Availability
The scheduling state of a node. Three states exist:
- **Active**: Node accepts new tasks
- **Pause**: Node doesn't accept new tasks but existing tasks continue
- **Drain**: Node doesn't accept new tasks and existing tasks are rescheduled elsewhere

### Spread Strategy
The algorithm for distributing tasks across nodes. Swarm automatically spreads replicas across nodes to maximize availability. Additional spread can be configured based on labels or other attributes.

---

## Networking

### Overlay Network
A virtual network spanning multiple Docker hosts in the swarm. Overlay networks use VXLAN encapsulation to enable container-to-container communication across nodes. Traffic is encrypted by default in swarm mode.

### Ingress Network
The default overlay network created automatically for swarm routing mesh. Handles inbound connections to published service ports. Traffic to any node's published port is routed to a service task.

### Service Discovery
The mechanism that allows services to find and communicate with each other by name. Swarm's built-in DNS server resolves service names to IP addresses. Services can connect to each other using the service name as the hostname.

### Routing Mesh
The ingress network routing system that load balances published ports across all nodes. External requests to any node's published port are distributed to available service tasks, regardless of which node actually runs the task.

### Virtual IP (VIP)
The IP address assigned to a service for internal load balancing. Services are accessible via their VIP, which load balances traffic across all healthy tasks. The VIP remains stable even as tasks are created or destroyed.

### DNS Round Robin (DNSRR)
An alternative to VIP load balancing. DNS queries for the service name return IP addresses of all healthy tasks. The client is responsible for selecting and connecting to a specific IP. Used when VIP mode is disabled.

### Published Port
A port exposed on all swarm nodes for external access. Traffic to the published port is routed through the ingress network to service tasks.

### Ingress Mode
The default port publishing mode. Published ports are available on all nodes and load balanced across service tasks via the routing mesh.

### Host Mode
A port publishing mode where the port is only available on nodes actually running service tasks. No routing mesh or load balancing is applied. Used for specific networking scenarios.

---

## Storage

### Volume
A persistent data storage mechanism for containers. Volumes exist outside the container lifecycle and can be shared between containers. Data persists even when containers are destroyed.

### Bind Mount
A direct mapping of a host filesystem path into a container. Changes on the host are immediately visible in the container and vice versa. Commonly used for accessing host data or configuration files.

### Named Volume
A volume created and managed by Docker with a user-assigned name. Docker handles storage location and lifecycle. Named volumes are portable and can be backed up or moved between hosts.

### tmpfs Mount
An ephemeral mount stored in host memory rather than disk. Data is fast to access but doesn't persist when the container stops. Used for temporary data, caches, or sensitive information that shouldn't be written to disk.

### Volume Driver
A plugin that enables volumes to be stored on external systems. Examples include NFS, cloud storage providers, or distributed filesystems. Allows shared storage across swarm nodes.

---

## Updates and Rollbacks

### Rolling Update
The process of updating service tasks gradually rather than all at once. Tasks are updated in batches (controlled by parallelism) with delays between batches. Ensures service availability during updates.

### Update Parallelism
The number of tasks updated simultaneously during a rolling update. Setting parallelism to 1 updates one task at a time. Higher values speed up updates but may impact service capacity.

### Update Delay
The time to wait between updating task batches. Allows time to verify successful updates before proceeding. Helps detect issues early in the update process.

### Update Order
The sequence for stopping old tasks and starting new ones. Two options:
- **stop-first**: Stop the old task before starting the new one (default)
- **start-first**: Start the new task before stopping the old one (requires extra capacity)

### Failure Action
The action taken when a task update fails. Options include:
- **pause**: Stop the update process (default)
- **continue**: Continue updating remaining tasks
- **rollback**: Automatically revert to the previous version

### Rollback
The process of reverting a service to its previous configuration. Can be triggered manually or automatically when updates fail. Rollback uses the same mechanisms as updates (parallelism, delay, order).

### Health Check
A test performed on containers to determine if they're functioning correctly. Failed health checks trigger task rescheduling. Health checks can test HTTP endpoints, TCP connections, or execute commands in the container.

---

## Security

### Secret
Encrypted data stored in the swarm and only accessible to services that have been granted access. Secrets are stored in the Raft log and transmitted securely to containers. Used for sensitive data like passwords, API keys, or certificates.

### Config
Non-sensitive configuration data stored in the swarm and made available to services. Similar to secrets but not encrypted. Used for application configuration files that need to be shared across services.

### TLS
Transport Layer Security encryption used for all swarm communications. Manager-to-manager, manager-to-worker, and worker-to-worker traffic is automatically encrypted using mutual TLS.

### Mutual TLS (mTLS)
A form of authentication where both client and server verify each other's identity using certificates. All swarm nodes use mTLS for secure communication and authentication.

### Raft
The consensus algorithm used by manager nodes to maintain consistent cluster state. Raft ensures all managers agree on the cluster state even when some managers fail or network partitions occur.

### Certificate Authority (CA)
The entity that issues TLS certificates for swarm nodes. Swarm includes a built-in CA that automatically generates and rotates certificates for nodes.

### Join Token
A secret token used to authenticate new nodes joining the swarm. Separate tokens exist for manager and worker nodes. Tokens include the CA's root certificate hash for security.

---

## Stack Management

### Stack
A collection of related services defined in a Compose file and deployed together. Stacks provide a convenient way to manage multi-service applications. All services in a stack share a common namespace.

### Compose File
A YAML file defining services, networks, volumes, configs, and secrets for a stack. Uses Docker Compose specification format. Compose files are version controlled and form the infrastructure-as-code for deployments.

### Stack Namespace
An isolated naming context for stack resources. Service names in a stack are prefixed with the stack name. For example, the `web` service in the `myapp` stack becomes `myapp_web`.

---

## Load Balancing

### Load Balancer
A component that distributes traffic across multiple service tasks. Swarm includes built-in load balancing via VIP and the routing mesh. External load balancers (like Traefik) provide additional features.

### Internal Load Balancer
The VIP-based load balancing for service-to-service communication within the swarm. Traffic to a service's VIP is automatically distributed across healthy tasks.

### External Load Balancer
A reverse proxy or load balancer that handles traffic from outside the swarm. Examples include Traefik, Nginx, or HAProxy. Often used for HTTP routing, SSL termination, or advanced routing rules.

### Session Affinity
The practice of routing requests from the same client to the same backend task. Also called "sticky sessions." Swarm doesn't provide built-in session affinity; external load balancers can implement this.

---

## High Availability

### Fault Tolerance
The ability of the swarm to continue operating when components fail. Swarm provides fault tolerance through manager replication, task rescheduling, and automatic failover.

### Split Brain
A scenario where network partitions cause separate groups of managers to make independent decisions. Raft's quorum requirement prevents split brain by ensuring only one group can make changes.

### Failover
The automatic process of replacing failed tasks or managers with new instances. Worker failover reschedules tasks. Manager failover elects a new leader if the current leader fails.

### Replication
Running multiple copies of managers or service tasks for redundancy. Manager replication provides cluster management resilience. Service replication provides application availability.

---

## Resource Management

### Resource Reservation
The amount of CPU or memory guaranteed to a task. Reserved resources are unavailable to other tasks. Ensures minimum resources for critical services.

### Resource Limit
The maximum CPU or memory a task can consume. Prevents tasks from consuming excessive resources and impacting other workloads. Tasks are throttled or killed if they exceed limits.

### CPU Shares
A relative weight for CPU allocation when multiple tasks compete for CPU. Higher shares receive more CPU time during contention. Doesn't limit CPU when resources are available.

### Memory Reservation
A soft memory limit indicating the minimum memory desired. Doesn't prevent a task from using more memory but influences scheduler placement.

### Memory Limit
A hard memory cap. If a task exceeds its memory limit, the kernel terminates it with an out-of-memory error.

---

## Advanced Concepts

### Raft Log
The replicated log used by manager nodes to store cluster state. All cluster changes are written to the Raft log and replicated across managers. Provides crash recovery and consistency.

### Gossip Protocol
The peer-to-peer communication protocol used by nodes to share information about cluster state. Provides efficient information dissemination and failure detection without central coordination.

### Heartbeat
A periodic message sent between nodes to detect failures. Worker nodes send heartbeats to managers. Managers send heartbeats to each other. Missing heartbeats trigger failure detection.

### Task Slot
A position in a service's task array. For a service with 5 replicas, there are 5 slots numbered 1-5. Each slot contains the current task and its history. Slots remain constant even as tasks are replaced.

### Pending State
A task state indicating the scheduler hasn't yet assigned it to a node. Tasks remain pending when no node meets resource requirements or constraints. Indicates scheduling problems.

### Running State
A task state indicating the container is running on a node. The desired state for tasks. Tasks remain running until the service is scaled down, updated, or fails.

### Shutdown State
A task state indicating the container has stopped. Tasks enter shutdown when intentionally stopped, replaced during updates, or when nodes are drained.

### Attachable Network
An overlay network that standalone containers (not part of services) can attach to. Allows mixing swarm services with standalone containers on the same network. Useful for management or debugging containers.

---

## Operations

### Drain
Gracefully removing all tasks from a node. Tasks are rescheduled to other nodes. Used for node maintenance or decommissioning. The node remains in the swarm but doesn't run new tasks.

### Promote
Converting a worker node to a manager node. Promoted nodes participate in Raft consensus and can handle orchestration tasks. Used to increase manager count for fault tolerance.

### Demote
Converting a manager node to a worker node. Demoted nodes no longer participate in cluster management. Used to reduce manager count or reallocate resources.

### Scale
Changing the number of replica tasks for a service. Scaling up creates additional tasks. Scaling down removes tasks. Swarm ensures the new replica count is maintained.

### Force Update
Recreating all service tasks even when the configuration hasn't changed. Used to pull new images, redistribute tasks, or recover from issues. All tasks are replaced using the service's update configuration.

---

## Related Resources

- [Docker Swarm Command Reference](/homelab/docker-swarm-commands/)
- [Docker Swarm Deployment Workflow](/homelab/docker-swarm-deployment-workflow/)
- [Frostlabs v3 Infrastructure](/projects/frostlabs-v3/)

---

*Last Updated: October 30, 2025*
