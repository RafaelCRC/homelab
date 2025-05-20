# Glance Dashboard Documentation
This is a work in progress, check back for more!

## Navigation
* [Apps](/apps/README.md) - List of all the apps and services.
* [Dashboard](/dashboard/README.md) - Dashboards and monitoring tools.
  - [__Glance__](/dashboard/glance/README.md) - Dashboards and monitoring tools.
* [Network](/network/README.md) - Network scripts and Cloudflare setup.
* [Home Assistant](/homeassistant/README.md) - Smart home services and automation.

![alt text](/assets/dashboard/glance.png)

### Overview
Glance is a customizable dashboard for monitoring your homelab services, with support for:
- System monitoring
- Docker container management
- Service health checks
- Custom widgets and integrations

### Prerequisites
- Docker and Docker Compose
- 64MB+ RAM allocation
- Port 8080 available

### Setup Guide

1. **Directory Structure**
```
/glance/
├── compose.yaml
├── .env
├── config/
│   ├── glance.yml
│   ├── fullhomelab.yml
│   └── home.yml
└── assets/
    ├── style.css
    ├── cyber.png
    └── samurai.jpg
```

2. **docker-compose.yml**
```yaml
services:
  glance:
    container_name: glance
    image: glanceapp/glance
    mem_limit: 64m
    memswap_limit: 64m
    restart: unless-stopped
    volumes:
      - ./config:/app/config
      - ./assets:/app/assets
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - 8080:8080
    env_file: .env
```

3. **Configuration Files**

**glance.yml**
```yaml
server:
  assets-path: /app/assets

theme:
  custom-css-file: /assets/style.css

pages:
  !include: fullhomelab.yml
  !include: home.yml

branding:
  logo-url: /assets/cyber.png
  favicon-url: /assets/cyber.png
```

4. **Key Features**
- Two dashboard pages (HomeLab and Home)
- Theme via style.css
- Docker container monitoring
- System resource tracking
- Multiple widget types:
  - Server stats
  - Service monitoring
  - Reddit feeds
  - Weather
  - Financial markets
  - Steam deals

5. **Customization**
- Edit `style.css` for visual changes
- Modify YAML files to:
  - Add/remove widgets
  - Change service endpoints
  - Adjust layout columns
- Replace assets/ images for branding

6. **Deployment**
```bash
mkdir -p glance/{config,assets}
# Add configuration files
docker compose up -d
```

### Maintenance
- Access at: `http://your-server:8080`
- Logs: `docker logs glance`
- Updates: `docker compose pull && docker compose up -d`
