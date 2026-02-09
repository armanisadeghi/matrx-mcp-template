# Hostinger VPS + Coolify — One-Time Setup

## ✅ Done
- VPS purchased: Hostinger KVM 2, Ubuntu 24.04 with Coolify, IP: `191.101.15.190`
- SSH access configured (key auth, passwordless)
- Docker + Coolify containers running and healthy

## 🔲 Remaining (See also `COOLIFY_SETUP.md` for detailed steps)

- [ ] Coolify dashboard onboarding (`http://191.101.15.190:8000` — create admin, select localhost)
- [ ] DNS wildcard: `*.mcp.aimatrx.com → 191.101.15.190` + optionally `coolify.aimatrx.com`
- [ ] SSL: Enable Let's Encrypt in Coolify
- [ ] GitHub: Connect via Coolify Sources → GitHub App
- [ ] Hostinger MCP Server (optional): `npm install -g hostinger-api-mcp` + API token from Hostinger dashboard

## Firewall Ports Required

| Port | Purpose |
|------|---------|
| 22 | SSH |
| 80 | HTTP (Traefik) |
| 443 | HTTPS (Traefik) |
| 8000 | Coolify dashboard |

## Hostinger MCP Config (for AI agent VPS management)
```json
{
  "mcpServers": {
    "hostinger-api": {
      "command": "hostinger-api-mcp",
      "env": { "API_TOKEN": "YOUR_HOSTINGER_API_TOKEN" }
    }
  }
}
```
