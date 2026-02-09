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
- Cloudflare: account active (ID: `e37857a87af22b3b3d00e7aebadcf674`, subdomain: `arman-e37.workers.dev`), `wrangler login` done
- VPS: Hostinger provisioned (Ubuntu 24.04 + Docker + Coolify, IP: `191.101.15.190`), SSH key auth configured
- Coolify: onboarded, API token generated, MCP tool configured in IDE
- Hostinger MCP tool configured in IDE
- All credentials saved to `.env`

## 🔲 Infrastructure (Browser/Human Required)

- [ ] **DNS wildcard** — `*.mcp.aimatrx.com → 191.101.15.190` A record
- [ ] **Supabase credentials** — service role key + JWT secret → `.env`

## 🔲 First Deployments

- [ ] Meta Tag Checker → Cloudflare (validates CF workflow)
- [ ] Bug Tracker → VPS/Coolify (validates VPS workflow)
- [ ] Verify endpoints with curl + configure MCP clients

## 🔲 Future

- [ ] `deploy.sh` helper | CI/CD | Health-check monitoring | Rate limiting | Registry dashboard
