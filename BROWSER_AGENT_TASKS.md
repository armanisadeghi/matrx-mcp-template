# Browser Agent Tasks

Tasks that require browser interaction. The browser agent can ask for human assistance as needed.

## Task 1: Cloudflare Workers Setup

**Goal:** Set up Cloudflare Workers so we can deploy stateless MCPs to the edge.

**Steps:**
1. Go to https://dash.cloudflare.com/sign-up (or log in if account exists)
2. Create a free account (if new)
3. Note the account ID from the dashboard (Settings → Account → Account ID)
4. No Workers need to be created manually — we deploy via `wrangler` CLI

**What to return:**
- Cloudflare account email
- Account ID
- Confirmation that the account is active

**After browser task:** Run `wrangler login` in the terminal to authenticate the CLI.

---

## Task 2: Hostinger VPS Purchase & Coolify Setup

**Goal:** Set up a VPS with Coolify for deploying stateful Docker-based MCPs.

**Steps:**
1. Go to https://www.hostinger.com/vps-hosting
2. Purchase the **KVM 2** plan (~$7–10/mo) — 2 vCPU, 8GB RAM, 100GB NVMe
3. During onboarding, select **"Ubuntu 24.04 with Coolify"** template
4. Set a root password and note it
5. Note the **VPS IP address**
6. Access Coolify at `http://{VPS_IP}:8000`
7. Create an admin account on first access
8. Select "localhost" during Coolify onboarding (deploy to same server)
9. Get the **Hostinger API token**: Dashboard → Account → API

**What to return:**
- VPS IP address
- Root password (store securely)
- Coolify admin credentials
- Hostinger API token

---

## Task 3: DNS Wildcard Configuration

**Prerequisite:** Task 2 completed (need VPS IP)

**Goal:** Point `*.mcp.aimatrx.com` to the VPS for MCP subdomains.

**Steps:**
1. Go to your DNS provider for `aimatrx.com`
2. Add a wildcard A record: `*.mcp` → `{VPS_IP}`
3. Verify propagation (may take up to 48h but usually 5-15 min)

**What to return:**
- Confirmation that the DNS record was added
- The VPS IP used

---

## Task 4: Supabase Credentials

**Goal:** Get credentials from the existing AI Matrx Supabase project for MCP auth.

**Steps:**
1. Go to https://supabase.com/dashboard
2. Open the AI Matrx project
3. Go to Settings → API
4. Copy:
   - **Project URL** (starts with `https://`)
   - **anon/public key**
   - **service_role key** (click "Reveal")
5. Go to Settings → API → JWT Settings
6. Copy the **JWT Secret**

**What to return:**
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`
- `SUPABASE_JWT_SECRET`

**Note:** These should be stored as environment variables, never committed to code.
