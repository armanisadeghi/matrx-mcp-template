# Browser Agent Tasks

## ✅ Done
- Cloudflare setup — account active, wrangler logged in (ID: `e37857a87af22b3b3d00e7aebadcf674`, subdomain: `arman-e37.workers.dev`)
- Hostinger VPS — provisioned (Ubuntu 24.04 + Docker + Coolify, IP: `191.101.15.190`), SSH key auth configured

---

### Task 1: DNS Wildcard
Add A record: `*.mcp` → `191.101.15.190` in DNS for `aimatrx.com`. Verify with `dig` or dnschecker.org.

### Task 2: Coolify Onboarding
Open `http://191.101.15.190:8000` → create admin account → select "localhost" → verify dashboard + server connected. Save creds to `.env`.

### Task 3: Supabase Credentials
From AI Matrx Supabase project: get `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_JWT_SECRET` (Settings → API + JWT Settings).

### Task 4: Hostinger API Token
From Hostinger dashboard → Account → API → get `HOSTINGER_API_TOKEN`.


## Pending

