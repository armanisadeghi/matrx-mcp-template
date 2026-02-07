# Decisions for Arman

These are questions that came up during implementation. Answers will inform follow-up work.

## 1. Domain for MCP Subdomains

**Question:** What domain do you want to use for VPS-hosted MCPs?

**Options:**
- `*.mcp.aimatrx.com` (subdomain of your main domain)
- `*.mcp.yourdomain.com` (a separate domain)
- Buy a short domain like `mcps.dev` or similar

**Impact:** Needed for DNS wildcard setup and Coolify configuration. Cloudflare Workers use `*.workers.dev` by default (free), custom domain is optional.

## 2. Supabase Project

**Question:** Should MCPs with Supabase auth use your existing AI Matrx Supabase project or a separate one?

**Recommendation:** Use the same project — this way users authenticate once and their JWT works everywhere. Only create a separate project if you need full data isolation.

## 3. Cloudflare Workers Python Support

**Question:** Cloudflare Workers Python support is still relatively new and has limited package compatibility. For Python MCPs that use heavy dependencies (like PDF processing with PyPDF2), should we:

**Options:**
- A) Try Cloudflare first, fall back to VPS if packages aren't supported
- B) Always use VPS for Python MCPs with non-trivial dependencies
- C) Use TypeScript for Cloudflare MCPs and Python only for VPS

**Recommendation:** Option A for simple tools, Option B for anything with native dependencies. The generator already supports both tiers, so switching is just a re-scaffold.

## 4. Client MCP Delivery

**Question:** When delivering MCPs to clients, how do you want to handle it?

**Options:**
- A) Host everything yourself (clients just get the MCP endpoint URL)
- B) Give clients their own repo with `--separate-repo` flag (they self-host)
- C) Mix — you host some, clients host others

**Impact:** Affects whether we need to build multi-tenant support, billing, and client onboarding docs.

## 5. MCP Registry / Discovery

**Question:** As you build more MCPs, do you want a central registry that lists all available MCPs and their endpoints?

**Options:**
- A) Simple README/JSON file in this repo listing all deployed MCPs
- B) A small web dashboard (could be another MCP or a simple Next.js page)
- C) Not needed yet — just track in docs

**Recommendation:** Start with Option A (a `registry.json` file). Build a dashboard later if the list grows past 20+.
