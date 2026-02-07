# Cloudflare Workers Deployment Guide

## Prerequisites

1. **Cloudflare account** — [Sign up free](https://dash.cloudflare.com/sign-up)
2. **Wrangler CLI** — Install globally:
   ```bash
   npm install -g wrangler
   ```
3. **Authenticate** — Log in to your Cloudflare account:
   ```bash
   wrangler login
   ```

## Deploy an MCP

```bash
cd mcps/your-mcp-name/
wrangler deploy
```

Your MCP will be available at:
```
https://your-mcp-name.your-subdomain.workers.dev/mcp
```

## Environment Variables & Secrets

Public variables go in `wrangler.toml`:
```toml
[vars]
MCP_NAME = "My Tool"
```

Secrets (API keys, JWT secrets) should be set via CLI:
```bash
wrangler secret put MCP_API_KEYS
# Paste your comma-separated keys when prompted

wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_JWT_SECRET
wrangler secret put SUPABASE_SERVICE_ROLE_KEY
```

## Custom Domain (Optional)

Add a route in `wrangler.toml`:
```toml
routes = [
  { pattern = "my-mcp.yourdomain.com/*", zone_name = "yourdomain.com" }
]
```

Then add a DNS record in Cloudflare dashboard:
- Type: `CNAME`
- Name: `my-mcp`
- Target: `your-subdomain.workers.dev`
- Proxy: On (orange cloud)

## Local Development

```bash
cd mcps/your-mcp-name/

# Python MCPs
pip install -r requirements.txt
python -m src.server

# TypeScript MCPs
npm install
npm run dev    # Uses wrangler dev server
```

## Python Workers Notes

- Python Workers on Cloudflare use the `python_workers` compatibility flag
- Not all Python packages are available — pure Python packages work best
- For packages with C extensions, check [Cloudflare's Python compatibility list](https://developers.cloudflare.com/workers/languages/python/packages/)
- If a package isn't supported, consider deploying to VPS instead

## Limits (Free Tier)

| Resource | Limit |
|----------|-------|
| Requests/day | 100,000 |
| CPU time/request | 10ms |
| Script size | 1 MB |
| Environment variables | 64 per script |

**Paid plan ($5/month):**
- 10 million requests/month
- 30ms CPU time/request
- 10 MB script size

## Monitoring

View logs in real-time:
```bash
wrangler tail
```

View in dashboard: Cloudflare Dashboard → Workers & Pages → your worker → Logs

## Troubleshooting

**"Script too large"** — Your dependencies may be too large for Workers. Move to VPS tier.

**"Module not found"** — The Python package may not be available on Cloudflare. Check compatibility or use VPS.

**"CPU time exceeded"** — Your tool is doing too much work per request. Optimize or move to VPS.
