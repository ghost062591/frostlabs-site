---
title: The Homelab Journey
date: 2025-10-18T23:41:45Z
draft: true
tags:
  - docker
  - homelab
description: Personal story of homelabbing.
categories:
  - homelab
---

# The Homelab Journey

## Overview

Learning homelabbing on my own has been a wild ride filled with challenges and triumphs. Starting out, I had basic Docker knowledge, but as my setup grew more complex, managing multiple individual machines running Docker became tedious. This led me down the path of setting up and struggling with Docker Swarm. Over weeks of research, testing, and failing, I finally achieved a functional production Docker Swarm deployment.

---
#### The Early Days

I began by building a 4-node cluster using a Beelink manager and three Raspberry Pi workers. Initially, my understanding of Docker Swarm was limited to basic concepts like overlay networks and placement constraints. However, managing four separate Docker hosts became cumbersome, leading me to break down the swarm and revert to individual hosts.

---

#### The Foundation Era (September-Early October)

To streamline management, I set up a Traefik reverse proxy with Cloudflare SSL automation, ensuring all services had secure access points. I also deployed essential core services like PostgreSQL 17 for database management and Portainer as the central management UI. Basic apps such as Wiki.js provided documentation and Uptime Kuma monitoring helped me keep an eye on system health.

To enhance security, I integrated an Authentik Single Sign-On (SSO) stack, ensuring a seamless authentication experience across all services.

---

#### Adding p4 as the 5th Node

I added a fifth node to expand my cluster. This required Docker Engine upgrades from version 28.4.0 to 28.5.1 for compatibility and stability.

The media revolution began with the integration of a complete *arr automation stack, which included Sonarr, Radarr, Prowlarr, SABnzbd, and Emby. This allowed me to automate my media library management effectively.

For AI experiments, I integrated Ollama and OpenWebUI, enabling local language model inference.

Over time, the number of services grew from 16 to 21 and then stabilized at 20 across four nodes. Each service was meticulously placed and configured for optimal performance.

---

#### The Known Parts

My setup now includes a multi-architecture cluster with an x86_64 manager and ARM workers. I’ve set up production networking with overlay networks, ingress mesh, and SSL automation to ensure secure and efficient communication between services.

Proper orchestration is achieved through placement constraints, resource limits, and health checks. Secrets management for cloud tokens and database credentials ensures security without compromising functionality.

---

#### DevOps Excellence

To maintain consistency and ease of management, I keep all configurations in a version-controlled directory named `/mnt/docker-configs/`. Stacks are well-structured to ensure each service is self-contained and easy to manage individually.

Portainer serves as the central management UI for monitoring and managing the entire infrastructure. Detailed documentation and blog posts provide insights into setup and configuration.

---

#### Current State: Production-Grade Homelab

Today, my homelab consists of a 5-node cluster with 20 services across 16 stacks. The setup is highly available, ensuring all critical services like Sonarr, Radarr, Prowlarr, SABnzbd, and Emby are always online and purpose-driven.

---

#### What This Journey Represents

This journey has taken me from a beginner to a Docker Swarm expert. I’ve evolved from managing single containers to orchestrating a robust infrastructure. The transition from manual deployments to stack-based automation has been profound.

The architecture has transformed from monolithic thinking to microservices, allowing for more scalable and maintainable solutions. Real-world impact includes self-hosting everything, reducing SaaS dependencies, and achieving set-and-forget media management with robust AI integration.

---

#### Conclusion

This journey has been a testament to perseverance and continuous learning. I encourage others facing similar challenges to not give up and seek out resources like documentation, forums, and community support.