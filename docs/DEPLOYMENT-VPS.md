# VPS + Coolify Deployment Guide

## One-Time VPS Setup

### 1. Purchase VPS

Recommended: **Hostinger KVM 2** (~$7–10/month)
- 2 vCPU, 8GB RAM, 100GB NVMe
- Select **"Ubuntu 24.04 with Coolify"** during onboarding

### 2. Access Coolify

After VPS provisioning:
```
http://{your-vps-ip}:8000
```

1. Create an admin account on first access
2. Select "localhost" during onboarding (deploy to same server)

### 3. Configure Wildcard Domain

In your DNS provider, add an A record:
```
*.mcp.yourdomain.com  →  {your-vps-ip}
```

In Coolify, configure the domain and enable auto SSL (Let's Encrypt).

### 4. Connect GitHub

In Coolify dashboard:
1. Settings → Sources → Add GitHub App
2. Follow the OAuth flow to connect your GitHub account
3. This enables auto-deploy on git push

### 5. Install Hostinger MCP Server (Optional)

For AI agent management of your VPS:
```bash
npm install -g hostinger-api-mcp
```

## Deploy a New MCP

### Option A: Via Coolify Dashboard

1. Push your MCP code to a GitHub repository
2. In Coolify: New Resource → Docker Compose
3. Select your GitHub repo
4. Set the base directory (if using monorepo)
5. Add environment variables in the Coolify UI
6. Set domain: `{mcp-name}.mcp.yourdomain.com`
7. Click Deploy

### Option B: Via Docker Compose Directly (SSH)

```bash
ssh root@{your-vps-ip}

# Clone your MCP
git clone https://github.com/you/your-mcp.git
cd your-mcp

# Configure
cp .env.example .env
nano .env  # Set your values

# Deploy
docker compose up -d --build
```

### Option C: Coolify API (Automation)

Coolify exposes a REST API for programmatic deployments. See Coolify docs for API reference.

## Environment Variables

Set environment variables in the Coolify UI for each service, or use `.env` files:

```bash
# Required
MCP_NAME=Your MCP Name
PORT=8000

# Auth (if applicable)
MCP_API_KEYS=key1,key2
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_JWT_SECRET=your-secret
SUPABASE_SERVICE_ROLE_KEY=your-key

# Database (if applicable)
DATABASE_URL=postgresql://user:pass@db:5432/mcpdata
```

## Custom Domain Per MCP

Each MCP gets its own subdomain via Coolify's Traefik reverse proxy:

```
bug-tracker.mcp.yourdomain.com     → container port 8000
virtual-tables.mcp.yourdomain.com  → container port 8000
```

Coolify handles SSL certificates automatically via Let's Encrypt.

## Updating a Deployed MCP

**With GitHub integration:** Just push to the connected branch. Coolify auto-deploys.

**Without GitHub integration:**
```bash
ssh root@{your-vps-ip}
cd /path/to/your-mcp
git pull
docker compose up -d --build
```

## Monitoring

### Container Logs
```bash
# Via Coolify dashboard: Click service → Logs tab

# Via SSH
docker logs {container-name} -f
```

### Health Checks

All MCP templates include Docker health checks. View status:
```bash
docker ps  # HEALTH column shows status
```

### Resource Usage
```bash
docker stats  # Real-time CPU/memory per container
```

## Scaling

**Vertical (same VPS):** Most MCPs use minimal resources. A KVM 2 VPS can easily run 20+ lightweight MCP containers.

**Horizontal (multiple VPS):** If you outgrow one VPS, deploy a second one and split MCPs between them.

**Upgrade path:**
| Plan | vCPU | RAM | Storage | Containers |
|------|------|-----|---------|------------|
| KVM 2 | 2 | 8 GB | 100 GB | ~20-30 MCPs |
| KVM 4 | 4 | 16 GB | 200 GB | ~50-80 MCPs |
| KVM 8 | 8 | 32 GB | 400 GB | ~100+ MCPs |

## Troubleshooting

**Container won't start:** Check logs with `docker logs {container-name}`

**Port conflict:** Each MCP uses port 8000 internally but Traefik routes by domain. No port conflicts.

**Out of memory:** Check `docker stats`. Reduce container count or upgrade VPS.

**SSL not working:** Ensure DNS wildcard record is correct. Check Coolify's Traefik logs.
