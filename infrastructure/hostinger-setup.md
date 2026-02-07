# Hostinger VPS + Coolify — One-Time Setup

## Step 1: Purchase VPS

1. Go to [Hostinger VPS](https://www.hostinger.com/vps-hosting)
2. Select **KVM 2** plan (~$7–10/month) or higher
3. During onboarding:
   - **OS Template:** Select **"Ubuntu 24.04 with Coolify"**
   - **Server Location:** Choose nearest to your primary users
   - **Set root password** and note it down
4. Note your **VPS IP address** from the dashboard

## Step 2: Initial SSH Access

```bash
ssh root@{YOUR_VPS_IP}
```

Coolify should already be installed. Verify:
```bash
docker ps  # Should show Coolify containers running
```

## Step 3: Access Coolify Dashboard

Open in browser:
```
http://{YOUR_VPS_IP}:8000
```

1. Create admin account
2. Select "localhost" during onboarding (deploy to same server)
3. Go through the setup wizard

## Step 4: Configure DNS

In your DNS provider (Cloudflare, Namecheap, etc.):

| Type | Name | Value | TTL |
|------|------|-------|-----|
| A | `*.mcp` | `{YOUR_VPS_IP}` | Auto |
| A | `coolify` | `{YOUR_VPS_IP}` | Auto |

This gives you:
- `anything.mcp.yourdomain.com` → your VPS
- `coolify.yourdomain.com` → Coolify dashboard

## Step 5: Configure Coolify Domain & SSL

1. In Coolify → Settings → General
2. Set your domain (e.g., `coolify.yourdomain.com`)
3. Enable Let's Encrypt for automatic SSL
4. Save and wait for SSL provisioning

## Step 6: Connect GitHub

1. In Coolify → Settings → Sources
2. Click "Add GitHub App"
3. Follow the OAuth authorization flow
4. Select the repositories you want Coolify to access

## Step 7: Install Hostinger MCP Server (Optional)

For AI agents to manage the VPS:

```bash
npm install -g hostinger-api-mcp
```

Get your API token from Hostinger dashboard → Account → API.

Configure in your AI tool (Claude Desktop, etc.):
```json
{
  "mcpServers": {
    "hostinger-api": {
      "command": "hostinger-api-mcp",
      "env": {
        "API_TOKEN": "YOUR_HOSTINGER_API_TOKEN"
      }
    }
  }
}
```

## Step 8: Verify Setup

Deploy a test container:
```bash
docker run -d -p 9999:80 --name test nginx
curl http://localhost:9999  # Should return nginx welcome page
docker rm -f test
```

## Firewall Configuration

Ensure these ports are open (Hostinger dashboard → VPS → Firewall):

| Port | Purpose |
|------|---------|
| 22 | SSH |
| 80 | HTTP (Traefik) |
| 443 | HTTPS (Traefik) |
| 8000 | Coolify dashboard |

## Post-Setup Checklist

- [ ] VPS is running Ubuntu 24.04 with Coolify
- [ ] Can SSH into VPS
- [ ] Coolify dashboard is accessible
- [ ] DNS wildcard is configured (`*.mcp.yourdomain.com`)
- [ ] SSL is working via Let's Encrypt
- [ ] GitHub is connected to Coolify
- [ ] Hostinger MCP server is installed (optional)
- [ ] Firewall ports are open
