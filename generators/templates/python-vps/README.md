# {{MCP_NAME}}

{{MCP_DESCRIPTION}}

## Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
python -m src.server

# Run with Docker
docker compose up --build

# Deploy: Push to GitHub, Coolify auto-deploys
```

## Adding Tools

Add new tool modules in `src/tools/`:

1. Create a new file (e.g., `src/tools/my_tools.py`)
2. Define a `register(mcp)` function with your tools
3. Import and call it in `src/tools/__init__.py`

## Endpoint

`https://{{MCP_SLUG}}.mcp.yourdomain.com/mcp`
