# Project Status & TODO

Last updated: 2026-02-08

## ✅ Completed

- [x] Repository structure created (monorepo with generators, templates, shared, examples, docs, infrastructure)
- [x] Generator script (`create-mcp.sh`) — handles all 4 template combos with auth/db options
- [x] Generator bug fix — cross-platform `sed -i` compatibility (macOS + Linux)
- [x] Generator bug fix — `mkdir -p` for `mcps/` directory creation
- [x] Templates built: python-cloudflare, python-vps, typescript-cloudflare, typescript-vps
- [x] All 4 template combos tested and verified (placeholder replacement, file structure, auth/db setup)
- [x] Example MCPs: meta-tag-checker, pdf-tools, bug-tracker, virtual-tables
- [x] Shared utilities: auth (API key + Supabase JWT), Supabase client, structured logging
- [x] Documentation: deployment guides (Cloudflare + VPS), auth guide, adding-tools guide
- [x] All 5 architectural decisions resolved (see ARMAN_DECISIONS.md)
- [x] MCP Registry table created in Supabase (`mcp_registry` in ai-matrix project)
- [x] Registry scripts: `register-mcp.sh`, `update-mcp-status.sh`, `list-mcps.sh`
- [x] Generator auto-registers new MCPs in the registry (soft-fail if no credentials)
- [x] Migration saved locally (`infrastructure/migrations/001_create_mcp_registry.sql`)
- [x] Root `.env.example` created
- [x] GitHub default branch set to `main`, old branch cleaned up
- [x] Cloudflare account verified & ready (Account ID: `08e81b35149e50e351b86aa6a1872c6d`, Workers subdomain: `orange-salad-fa20.workers.dev`)

## 🔲 Infrastructure Setup (Requires Browser/Human)

- [x] ~~**Cloudflare account** — Create account or confirm existing~~ ✅ Done
- [x] ~~**`wrangler login`** — Run in terminal to authenticate CLI with Cloudflare~~ ✅ Done
- [ ] **Hostinger VPS** — Purchase KVM 2 plan with Coolify template (Ubuntu 24.04)
- [ ] **DNS wildcard** — Add `*.mcp.aimatrx.com → {VPS_IP}` A record
- [ ] **Supabase credentials** — Get service role key + JWT secret from existing project, add to `.env`
- [ ] **Hostinger API token** — Get from dashboard for AI-managed VPS

## 🔲 First Deployments

- [ ] **Meta Tag Checker → Cloudflare** (validates CF workflow)
- [ ] **Bug Tracker → VPS/Coolify** (validates VPS workflow, needs Supabase tables first)
- [ ] **Verify MCP endpoints** with curl tests
- [ ] **Configure MCP clients** (Claude Desktop, Cursor) to connect

## 🔲 Enhancements (Future)

- [ ] `deploy.sh` helper script for both CF and Docker deployments
- [ ] GitHub Actions CI/CD for auto-deploy on push
- [ ] Multi-tenant routing design — support `org.mcp.aimatrx.com` or route-based patterns
- [ ] Health-check monitoring script
- [ ] Rate limiting middleware in shared utilities
- [ ] Registry dashboard (web UI for MCP discovery)
