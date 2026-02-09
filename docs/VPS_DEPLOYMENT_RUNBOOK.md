# VPS Deployment Runbook — Private Registry + Coolify API

This document captures the exact manual process used to deploy MCP servers to the VPS
using a private Docker registry and the Coolify REST API. This is the reference for
building the automated `deploy-vps.sh` script.

---

## Architecture Overview

```
Local Machine                  VPS (191.101.15.190)
┌──────────────┐               ┌─────────────────────────────────────┐
│ MCP source   │──rsync/scp──▶│ /opt/mcps/<slug>/                   │
│ code         │               │                                     │
└──────────────┘               │ docker build ──▶ localhost:5000      │
                               │ (private registry)                  │
                               │                                     │
                               │ Coolify API ──▶ creates app          │
                               │   ├── pulls from localhost:5000      │
                               │   ├── assigns domain + HTTPS         │
                               │   └── manages via Traefik            │
                               └─────────────────────────────────────┘
```

**Flow:**
1. Copy MCP project files to VPS
2. Build Docker image on VPS
3. Tag and push to private registry (`localhost:5000`)
4. Create Coolify application via API (first deploy) or restart (subsequent deploys)
5. Coolify pulls image from registry, starts container, provisions HTTPS via Traefik

---

## Prerequisites

### One-Time Setup (Already Done)

| Component | Status | Details |
|-----------|--------|---------|
| VPS | Running | Hostinger KVM at `191.101.15.190` |
| Coolify | Running | `http://191.101.15.190:8000` (or `https://coolify.mcp.aimatrx.com`) |
| Docker Registry | Running | Coolify service UUID `l044ccwcg8484g8gcgww4kkk`, accessible at `localhost:5000` on VPS |
| Wildcard DNS | Configured | `*.mcp.aimatrx.com` → `191.101.15.190` |
| SSH Access | Configured | `ssh root@191.101.15.190` |

### Required Credentials

```bash
# SSH
VPS_IP=191.101.15.190
VPS_USER=root

# Coolify API
COOLIFY_URL=http://191.101.15.190:8000
COOLIFY_API_TOKEN="4|GwGrL8wLqUGdtUCiFJGfIVyxibPaO9AibkRz08umb1924af1"

# Coolify Project (MCP Factory)
COOLIFY_PROJECT_UUID=hcw40ckwss4gkgwkckc004wc
COOLIFY_SERVER_UUID=sggkws4cgwoo0kckk4oogcss
COOLIFY_ENVIRONMENT=production

# Docker Registry (on VPS only — not publicly exposed)
REGISTRY_HOST=localhost:5000
REGISTRY_USER=fi0fYTPXqNQJVaIm
REGISTRY_PASS=pWA7R813XUDTt8AStO2xm99QBZgndLgh
```

---

## Step-by-Step: First Deployment

### Step 1: Copy Project Files to VPS

```bash
# From your local machine
MCP_SLUG="your-mcp-name"
LOCAL_PATH="./mcps/${MCP_SLUG}"

# Create directory on VPS and copy files
ssh root@191.101.15.190 "mkdir -p /opt/mcps/${MCP_SLUG}"
rsync -avz --exclude='node_modules' --exclude='.venv' --exclude='__pycache__' \
  "${LOCAL_PATH}/" "root@191.101.15.190:/opt/mcps/${MCP_SLUG}/"
```

### Step 2: Build Docker Image on VPS

```bash
ssh root@191.101.15.190 << EOF
  cd /opt/mcps/${MCP_SLUG}
  docker build -t localhost:5000/${MCP_SLUG}:latest .
EOF
```

**What happens:** Docker reads the `Dockerfile` in the project root and builds the image.
- Python-VPS: Uses `python:3.12-slim`, installs from `requirements.txt`, sets `PYTHONPATH=/app/src`
- TypeScript-VPS: Multi-stage build with `node:22-slim`, runs `npm ci && npm run build`

### Step 3: Push to Private Registry

```bash
ssh root@191.101.15.190 << EOF
  docker login localhost:5000 -u fi0fYTPXqNQJVaIm -p pWA7R813XUDTt8AStO2xm99QBZgndLgh
  docker push localhost:5000/${MCP_SLUG}:latest
EOF
```

**Why a registry?** Coolify manages containers declaratively. It needs to pull images from a
registry — it can't use images in the local Docker store. `localhost:5000` is only accessible
on the VPS itself (port bound to `127.0.0.1`), so no security exposure.

