# Project Status & TODO

Last updated: 2026-02-08

## ✅ Completed

- Repo structure, generator (`create-mcp.sh`), all 4 templates working
- Generator bug fixes (cross-platform `sed -i`, `mkdir -p`)
- 4 example MCPs: meta-tag-checker, pdf-tools, bug-tracker, virtual-tables
- Shared utilities: auth (API key + Supabase JWT), Supabase client, structured logging
- Docs: deployment guides (CF + VPS), auth guide, adding-tools guide
- All 5 architectural decisions resolved (see `ARMAN_DECISIONS.md`)
- MCP Registry: `mcp_registry` table + RLS in Supabase (`automation-matrix`), scripts, generator auto-registers
- GitHub: default branch → `main`, old branch deleted
- Cloudflare: account active, `wrangler login` done
- VPS: Hostinger provisioned (Ubuntu 24.04 + Docker + Coolify, IP: `191.101.15.190`), SSH key auth
- Coolify: onboarded, API token, MCP tool in IDE
- Hostinger MCP tool in IDE
- DNS wildcard: `*.mcp.aimatrx.com → 191.101.15.190` ✅
- Supabase: URL + anon key in `.env`
- All credentials centralized in `.env`

## 🔲 Remaining

- [ ] **Supabase service role key + JWT secret** — must be copied from dashboard (not available via API)
- [ ] Meta Tag Checker → Cloudflare (validates CF workflow)
- [ ] Bug Tracker → VPS/Coolify (validates VPS workflow)
- [ ] Verify endpoints + configure MCP clients

## 🔲 Future

- [ ] `deploy.sh` helper | CI/CD | Health-check monitoring | Rate limiting | Registry dashboard
