# {{MCP_NAME}}

{{MCP_DESCRIPTION}}

## Development

```bash
npm install
npm run dev     # Local development with hot reload
npm run build   # Build for production
npm start       # Run production build

# Docker
docker compose up --build
```

## Adding Tools

Add new tools in `src/tools/index.ts` or create new files:

1. Create a tool file (e.g., `src/tools/my-tools.ts`)
2. Export a register function
3. Import and call it in `src/tools/index.ts`

## Endpoint

`https://{{MCP_SLUG}}.mcp.yourdomain.com/mcp`
