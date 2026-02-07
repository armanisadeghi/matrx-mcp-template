# AI Matrx MCP Factory

A monorepo template system for rapidly creating, deploying, and managing MCP (Model Context Protocol) servers. Spin up new MCPs in minutes with a single command.

## Architecture

**Two-tier deployment strategy:**

| Tier | Platform | Best For | Cost |
|------|----------|----------|------|
| **Cloudflare Workers** | Edge, global | Stateless utilities (SEO tools, text processing, formatters) | Free–$5/mo |
| **VPS + Coolify** | Docker containers | Stateful services (DB access, long-running ops, complex logic) | ~$7–15/mo |

Both tiers support **Python** (FastMCP) and **TypeScript** (official MCP SDK).

## Quick Start

```bash
# Create a new MCP
./generators/create-mcp.sh \
  --name "my-cool-tool" \
  --lang python \
  --tier cloudflare \
  --auth apikey \
  --description "A tool that does something useful"

# Output: ./mcps/my-cool-tool/ (ready to develop and deploy)
```

## Generator Options

| Flag | Required | Values | Default |
|------|----------|--------|---------|
| `--name` | Yes | Display name | — |
| `--lang` | Yes | `python` \| `typescript` | — |
| `--tier` | Yes | `cloudflare` \| `vps` | — |
| `--auth` | No | `none` \| `apikey` \| `supabase` | `apikey` |
| `--db` | No | `none` \| `supabase` \| `postgres` | `none` |
| `--description` | No | String | `"An MCP server"` |
| `--separate-repo` | No | Flag | `false` |

## Repository Structure

```
matrx-mcp-template/
├── generators/          # MCP scaffolding scripts and templates
│   ├── create-mcp.sh   # Main generator CLI
│   └── templates/       # Template files for each lang+tier combo
├── shared/              # Reusable auth, DB, and logging modules
│   ├── python/
│   └── typescript/
├── examples/            # Working example MCPs (copy & modify)
├── docs/                # Deployment and usage guides
├── infrastructure/      # VPS and Coolify setup configs
└── mcps/                # Generated MCPs land here (gitignored)
```

## Authentication

Three levels, chosen per-MCP:

- **None** — Public utilities, no token needed
- **API Key** — Shared secret in `Authorization: Bearer {key}` header
- **Supabase JWT** — User-scoped access via JWT pass-through

## Transport

All MCPs use **Streamable HTTP** (current MCP spec standard). Each MCP exposes its endpoint at `/mcp`.

## Deployment

### Cloudflare Workers
```bash
cd mcps/my-tool/
wrangler deploy
# Available at: https://my-tool.your-account.workers.dev/mcp
```

### VPS + Coolify
Push to GitHub → Coolify auto-deploys via Docker Compose → Available at `my-tool.mcp.yourdomain.com/mcp`

## Documentation

- [Cloudflare Deployment Guide](docs/DEPLOYMENT-CLOUDFLARE.md)
- [VPS Deployment Guide](docs/DEPLOYMENT-VPS.md)
- [Authentication Guide](docs/AUTH-GUIDE.md)
- [Adding Tools Guide](docs/ADDING-TOOLS.md)

## Examples

| Example | Tier | Language | Auth | Description |
|---------|------|----------|------|-------------|
| [meta-tag-checker](examples/meta-tag-checker/) | Cloudflare | Python | None | SEO meta tag analysis |
| [pdf-tools](examples/pdf-tools/) | Cloudflare | Python | API Key | PDF manipulation utilities |
| [bug-tracker](examples/bug-tracker/) | VPS | TypeScript | Supabase JWT | Bug tracking with DB |
| [virtual-tables](examples/virtual-tables/) | VPS | Python | Supabase JWT | Dynamic user data tables |
