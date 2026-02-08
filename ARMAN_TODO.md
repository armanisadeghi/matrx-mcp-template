# Arman's TODO

Items that need human decisions or actions.

## Decisions Needed

- [ ] **Choose a domain** for MCP subdomains (e.g., `*.mcp.aimatrx.com` or a new domain)
- [ ] **Confirm Hostinger plan** — KVM 2 ($7–10/mo) should be sufficient to start. Upgrade to KVM 4 if running 30+ MCPs.
- [ ] **Supabase project** — Are you using an existing AI Matrx Supabase project for MCP auth, or creating a separate one?
- [ ] **Cloudflare account** — Existing account or new one? Free tier handles 100K requests/day.

-- I Have answered everything inside of the decision file.

## Account Setup

- [ ] Set up Cloudflare account and run `wrangler login`
- [ ] Purchase Hostinger VPS (KVM 2 with Coolify template)
- [ ] Get Hostinger API token for the Hostinger MCP server

## First MCPs to Build

Suggested order based on complexity (simplest first to validate the workflow):

1. **Meta Tag Checker** → Deploy to Cloudflare (example already built, just deploy)
2. **PDF Tools** → Deploy to Cloudflare (example already built)
3. **A client marketing tools MCP** → Use the generator to scaffold, add custom tools
4. **Bug Tracker** → Deploy to VPS/Coolify (needs Supabase tables first)
5. **Virtual Tables** → Deploy to VPS/Coolify (needs Supabase schema design)

## Ongoing

- [ ] For each new client MCP, decide: Cloudflare (stateless) or VPS (stateful)?
- [ ] Set up monitoring/alerting for VPS MCPs (Coolify has basic monitoring built in)
- [ ] Consider a billing strategy if charging clients for MCP access
