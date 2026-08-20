# Decisions Made

All 5 architectural decisions are resolved.

1. **Domain for MCP Subdomains:** `*.mcp.aimatrx.com` | CF default: `*.workers.dev` — route-based or nested subdomain pattern  
   → *Action: Configure DNS wildcard A record once VPS provisioned*

2. **Supabase Project:** Use existing **AI Matrx** Supabase project (shared auth, single JWT)

3. **CF Workers Python Support:** Try Cloudflare first, fall back to VPS or AWS for native deps — generator supports all three targets

4. **Client MCP Delivery:** Mix — self-host some, clients host others via `--separate-repo` flag

5. **MCP Catalog:** Use the canonical East `tool.mcp_server` catalog. The abandoned West-era
   `public.mcp_registry` proposal is retired; generator metadata lives in `tool.mcp_server.metadata`.

6. **AWS Hosting:** AWS App Runner is the managed-container target. It uses stateless Streamable HTTP,
   immutable ECR releases, an IAM workload role, an AWS-managed HTTPS URL, health checks, and CloudWatch logs.

The cross-repository contract is `common-docs/systems/mcp-hosting/FEATURE.md`.
