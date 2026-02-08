# Decisions Log

All architectural decisions for the MCP Factory. Each decision is marked with its status.

## 1. Domain for MCP Subdomains ✅ RESOLVED

**Question:** What domain to use for VPS-hosted MCPs?

**Decision:** `*.mcp.aimatrx.com`
- Wildcard subdomain of the main AI Matrx domain
- Must support a pattern allowing users/organizations to have their own MCPs (e.g., route-based or nested subdomain)
- Cloudflare Workers use `*.workers.dev` by default (free), custom domain is optional

**Action Required:** Configure DNS wildcard A record once Hostinger VPS is provisioned.

---

## 2. Supabase Project ✅ RESOLVED

**Question:** Should MCPs use the existing AI Matrx Supabase project or a separate one?

**Decision:** Use the **same** AI Matrx Supabase project.
- Users authenticate once and their JWT works everywhere
- No data isolation needed for MCP auth

**Action Required:** Retrieve credentials (URL, JWT secret, service role key) from the existing Supabase dashboard.

---

## 3. Cloudflare Workers Python Support ✅ RESOLVED

**Question:** How to handle Python MCPs with heavy dependencies on Cloudflare?

**Decision:** **Option A** — Try Cloudflare first, fall back to VPS if packages aren't supported.
- Option B for anything with native dependencies
- The generator supports both tiers, so switching is a simple re-scaffold

**Action Required:** None — generator already supports this workflow.

---

## 4. Client MCP Delivery ✅ RESOLVED

**Question:** How to deliver MCPs to clients?

**Decision:** **Mix** — host some ourselves, clients host others.
- Use `--separate-repo` flag for client deliverables
- Self-host for internal/shared MCPs

**Action Required:** None — generator already supports `--separate-repo` flag.

---

## 5. MCP Registry / Discovery ✅ RESOLVED

**Question:** How to track and discover deployed MCPs?

**Decision:** **Postgres table in the AI Matrx Supabase database.**
- Not just a JSON file — needs proper database tracking
- Track MCP name, endpoint, status, tier, auth type, etc.
- Keep the database always up-to-date with available MCPs
- Generator should auto-register new MCPs on creation

**Action Required:** Design and create the Supabase table, update the generator to register MCPs.
