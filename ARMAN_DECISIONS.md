# Decisions Made

All 5 architectural decisions are resolved.

1. **Domain for MCP Subdomains:** `*.mcp.aimatrx.com` | CF default: `*.workers.dev` — route-based or nested subdomain pattern  
   → *Action: Configure DNS wildcard A record once VPS provisioned*

2. **Supabase Project:** Use existing **AI Matrx** Supabase project (shared auth, single JWT)

3. **CF Workers Python Support:** Try Cloudflare first, fall back to VPS for native deps — generator supports both

4. **Client MCP Delivery:** Mix — self-host some, clients host others via `--separate-repo` flag

5. **MCP Registry:** Postgres table in AI Matrx Supabase (`mcp_registry`) — tracks name, endpoint, status, tier, auth type; generator auto-registers on scaffold

## Pending
- 
