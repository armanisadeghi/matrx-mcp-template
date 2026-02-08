# Browser Agent Tasks

## ✅ Completed
- [x] **Cloudflare setup** — Account active, `wrangler login` done, Account ID: `08e81b35149e50e351b86aa6a1872c6d`
- [x] **Hostinger VPS** — Provisioned, Ubuntu 24.04 + Docker + Coolify, IP: `191.101.15.190`, SSH key auth configured

---

## Task 1: DNS Wildcard Configuration

**Goal:** Point `*.mcp.aimatrx.com` to the VPS for MCP subdomains.

**Steps:**
1. Go to DNS provider for `aimatrx.com`
2. Add wildcard A record: `*.mcp` → `191.101.15.190`
3. Verify propagation (`dig *.mcp.aimatrx.com` or https://dnschecker.org)

**Return:** Confirmation the record was added.

---

## Task 2: Coolify Onboarding

**Goal:** Complete the initial Coolify setup so we can deploy containers.

**Steps:**
1. Open `http://191.101.15.190:8000` in browser
2. Create an admin account (save credentials to `.env`)
3. During onboarding, select "localhost" (deploy to same server)
4. Verify the dashboard loads and server shows as connected

**Return:** Coolify admin email + password.

---

## Task 3: Supabase Credentials

**Goal:** Get credentials from the AI Matrx Supabase project for MCP auth.

**Steps:**
1. Go to https://supabase.com/dashboard → AI Matrx project
2. Settings → API → Copy: Project URL, anon key, service_role key (click "Reveal")
3. Settings → API → JWT Settings → Copy JWT Secret

**Return:** `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET`

---

## Task 4: Hostinger API Token

**Goal:** Get API token for programmatic VPS management.

**Steps:**
1. Go to Hostinger dashboard → Account → API
2. Generate or copy API token

**Return:** `HOSTINGER_API_TOKEN`
