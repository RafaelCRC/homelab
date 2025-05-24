# Portainer Setup Documentation
Portainer is a docker management tool that helps to visualize and manage stacks, containers, images and network.

## Navigation
* [Apps](/apps/README.md) - List of all the apps and services.
* [Dashboard](/dashboard/README.md) - Dashboards and monitoring tools.
* [__Network__](/network/README.md) - Network scripts and Cloudflare setup.
  - [Adguard Home](/network/adguardHome/README.md) - Adguard DNS Server.
  - [DNSS](/network/dnss/README.md) - Container to update Cloudflare records with public ip.
  - [Nginx Proxy Manager](/network/nginx/README.md) - Nginx proxy manager.
  - [Scripts](/network/scripts/README.md) - Scripts for network and cloudflare.
  - [Wireguard](/network/wireguard/README.md) - Wireguard VPN Server.
* [Home Assistant](/homeassistant/README.md) - Smart home services and automation.
* [Server Monitoring](/monitoring/README.md) - Server Monitoring services.
* [Tools](/tools/README.md) - Tools that makes life easier.
  - [__Portainer__](/tools/portainer/README.md) - Docker management service.


## Overview
This documentation explains how to set up Portainer (main instance) on a Proxmox server and a Portainer Agent on a Raspberry Pi to manage Docker environments remotely.

## Prerequisites
- Docker installed on both machines
- Docker Compose installed (optional, but recommended)
- Network connectivity between the machines

## Portainer Main Instance Setup (Proxmox Server)

### 1. Create data directory
```bash
mkdir -p ./portainer/data
cd ./portainer
```

### 2. Create compose.yml file
Create a file named `compose.yml` with the following content:

```yaml
services:
  portainer:
    container_name: portainer
    image: portainer/portainer-ce:latest
    ports:
      - "9443:9443"
    volumes:
     - ./data:/data
     - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
```

### 3. Start Portainer
```bash
docker compose up -d
```

### 4. Access Portainer
Open a web browser and navigate to:
```
https://<your-proxmox-server-ip>:9443
```

## Portainer Agent Setup (Raspberry Pi)

### 1. Create compose.yml file
Create a file named `compose.yml` with the following content:

```yaml
services:
  portainer-agent:
    container_name: portainer-agent
    image: portainer/agent
    restart: unless-stopped
    ports:
      - "9001:9001" 
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
```

### 2. Start Portainer Agent
```bash
compose up -d
```

## Connecting Agent to Portainer

1. Log in to your Portainer web interface (https://<proxmox-ip>:9443)
2. Go to "Environments" in the left sidebar
3. Click "Add environment"
4. Select "Agent"
5. Enter the following details:
   - Name: (e.g., "Raspberry Pi")
   - Agent URL: `tcp://<raspberry-pi-ip>:9001`
6. Click "Connect"