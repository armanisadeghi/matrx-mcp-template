# MCP Deployment Progress & Template Fix Tracker

Last updated: 2026-02-09 00:30 PST

## Goal
Deploy real SEO tools as MCP across all 4 template combos to validate the full pipeline.
The ONLY custom code should be the tool functions. Everything else must come from templates.

---

## Deployment Status

### TS + Cloudflare: LIVE
- **URL**: `https://seo-tools-ts-cf.arman-e37.workers.dev/mcp`
- **Health**: `https://seo-tools-ts-cf.arman-e37.workers.dev/`
- **Tools**: All 4 working (check_meta_title, check_meta_description, analyze_meta_tags, analyze_meta_tags_batch)
- **Managed by**: Cloudflare Workers (wrangler deploy)

### TS + VPS: LIVE
- **URL**: `https://seo-tools-ts.mcp.aimatrx.com/mcp`
- **Health**: `https://seo-tools-ts.mcp.aimatrx.com/`
- **Tools**: All 4 working
- **Managed by**: Coolify (application UUID: `pgk8kcg8o804c8o0w4wo44kc`)
- **Image**: `localhost:5000/seo-tools-ts-vps:latest` (private registry)

### Python + VPS: LIVE
- **URL**: `https://seo-tools-python.mcp.aimatrx.com/mcp`
- **Health**: `https://seo-tools-python.mcp.aimatrx.com/`
- **Tools**: All 4 working
- **Managed by**: Coolify (application UUID: `kwk404c48cokokwoos4woo84`)
- **Image**: `localhost:5000/seo-tools-python-vps:latest` (private registry)

### Python + Cloudflare: BLOCKED BY PLATFORM
- **Location**: `mcps/seo-tools-python-cf/`
- **Status**: Code correct (WorkerEntrypoint + FastAPI + ASGI pattern), but CF API rejects: "You cannot yet deploy Python Workers that depend on packages"
- **Recommendation**: Use Python-VPS instead. Drop or defer the Python-CF template.

---

## Infrastructure

### Private Docker Registry
- **Managed by**: Coolify service (UUID: `l044ccwcg8484g8gcgww4kkk`)
- **Access**: `localhost:5000` on VPS (port mapped to host 127.0.0.1 only — not publicly exposed)
- **Auth**: username `fi0fYTPXqNQJVaIm`, password `pWA7R813XUDTt8AStO2xm99QBZgndLgh`
- **Image**: `registry:3`

### VPS Deployment Pipeline: AUTOMATED

Each VPS MCP project now includes a `deploy-vps.sh` script that handles the full pipeline.
The generator also supports `--deploy` flag for one-click create + deploy.

**How it works:**
```
create-mcp.sh --name "My Tools" --lang python --tier vps --deploy
                                                          ↑
                                                   triggers deploy-vps.sh --create
```

**deploy-vps.sh lifecycle:**
```bash
# First deploy (creates Coolify app, provisions HTTPS):
./deploy-vps.sh --create

# Subsequent deploys (rebuild + push + restart):
./deploy-vps.sh

# Check status and health:
./deploy-vps.sh --status

# Tail container logs:
./deploy-vps.sh --logs
```

**What deploy-vps.sh does internally:**
1. `rsync` project files to VPS `/opt/mcps/<slug>/`
2. SSH to VPS, `docker build`, tag for registry, `docker push localhost:5000/<slug>:latest`
3. First deploy: Coolify API `POST /applications/dockerimage` — creates app with domain + HTTPS
4. Redeploy: Coolify API `POST /applications/<uuid>/restart` — pulls latest image
5. Saves Coolify app UUID in `.coolify-uuid` for subsequent deploys

**Configuration:** `deploy-vps.sh` reads credentials from `.env.deploy` (local) or falls back
to the repo root `.env` for `COOLIFY_API_TOKEN`. Template values are pre-filled by generator.

**Full manual process documented in:** `docs/VPS_DEPLOYMENT_RUNBOOK.md`

---

## Template Bugs Found & Fixed

### From First Agent (Bugs 1-9)

| # | Category | Problem | Status |
|---|----------|---------|--------|
| 1 | TS-CF | Wrong MCP architecture (no fetch handler) | FIXED |
| 2 | TS-CF | Missing `agents` dependency | FIXED |
| 3 | TS-CF | Missing `nodejs_compat` flag | FIXED |
| 4 | TS-CF | Missing Durable Objects config | FIXED |
| 5 | TS-CF | Wrong migration type for free plan | FIXED |
| 6 | TS-CF | `tsconfig.json` missing CF Workers types | FIXED |
| 7 | TS-CF | `logging.ts` uses `process.env` | NOT FIXED |
| 8 | TS-CF | Unnecessary `tsc` build step | FIXED |
| 9 | Generator | `.env` sourcing bug | NOT FIXED |

### From Second Agent — Current Session (Bugs 10-15)

#### 10. TS-VPS: Wrong `StreamableHTTPServerTransport` API + missing session management (FIXED)
- **Problem**: Template used old constructor signature incompatible with MCP SDK v1.26.0
- **Error**: `TS2559: Type '"/mcp"' has no properties in common with 'WebStandardStreamableHTTPServerTransportOptions'`
- **Fix**: Complete rewrite with session transport map, `isInitializeRequest()`, SSE/DELETE handlers
- **Files**: `generators/templates/typescript-vps/src/index.ts`

