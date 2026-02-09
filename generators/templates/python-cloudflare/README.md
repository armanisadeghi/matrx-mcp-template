# {{MCP_NAME}}

> **EXPERIMENTAL** — Python + Cloudflare Workers with external packages is not yet
> generally available on the Cloudflare platform. This template is architecturally
> correct and will work once Cloudflare enables Python package support for your account.
> For production Python MCPs, use the **VPS** tier instead.

{{MCP_DESCRIPTION}}

## Development

```bash
# Install dependencies
uv sync

# Run locally (Cloudflare dev server)
uv run pywrangler dev

# Deploy to Cloudflare Workers (requires Python packages access)
uv run pywrangler deploy
```

## Adding Tools

Add new tool modules in `src/tools/`:

1. Create a new file (e.g., `src/tools/my_tools.py`)
2. Define a `register(mcp)` function with your `@mcp.tool` decorated functions
3. Import and call it in `src/tools/__init__.py`

See `docs/ADDING-TOOLS.md` in the parent repo for detailed examples.

## Endpoint

`https://{{MCP_SLUG}}.your-account.workers.dev/mcp`

## Platform Status

This template requires Cloudflare to support external Python packages in Workers.
As of early 2026, this feature is in limited beta. If `uv run pywrangler deploy` fails
with "You cannot yet deploy Python Workers that depend on packages", your account
does not have access. Use `--tier vps` instead for immediate production deployment.
