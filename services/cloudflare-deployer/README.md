# Cloudflare MCP Deployer

Authenticated API service that creates and deploys TypeScript Cloudflare MCP Workers from the repo template.

## Endpoints

- `GET /health` — service health and configuration readiness.
- `POST /v1/cloudflare/mcps` — scaffold, deploy, verify, and return a live MCP URL.

All deploy requests require:

```http
Authorization: Bearer <DEPLOYER_API_KEY>
```

## Environment

Copy `.env.example` to `.env` on the server and fill:

```bash
DEPLOYER_API_KEY=<your-internal-api-key>
CLOUDFLARE_ACCOUNT_ID=<cloudflare-account-id>
CLOUDFLARE_API_TOKEN=<cloudflare-api-token>
CLOUDFLARE_DEFAULT_DOMAIN=mcp.example.com
```

The Cloudflare token needs permissions for Workers deploys and custom domains/routes on the target zone.
If you do not use custom domains, set `CLOUDFLARE_WORKERS_SUBDOMAIN` so the deployer can return and verify `https://<slug>.<subdomain>.workers.dev`.

## Request

```bash
curl -X POST https://cloudflare-deployer.mcp.aimatrx.com/v1/cloudflare/mcps \
  -H "Authorization: Bearer $DEPLOYER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Customer SEO Tools",
    "description": "SEO utility MCP for a customer workspace",
    "slug": "customer-seo-tools",
    "hostname": "customer-seo-tools.mcp.aimatrx.com",
    "files": [
      {
        "path": "src/tools/index.ts",
        "content": "import { McpServer } from \"@modelcontextprotocol/sdk/server/mcp.js\";\nimport { z } from \"zod\";\n\nexport function registerTools(server: McpServer) {\n  server.tool(\"echo\", \"Echo a string\", { text: z.string() }, async ({ text }) => ({\n    content: [{ type: \"text\", text }]\n  }));\n}\n"
      }
    ]
  }'
```

If `hostname` is omitted and `CLOUDFLARE_DEFAULT_DOMAIN` is set, the service uses `<slug>.<CLOUDFLARE_DEFAULT_DOMAIN>`.

Response:

```json
{
  "ok": true,
  "slug": "customer-seo-tools",
  "workerName": "customer-seo-tools",
  "hostname": "customer-seo-tools.mcp.aimatrx.com",
  "url": "https://customer-seo-tools.mcp.aimatrx.com",
  "mcpUrl": "https://customer-seo-tools.mcp.aimatrx.com/mcp",
  "verified": true
}
```

## Run Locally

```bash
cd services/cloudflare-deployer
npm install
npm run build
npm start
```

## Deploy On VPS/Coolify

Use `services/cloudflare-deployer/docker-compose.yml` as the Compose file. Set the `.env` values as Coolify environment variables or an env file, then expose port `8080` behind your chosen domain.
