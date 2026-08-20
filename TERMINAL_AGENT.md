# Terminal / Coding Agent Tasks

## ✅ Done
- **Task 1: MCP catalog integration** — The generator uses canonical East `tool.mcp_server` through
  `register-mcp.sh`, `update-mcp-status.sh`, and `list-mcps.sh`. Do not recreate `public.mcp_registry`.
- **Task 2: AWS hosting** — `--tier aws` generates a stateless App Runner container and `deploy-aws.sh`.
  The account baseline is `matrx-ship/infrastructure/aws/mcp-hosting`. No customer service is deployed by default.

---

### Task 3: CI/CD Pipeline
**Priority:** Low (after first manual deployments)

GitHub Actions for auto-deploying MCPs:
1. CF Workers deploy on push to `mcps/{name}/` for CF-tier MCPs
2. Docker build + push for VPS-tier MCPs
3. Immutable ECR/App Runner deployment for AWS-tier MCPs through workload identity
4. Canonical catalog status update after deploy

---

### Task 4: Unified Deploy Helper/API
**Priority:** Medium

Unified `scripts/deploy-mcp.sh`:
1. Auto-detect Cloudflare, VPS/Coolify, or AWS App Runner
2. Route to the already-working target-native deployer
3. Return one machine-readable deployment result and update `tool.mcp_server`

The canonical requirements are `common-docs/systems/mcp-hosting/FEATURE.md`.
