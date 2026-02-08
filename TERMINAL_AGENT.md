# Terminal / Coding Agent Tasks

Large coding tasks suitable for delegation to the Claude coding agent (branch-based workflow).

## Task 1: MCP Registry System

**Branch from:** `main`
**Priority:** High

**Goal:** Build a complete MCP registry system that tracks all deployed MCPs in a Supabase Postgres table.

**Requirements:**
1. **Supabase migration** — Create the `mcp_registry` table (see schema below)
2. **Generator integration** — Update `create-mcp.sh` to call a registration script after scaffolding
3. **Registration script** — `scripts/register-mcp.sh` that inserts/updates the registry via Supabase API
4. **Status update script** — `scripts/update-mcp-status.sh` for marking MCPs as deployed/active/inactive
5. **List script** — `scripts/list-mcps.sh` to query and display all registered MCPs

**Table schema:**
```sql
CREATE TABLE mcp_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    language TEXT NOT NULL CHECK (language IN ('python', 'typescript')),
    tier TEXT NOT NULL CHECK (tier IN ('cloudflare', 'vps')),
    auth_type TEXT NOT NULL CHECK (auth_type IN ('none', 'apikey', 'supabase')),
    db_type TEXT NOT NULL DEFAULT 'none' CHECK (db_type IN ('none', 'supabase', 'postgres')),
    endpoint_url TEXT,
    status TEXT NOT NULL DEFAULT 'scaffolded' CHECK (status IN ('scaffolded', 'developing', 'deployed', 'active', 'inactive', 'deprecated')),
    repo_url TEXT,
    is_separate_repo BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deployed_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'
);
```

**Deliverables:**
- SQL migration file
- Updated `create-mcp.sh`
- `scripts/register-mcp.sh`
- `scripts/update-mcp-status.sh`
- `scripts/list-mcps.sh`

---

## Task 2: CI/CD Pipeline

**Branch from:** `main`
**Priority:** Low (after first successful manual deployments)

**Goal:** GitHub Actions workflows for auto-deploying MCPs.

**Requirements:**
1. Cloudflare Workers deploy action (on push to `mcps/{name}/` for CF-tier MCPs)
2. Docker build + push for VPS-tier MCPs
3. Registry status update after successful deploy

---

## Task 3: Deploy Helper Script

**Branch from:** `main`
**Priority:** Medium

**Goal:** A unified `scripts/deploy-mcp.sh` that handles both CF and VPS deployments.

**Requirements:**
1. Auto-detect tier from the MCP's config (wrangler.toml = CF, docker-compose.yml = VPS)
2. For CF: run `wrangler deploy`
3. For VPS: build Docker image, push to registry, trigger Coolify redeploy
4. Update the MCP registry status after successful deploy
