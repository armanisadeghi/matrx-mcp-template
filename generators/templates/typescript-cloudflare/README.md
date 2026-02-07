# {{MCP_NAME}}

{{MCP_DESCRIPTION}}

## Development

```bash
npm install
npm run dev     # Local development
npm run deploy  # Deploy to Cloudflare Workers
```

## Adding Tools

Add new tools in `src/tools/index.ts` or create new files:

1. Create a tool file (e.g., `src/tools/my-tools.ts`)
2. Export a `registerMyTools(server: McpServer)` function
3. Import and call it in `src/tools/index.ts`

## Endpoint

`https://{{MCP_SLUG}}.your-account.workers.dev/mcp`
