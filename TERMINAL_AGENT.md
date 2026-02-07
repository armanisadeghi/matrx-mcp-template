# Terminal Agent Tasks

Tasks that can be done by a terminal-based AI agent in future sessions.

## Post-Setup Tasks (After Arman Completes Browser Tasks)

### After Cloudflare Account is Ready
- [ ] Run `wrangler deploy` in `examples/meta-tag-checker/` to test Cloudflare deployment
- [ ] Run `wrangler deploy` in `examples/pdf-tools/` to test with API key auth
- [ ] Set secrets via `wrangler secret put MCP_API_KEYS` for authenticated MCPs
- [ ] Verify MCP endpoints respond correctly with curl tests

### After VPS is Ready
- [ ] SSH into VPS and verify Coolify is running
- [ ] Deploy bug-tracker example via `docker compose up -d --build`
- [ ] Deploy virtual-tables example via `docker compose up -d --build`
- [ ] Test health endpoints and MCP endpoints with curl
- [ ] Install and configure Hostinger MCP server if API token is available

### Generator Testing
- [ ] Test the generator with all 4 template combinations:
  ```bash
  ./generators/create-mcp.sh --name "Test Python CF" --lang python --tier cloudflare --auth none
  ./generators/create-mcp.sh --name "Test TS CF" --lang typescript --tier cloudflare --auth apikey
  ./generators/create-mcp.sh --name "Test Python VPS" --lang python --tier vps --auth supabase --db supabase
  ./generators/create-mcp.sh --name "Test TS VPS" --lang typescript --tier vps --auth supabase --db postgres
  ```
- [ ] Verify generated MCPs have correct placeholder replacements
- [ ] Verify auth and DB modules are correctly copied
- [ ] Clean up test MCPs from `mcps/` directory

### First Real MCP
- [ ] Use the generator to scaffold the first real client MCP
- [ ] Add custom tools based on client requirements
- [ ] Deploy and test end-to-end

## Enhancement Ideas (Future)

- [ ] Add a `registry.json` file that tracks all deployed MCPs
- [ ] Create a `deploy.sh` helper script that handles both Cloudflare and Docker deployments
- [ ] Add GitHub Actions CI/CD for automatic deployment on push
- [ ] Add a simple health-check monitoring script that pings all MCP endpoints
- [ ] Consider adding rate limiting middleware to the shared utilities