### Step 4: Create Coolify Application

```bash
MCP_SLUG="your-mcp-name"
MCP_DOMAIN="https://${MCP_SLUG}.mcp.aimatrx.com"
COOLIFY_TOKEN="4|GwGrL8wLqUGdtUCiFJGfIVyxibPaO9AibkRz08umb1924af1"
COOLIFY_URL="http://191.101.15.190:8000"

curl -s -X POST \
  -H "Authorization: Bearer ${COOLIFY_TOKEN}" \
  -H "Content-Type: application/json" \
  "${COOLIFY_URL}/api/v1/applications/dockerimage" \
  -d "{
    \"project_uuid\": \"hcw40ckwss4gkgwkckc004wc\",
    \"environment_name\": \"production\",
    \"server_uuid\": \"sggkws4cgwoo0kckk4oogcss\",
    \"name\": \"${MCP_SLUG}\",
    \"docker_registry_image_name\": \"localhost:5000/${MCP_SLUG}\",
    \"docker_registry_image_tag\": \"latest\",
    \"ports_exposes\": \"8000\",
    \"domains\": \"${MCP_DOMAIN}\",
    \"instant_deploy\": true
  }"
```

**Response:** Returns JSON with the new application UUID. **Save this UUID** — you need it for
redeployments and environment variable management.

```json
{
  "uuid": "pgk8kcg8o804c8o0w4wo44kc",
  "domains": ["https://your-mcp-name.mcp.aimatrx.com"]
}
```

### Step 5: Set Environment Variables (if needed)

```bash
APP_UUID="<uuid-from-step-4>"

# Set a single env var
curl -s -X PATCH \
  -H "Authorization: Bearer ${COOLIFY_TOKEN}" \
  -H "Content-Type: application/json" \
  "${COOLIFY_URL}/api/v1/applications/${APP_UUID}/envs" \
  -d "{
    \"key\": \"MCP_NAME\",
    \"value\": \"Your MCP Display Name\",
    \"is_build_time\": false,
    \"is_preview\": false
  }"
```

Common env vars to set:
- `MCP_NAME` — Display name for the MCP
- `PORT` — Usually `8000` (matches Dockerfile EXPOSE)
- `MCP_API_KEYS` — Comma-separated API keys (if auth=apikey)
- `SUPABASE_URL`, `SUPABASE_JWT_SECRET` — (if auth=supabase)

### Step 6: Verify Deployment

```bash
MCP_DOMAIN="https://${MCP_SLUG}.mcp.aimatrx.com"

# 1. Health check
curl -s "${MCP_DOMAIN}/"
# Expected: {"name":"...","version":"1.0.0","mcp_endpoint":"/mcp","status":"running"}

# 2. MCP Initialize (full protocol test)
curl --max-time 10 -s -D /tmp/mcp-headers.txt -X POST "${MCP_DOMAIN}/mcp" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-03-26",
      "capabilities": {},
      "clientInfo": {"name": "test", "version": "1.0.0"}
    }
  }'
# Expected: JSON with serverInfo, capabilities, tools list

# 3. Extract session and call a tool
SESSION=$(grep -i mcp-session-id /tmp/mcp-headers.txt | awk '{print $2}' | tr -d '\r')
curl --max-time 10 -s -X POST "${MCP_DOMAIN}/mcp" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "mcp-session-id: ${SESSION}" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "your_tool_name",
      "arguments": {"arg": "value"}
    }
  }'
```

---

## Redeployment (After Code Changes)

When you update the MCP source code:

```bash
MCP_SLUG="your-mcp-name"
APP_UUID="<coolify-app-uuid>"

# 1. Sync updated code
rsync -avz --exclude='node_modules' --exclude='.venv' --exclude='__pycache__' \
  "./mcps/${MCP_SLUG}/" "root@191.101.15.190:/opt/mcps/${MCP_SLUG}/"

# 2. Rebuild and push image
ssh root@191.101.15.190 << EOF
  cd /opt/mcps/${MCP_SLUG}
  docker build -t localhost:5000/${MCP_SLUG}:latest .
  docker push localhost:5000/${MCP_SLUG}:latest
EOF

# 3. Restart application in Coolify
curl -s -X POST \
  -H "Authorization: Bearer ${COOLIFY_TOKEN}" \
  "${COOLIFY_URL}/api/v1/applications/${APP_UUID}/restart"
```

