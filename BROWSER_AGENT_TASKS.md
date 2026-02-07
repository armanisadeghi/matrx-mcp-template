# Browser Agent Tasks

These tasks require browser access and cannot be done from the terminal.

## Cloudflare Setup

- [ ] **Create Cloudflare account** (if you don't have one): https://dash.cloudflare.com/sign-up
- [ ] **Run `wrangler login`** to authenticate the CLI with your Cloudflare account
- [ ] **Test deploy** the meta-tag-checker example to verify the Cloudflare workflow:
  ```bash
  cd examples/meta-tag-checker && wrangler deploy
  ```
- [ ] **(Optional) Add custom domain** in Cloudflare dashboard for Worker routes

## Hostinger VPS Setup

- [ ] **Purchase Hostinger KVM 2 VPS** at https://www.hostinger.com/vps-hosting
  - Select "Ubuntu 24.04 with Coolify" during onboarding
  - Note the VPS IP address and root password
- [ ] **Access Coolify dashboard** at `http://{VPS_IP}:8000`
  - Create admin account
  - Select "localhost" during onboarding
- [ ] **Configure DNS** — Add wildcard A record: `*.mcp.yourdomain.com → {VPS_IP}`
- [ ] **Enable SSL** in Coolify settings (Let's Encrypt)
- [ ] **Connect GitHub** in Coolify → Settings → Sources → Add GitHub App
- [ ] **(Optional) Get Hostinger API token** from dashboard → Account → API

## Supabase Configuration

- [ ] **Get Supabase credentials** from Supabase Dashboard → Settings → API:
  - `SUPABASE_URL`
  - `SUPABASE_JWT_SECRET` (under "JWT Settings")
  - `SUPABASE_SERVICE_ROLE_KEY` (under "Service Role")
- [ ] **Create Supabase tables** for MCPs that need them:
  - Bug tracker: `bugs` table with columns (id, title, description, severity, status, app_name, created_at, updated_at, user_id)
  - Virtual tables: `virtual_table_definitions` and `virtual_table_rows` tables
- [ ] **Set up RLS policies** for user-scoped data access

## Deployment Verification

- [ ] **Deploy meta-tag-checker** to Cloudflare Workers and verify `/mcp` endpoint responds
- [ ] **Deploy bug-tracker** to Coolify/VPS and verify `/mcp` endpoint responds
- [ ] **Test authentication** — verify API key and Supabase JWT flows work end-to-end
- [ ] **Configure MCP clients** (Claude Desktop, Cursor, etc.) to connect to deployed MCPs