#### 11. Python-CF: Wrong server architecture for CF Workers (FIXED — template only)
- **Problem**: Standalone `FastMCP.run()` doesn't work on CF Workers
- **Fix**: Rewrote to `WorkerEntrypoint` + FastAPI + ASGI, switched to `pyproject.toml`
- **Files**: `generators/templates/python-cloudflare/src/server.py`, `wrangler.toml`, `pyproject.toml`
- **Note**: Correct architecture, but CF platform blocks external packages

#### 12. Python-VPS: Docker PYTHONPATH and CMD misconfiguration (FIXED)
- **Problem**: `CMD ["python", "-m", "src.server"]` fails — Python can't resolve `from tools import register_tools`
- **Fix**: `ENV PYTHONPATH=/app/src`, `CMD ["python", "-m", "server"]`
- **Files**: `generators/templates/python-vps/Dockerfile`

#### 13. Generator: Python-CF references `requirements.txt` but template uses `pyproject.toml` (FIXED)
- **Problem**: `create-mcp.sh` appends to `requirements.txt` for all Python projects
- **Fix**: Added `$TIER` checks — CF uses `pyproject.toml`, VPS uses `requirements.txt`
- **File**: `generators/create-mcp.sh`

#### 14. Python-VPS: No health endpoint on `/` (FIXED)
- **Problem**: `FastMCP.run()` only registers `/mcp`. No root health check for monitoring.
- **Fix**: Wrapped FastMCP in Starlette app with `/` and `/health` routes, mounted MCP app with `http_app(path="/mcp")`
- **Files**: `generators/templates/python-vps/src/server.py`

#### 15. Python-VPS: Starlette Mount causes 307 redirect on `/mcp` (FIXED)
- **Problem**: `Mount("/mcp", app=mcp_app)` redirects `/mcp` to `/mcp/` (307), breaking MCP clients
- **Fix**: Changed to `mcp.http_app(path="/mcp")` and `app.mount("/", mcp_app)` so FastMCP handles path matching directly
- **Files**: `generators/templates/python-vps/src/server.py`

---

## Root Template Files (Current State)

### `generators/templates/typescript-cloudflare/`
- `src/index.ts` — McpAgent pattern with fetch handler, /mcp and / routes
- `wrangler.toml` — DO bindings, sqlite migrations, nodejs_compat
- `package.json` — agents, @modelcontextprotocol/sdk, zod

### `generators/templates/python-cloudflare/`
- `src/server.py` — WorkerEntrypoint + FastAPI + FastMCP ASGI
- `wrangler.toml` — python_workers compat, observability
- `pyproject.toml` — fastmcp, fastapi deps

### `generators/templates/typescript-vps/`
- `src/index.ts` — HTTP server with StreamableHTTPServerTransport, full session management
- `Dockerfile` — Node 22 slim, multi-stage build
- `package.json` — @modelcontextprotocol/sdk, zod
- `.gitignore` — node_modules, dist, deploy state files

### `generators/templates/python-vps/`
- `src/server.py` — Starlette + FastMCP ASGI, health endpoints, uvicorn
- `Dockerfile` — Python 3.12 slim, PYTHONPATH=/app/src
- `requirements.txt` — fastmcp
- `.gitignore` — __pycache__, .venv, deploy state files

### `generators/templates/` (shared)
- `deploy-vps.sh` — Automated VPS deploy script (copied to VPS projects by generator)
- `env.deploy.example` — Deploy configuration template

---

## Known Issues (Still Open)

1. **Python CF Workers with packages not available** — CF platform limitation. Recommend Python-VPS instead.
2. **`logging.ts` uses `process.env` in CF Workers** (Bug #7) — Needs CF-specific version.
3. **`.env` sourcing bug in generator** (Bug #9) — Unquoted value interpreted as command.

## Recently Resolved

- ~~**Generator doesn't automate VPS deployment**~~ — DONE. `deploy-vps.sh` automates the full pipeline. Generator `--deploy` flag triggers first deploy automatically.

---

## Key Infrastructure Details

| Resource | Value |
|----------|-------|
| Coolify URL | `http://191.101.15.190:8000` |
| Coolify API Token | `4\|GwGrL8wLqUGdtUCiFJGfIVyxibPaO9AibkRz08umb1924af1` |
| Coolify Project UUID | `hcw40ckwss4gkgwkckc004wc` |
| Coolify Server UUID | `sggkws4cgwoo0kckk4oogcss` |
| Coolify Environment | `production` |
| Registry Service UUID | `l044ccwcg8484g8gcgww4kkk` |
| Registry Port | `localhost:5000` (VPS only) |
| MCP Wildcard Domain | `*.mcp.aimatrx.com` → `191.101.15.190` |
| CF Workers Subdomain | `*.arman-e37.workers.dev` |

---

## Testing Reference

```bash
# Health check
curl -s https://seo-tools-ts.mcp.aimatrx.com/

# MCP Initialize
curl --max-time 5 -s -D /tmp/h.txt -X POST $URL/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'

# Extract session, call tool
SESSION=$(grep -i mcp-session-id /tmp/h.txt | awk '{print $2}' | tr -d '\r')
curl --max-time 5 -s -X POST $URL/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "mcp-session-id: $SESSION" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"check_meta_title","arguments":{"title":"Test Title"}}}'
```
