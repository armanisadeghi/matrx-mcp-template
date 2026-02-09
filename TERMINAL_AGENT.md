# Terminal / Coding Agent Tasks

## ✅ Done
- **Task 1: MCP Registry System** — Registry table (`mcp_registry`) created in Supabase with RLS. Scripts: `register-mcp.sh`, `update-mcp-status.sh`, `list-mcps.sh`. Generator auto-registers. Schema: UUID id, name, slug (unique), description, language, tier, auth_type, db_type, endpoint_url, status, repo_url, is_separate_repo, timestamps, metadata JSONB.

---

### Task 2: CI/CD Pipeline
**Priority:** Low (after first manual deployments)

GitHub Actions for auto-deploying MCPs:
1. CF Workers deploy on push to `mcps/{name}/` for CF-tier MCPs
2. Docker build + push for VPS-tier MCPs
3. Registry status update after deploy

---

### Task 3: Deploy Helper Script
**Priority:** Medium

Unified `scripts/deploy-mcp.sh`:
1. Auto-detect tier (`wrangler.toml` = CF, `docker-compose.yml` = VPS)
2. CF: `wrangler deploy` | VPS: Docker build → push → trigger Coolify redeploy
3. Update registry status after deploy

## Pending
- 
