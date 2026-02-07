# Authentication Guide

## Overview

Each MCP chooses one of three authentication levels:

| Level | Flag | Use Case | How It Works |
|-------|------|----------|--------------|
| **None** | `--auth none` | Public utilities | No token required |
| **API Key** | `--auth apikey` | Client tools, internal agents | Shared secret in `Authorization: Bearer {key}` |
| **Supabase JWT** | `--auth supabase` | User-scoped data access | User's JWT passed through for RLS |

## No Authentication

For completely public MCPs. Anyone can call the tools.

```bash
./generators/create-mcp.sh --name "Calculator" --lang python --tier cloudflare --auth none
```

No setup required. Tools are open to all callers.

## API Key Authentication

For MCPs that should only be accessible to authorized agents or clients.

### Setup

1. Generate one or more API keys (any random string works):
   ```bash
   openssl rand -hex 32
   ```

2. Set the keys in your environment:
   ```bash
   # .env file
   MCP_API_KEYS=abc123key,def456key,ghi789key
   ```

3. For Cloudflare Workers, use secrets:
   ```bash
   wrangler secret put MCP_API_KEYS
   ```

### Client Configuration

Callers must include the key in the Authorization header:
```
Authorization: Bearer abc123key
```

In MCP client config (e.g., Claude Desktop):
```json
{
  "mcpServers": {
    "my-tool": {
      "url": "https://my-tool.workers.dev/mcp",
      "headers": {
        "Authorization": "Bearer abc123key"
      }
    }
  }
}
```

### Using in Tool Code

The `auth.py` / `auth.ts` module is automatically included when you use `--auth apikey`.

**Python:**
```python
from auth import require_api_key

def register(mcp):
    @mcp.tool
    @require_api_key
    async def my_protected_tool(data: str) -> str:
        """This tool requires an API key."""
        return f"Processed: {data}"
```

**TypeScript:**
```typescript
import { requireApiKey } from "../auth.js";

// Validate in tool handler
server.tool("my_tool", "Description", { data: z.string() }, async ({ data }, extra) => {
  requireApiKey(extra.request?.headers?.get("Authorization") ?? null);
  return { content: [{ type: "text", text: `Processed: ${data}` }] };
});
```

### Multiple Keys

You can issue different keys to different clients:
```bash
MCP_API_KEYS=client-a-key,client-b-key,internal-agent-key
```

Rotate keys by adding the new key, notifying the client, then removing the old key.

## Supabase JWT Authentication

For MCPs that access user-specific data. The calling agent passes the user's Supabase JWT, and the MCP uses it to make authenticated Supabase queries that respect Row Level Security (RLS).

### Setup

1. Set Supabase environment variables:
   ```bash
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_JWT_SECRET=your-jwt-secret          # Found in Supabase Dashboard → Settings → API
   SUPABASE_SERVICE_ROLE_KEY=your-service-role-key  # For admin operations (optional)
   ```

2. Generate your MCP with Supabase auth:
   ```bash
   ./generators/create-mcp.sh --name "My App" --lang python --tier vps --auth supabase --db supabase
   ```

### How It Works

1. User authenticates with your app (AI Matrx) via Supabase Auth
2. Your app's agent makes MCP tool calls, passing the user's JWT in the Authorization header
3. The MCP verifies the JWT against `SUPABASE_JWT_SECRET`
4. The MCP creates a Supabase client using the user's JWT → all queries respect RLS
5. The user can only access their own data

### Using in Tool Code

**Python:**
```python
from auth import require_supabase_auth
from supabase_client import get_user_supabase_client

def register(mcp):
    @mcp.tool
    @require_supabase_auth
    async def get_my_data(table: str, *, user_id: str = "", user_payload: dict = {}) -> dict:
        """Get data from a user's table."""
        # user_id and user_payload are injected by the decorator
        client = get_user_supabase_client(user_payload.get("token", ""))
        result = client.table(table).select("*").execute()
        return {"data": result.data}
```

**TypeScript:**
```typescript
import { requireSupabaseAuth } from "../auth.js";
import { getUserSupabaseClient } from "../supabase-client.js";

server.tool("get_my_data", "Get user data", { table: z.string() }, async ({ table }, extra) => {
  const token = extra.request?.headers?.get("Authorization")?.replace("Bearer ", "") ?? "";
  const user = await requireSupabaseAuth(extra.request?.headers?.get("Authorization") ?? null);
  const supabase = getUserSupabaseClient(token);
  const { data } = await supabase.from(table).select("*");
  return { content: [{ type: "text", text: JSON.stringify(data) }] };
});
```

## Mixed Authentication

Some MCPs may have tools with different auth requirements. For example:
- PDF conversion → public (no auth)
- User's saved PDFs → Supabase JWT required

Handle this per-tool by applying decorators selectively:

```python
def register(mcp):
    @mcp.tool
    def convert_pdf(pdf_base64: str) -> dict:
        """Public tool — no auth needed."""
        return do_conversion(pdf_base64)

    @mcp.tool
    @require_supabase_auth
    async def list_my_pdfs(*, user_id: str = "", **kwargs) -> dict:
        """Protected tool — requires user JWT."""
        return get_user_pdfs(user_id)
```

## Decision Matrix

| Scenario | Auth Level |
|----------|-----------|
| Public calculator / formatter | None |
| Client SEO tools | API Key |
| Internal automation agent | API Key |
| User's personal data | Supabase JWT |
| Admin operations | Supabase JWT + role check |
| Mix of public + private tools | Per-tool |