**Important:** Coolify's restart pulls the `latest` tag from the registry automatically.
No need to delete/recreate the application.

---

## Currently Deployed MCPs

| MCP | Language | Coolify UUID | URL |
|-----|----------|-------------|-----|
| seo-tools-ts-vps | TypeScript | `pgk8kcg8o804c8o0w4wo44kc` | `https://seo-tools-ts.mcp.aimatrx.com/mcp` |
| seo-tools-python-vps | Python | `kwk404c48cokokwoos4woo84` | `https://seo-tools-python.mcp.aimatrx.com/mcp` |

---

## Troubleshooting

### Image not found when Coolify deploys

**Symptom:** Coolify logs show "image not found" or "pull failed"

**Cause:** Image wasn't pushed to registry, or Coolify can't reach `localhost:5000`

**Fix:**
```bash
# Verify image exists in registry
ssh root@191.101.15.190 "curl -s localhost:5000/v2/_catalog"
# Should list your image name

# Verify the specific tag
ssh root@191.101.15.190 "curl -s localhost:5000/v2/${MCP_SLUG}/tags/list"
# Should show {"tags":["latest"]}
```

### Container starts but health check fails

**Symptom:** Coolify shows container running but domain returns 502

**Cause:** App listening on wrong port, or health endpoint not responding

**Fix:**
```bash
# Check container logs
ssh root@191.101.15.190 "docker logs \$(docker ps -q -f name=${MCP_SLUG}) --tail 50"

# Verify port
ssh root@191.101.15.190 "docker inspect \$(docker ps -q -f name=${MCP_SLUG}) | grep -A2 ExposedPorts"
# Should show "8000/tcp"
```

### 307 Redirect on /mcp endpoint

**Symptom:** POST to `/mcp` returns 307 redirect to `/mcp/`

**Cause:** Starlette `Mount("/mcp", ...)` adds trailing slash redirect

**Fix:** Use `mcp.http_app(path="/mcp")` and mount at root: `app.mount("/", mcp_app)`
(This is already fixed in the current template — see Bug #15 in DEPLOYMENT_PROGRESS.md)

### Registry service not accessible

**Symptom:** `curl localhost:5000/v2/` fails on VPS

**Fix:** Check registry is running in Coolify dashboard (service UUID: `l044ccwcg8484g8gcgww4kkk`).
Port must be mapped to host: `127.0.0.1:5000:5000` in the docker-compose config.

---

## Coolify API Reference (Key Endpoints)

```bash
BASE="${COOLIFY_URL}/api/v1"
AUTH="-H 'Authorization: Bearer ${COOLIFY_TOKEN}'"

# List all applications
curl -s ${AUTH} "${BASE}/applications"

# Get application details
curl -s ${AUTH} "${BASE}/applications/${APP_UUID}"

# Create docker-image application
curl -s -X POST ${AUTH} -H "Content-Type: application/json" \
  "${BASE}/applications/dockerimage" -d '{...}'

# Update application settings
curl -s -X PATCH ${AUTH} -H "Content-Type: application/json" \
  "${BASE}/applications/${APP_UUID}" -d '{"key": "value"}'

# Set environment variable
curl -s -X PATCH ${AUTH} -H "Content-Type: application/json" \
  "${BASE}/applications/${APP_UUID}/envs" -d '{"key":"K","value":"V"}'

# Restart (redeploy)
curl -s -X POST ${AUTH} "${BASE}/applications/${APP_UUID}/restart"

# Stop
curl -s -X POST ${AUTH} "${BASE}/applications/${APP_UUID}/stop"

# Start
curl -s -X POST ${AUTH} "${BASE}/applications/${APP_UUID}/start"

# Delete
curl -s -X DELETE ${AUTH} "${BASE}/applications/${APP_UUID}"
```

---

## Registry Management

```bash
# List all images in registry
ssh root@191.101.15.190 "curl -s localhost:5000/v2/_catalog"

# List tags for an image
ssh root@191.101.15.190 "curl -s localhost:5000/v2/<image-name>/tags/list"

# Registry runs as Coolify service (UUID: l044ccwcg8484g8gcgww4kkk)
# Config: registry:3 image, port 127.0.0.1:5000:5000
# Auth: fi0fYTPXqNQJVaIm / pWA7R813XUDTt8AStO2xm99QBZgndLgh
```
