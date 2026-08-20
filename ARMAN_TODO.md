# Project Status & TODO

Last updated: 2026-08-20

## ✅ Completed — Infrastructure

- Repo structure and Python/TypeScript generators for Cloudflare, Coolify/VPS, and AWS App Runner
- 4 example MCPs, shared utilities, docs, all architectural decisions resolved
- Canonical catalog integration with East `tool.mcp_server`; the old `public.mcp_registry` proposal is retired
- GitHub: `main` branch, clean history
- Cloudflare: account active, `wrangler` authenticated
- VPS: Hostinger (Ubuntu 24.04, Docker, Coolify) at `191.101.15.190`, SSH key auth
- Coolify: onboarded, API token, HTTPS at `coolify.mcp.aimatrx.com`, Git auth configured
- DNS: `*.mcp.aimatrx.com → 191.101.15.190`
- IDE MCP tools: Supabase, Hostinger, Coolify — all connected
- Credentials remain outside Git; AWS deployments use workload identity and Secrets Manager references

## 🔲 First Deployments — Ready to Go

- [ ] Meta Tag Checker → Cloudflare (validates CF workflow)
- [ ] Bug Tracker → VPS/Coolify (validates VPS workflow)
- [ ] Verify endpoints + configure MCP clients

## 🔲 Future

- [ ] Unified target-neutral deploy API/UI | rate limiting | catalog dashboard
