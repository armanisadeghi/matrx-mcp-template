# Coolify Configuration Guide

## ✅ Infrastructure Ready
- **VPS:** `191.101.15.190` (KVM 2, Ubuntu 24.04, 2 vCPU, 8GB RAM, 90GB free)
- **Docker:** v29.2.1 (running, healthy)
- **Proxy:** Traefik v3.6 (running, healthy, ports 80/443)
- **DNS:** `*.mcp.aimatrx.com → 191.101.15.190` (A record, TTL 60)
- **Dashboard:** `http://191.101.15.190:8000`

---

## 🔲 Remaining Steps (Browser Required)

### Step 1: Configure Coolify Domain
Open dashboard → Settings → set Instance FQDN to `http://191.101.15.190:8000` (keep as IP for now) → Save.

### Step 2: Verify Server Connection
Sidebar → Servers → "localhost" → verify Status: Connected, Docker: Running, Proxy: Traefik running. Click "Validate Server" if disconnected.

### Step 3: Connect GitHub
Sidebar → Sources → Add → GitHub App → OAuth flow → authorize → select repos (at minimum `armanisadeghi/matrx-mcp-template`).  
*Fallback: Use fine-grained Personal Access Token with repo read access.*

### Step 4: Create Project
Sidebar → Projects → Add → name: "MCP Servers" → create environment: "production".

### Step 5: Verify via SSH
```bash
ssh root@191.101.15.190 "docker ps --format 'table {{.Names}}\t{{.Status}}'"
# All Coolify containers should show healthy
dig +short test.mcp.aimatrx.com  # Should return 191.101.15.190
```

### Step 6: Test Deploy
**Quick Docker test:**
```bash
ssh root@191.101.15.190 "docker run -d --name test-mcp --network coolify \
  -l 'traefik.enable=true' \
  -l 'traefik.http.routers.test-mcp.rule=Host(\`test.mcp.aimatrx.com\`)' \
  -l 'traefik.http.routers.test-mcp.entrypoints=http' \
  -l 'traefik.http.services.test-mcp.loadbalancer.server.port=80' \
  nginx:alpine"
curl -H "Host: test.mcp.aimatrx.com" http://191.101.15.190
ssh root@191.101.15.190 "docker rm -f test-mcp"
```

**Or via Coolify:** Projects → MCP Servers → production → New Resource → Docker Compose → select repo → set domain `test.mcp.aimatrx.com` → Deploy.

### Step 7: SSL / HTTPS
Coolify → Settings → enable Let's Encrypt → set email `Arman@armansadeghi.com` → Save. DNS must be propagated first ([dnschecker.org](https://dnschecker.org)).

---

## Quick Reference: Deploy a New MCP (After Setup)

1. `./generators/create-mcp.sh --name "my-tool" --lang python --tier vps`
2. Push to GitHub
3. Coolify: New Resource → Docker Compose → select repo → set domain → Deploy
4. Live at `https://my-tool.mcp.aimatrx.com/mcp` (or via Coolify API)
