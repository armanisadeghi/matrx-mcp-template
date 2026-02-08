# Project Status & TODO

Last updated: 2026-02-08

## ✅ Completed

- [x] Repo structure, generator (`create-mcp.sh`), all 4 templates tested & working
- [x] Generator bug fixes: cross-platform `sed -i`, `mkdir -p` for output dir
- [x] Example MCPs: meta-tag-checker, pdf-tools, bug-tracker, virtual-tables
- [x] Shared utilities: auth (API key + Supabase JWT), Supabase client, structured logging
- [x] Docs: deployment guides (CF + VPS), auth guide, adding-tools guide
- [x] All 5 architectural decisions resolved (see ARMAN_DECISIONS.md)
- [x] MCP Registry table + RLS policies in Supabase (`mcp_registry` in ai-matrix project)
- [x] Registry scripts: `register-mcp.sh`, `update-mcp-status.sh`, `list-mcps.sh`
- [x] Generator auto-registers to Supabase registry on scaffold
- [x] GitHub default branch → `main`, old branch deleted
- [x] Cloudflare account active (ID: `08e81b35149e50e351b86aa6a1872c6d`), `wrangler login` done
- [x] Hostinger VPS provisioned — Ubuntu 24.04, Docker, Coolify (IP: `191.101.15.190`)
- [x] SSH key auth configured (passwordless `ssh root@191.101.15.190`)

## 🔲 Infrastructure (Requires Browser/Human)

- [ ] **DNS wildcard** — Add `*.mcp.aimatrx.com → 191.101.15.190` A record
- [ ] **Coolify onboarding** — Access `http://191.101.15.190:8000`, create admin account, configure localhost server
- [ ] **Supabase credentials** — Get service role key + JWT secret, add to `.env`
- [ ] **Hostinger API token** — Get from Hostinger dashboard, add to `.env`

## 🔲 First Deployments

- [ ] **Meta Tag Checker → Cloudflare** (validates CF workflow)
- [ ] **Bug Tracker → VPS/Coolify** (validates VPS workflow)
- [ ] Verify MCP endpoints with curl
- [ ] Configure MCP clients (Claude Desktop, Cursor)

## 🔲 Future Enhancements

- [ ] `deploy.sh` helper for CF + Docker deployments
- [ ] GitHub Actions CI/CD
- [ ] Health-check monitoring
- [ ] Rate limiting middleware
- [ ] Registry dashboard (web UI)
