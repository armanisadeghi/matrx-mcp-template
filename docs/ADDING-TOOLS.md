# Adding Tools to an MCP

## Python (FastMCP)

### Add a Tool to an Existing Module

Open the relevant file in `src/tools/` and add a new function:

```python
# src/tools/my_tools.py

def register(mcp):
    @mcp.tool
    def existing_tool(input: str) -> str:
        """Existing tool."""
        return f"Result: {input}"

    # Add your new tool here:
    @mcp.tool
    def my_new_tool(data: str, count: int = 10) -> dict:
        """Description of what this tool does.

        Args:
            data: The input data to process
            count: Number of results to return (default: 10)
        """
        # Your implementation
        return {"result": data, "count": count}
```

### Create a New Tool Module

1. Create a new file:

```python
# src/tools/analytics_tools.py

def register(mcp):
    @mcp.tool
    def track_event(event_name: str, properties: dict | None = None) -> dict:
        """Track an analytics event."""
        return {
            "event": event_name,
            "properties": properties or {},
            "status": "tracked"
        }

    @mcp.tool
    def get_metrics(metric_name: str, period: str = "7d") -> dict:
        """Get metrics for a given period."""
        return {
            "metric": metric_name,
            "period": period,
            "value": 0  # Replace with real query
        }
```

2. Register it in `src/tools/__init__.py`:

```python
def register_tools(mcp):
    from .my_tools import register as register_my_tools
    from .analytics_tools import register as register_analytics

    register_my_tools(mcp)
    register_analytics(mcp)
```

### Tool Parameter Types

FastMCP uses Python type hints for schema generation:

```python
@mcp.tool
def example(
    name: str,                          # Required string
    count: int = 10,                    # Optional int with default
    tags: list[str] | None = None,      # Optional list of strings
    config: dict | None = None,         # Optional object
    mode: str = "fast",                 # String with default
) -> dict:
    """Tool description goes here."""
    ...
```

### Returning Results

Return any JSON-serializable value:

```python
@mcp.tool
def my_tool(input: str) -> str:
    return "Simple string result"

@mcp.tool
def my_tool(input: str) -> dict:
    return {"key": "value", "nested": {"data": [1, 2, 3]}}

@mcp.tool
def my_tool(input: str) -> list:
    return [{"item": 1}, {"item": 2}]
```

## TypeScript (MCP SDK)

### Add a Tool to an Existing Module

```typescript
// src/tools/index.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function registerTools(server: McpServer) {
  // Existing tool
  server.tool("existing_tool", "Description", { input: z.string() }, async ({ input }) => ({
    content: [{ type: "text", text: `Result: ${input}` }],
  }));

  // Add your new tool:
  server.tool(
    "my_new_tool",
    "Description of what this tool does",
    {
      data: z.string().describe("The input data to process"),
      count: z.number().default(10).describe("Number of results"),
    },
    async ({ data, count }) => ({
      content: [{ type: "text", text: JSON.stringify({ result: data, count }) }],
    })
  );
}
```

### Create a New Tool Module

1. Create a new file:

```typescript
// src/tools/analytics-tools.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function registerAnalyticsTools(server: McpServer) {
  server.tool(
    "track_event",
    "Track an analytics event",
    {
      event_name: z.string(),
      properties: z.record(z.unknown()).optional(),
    },
    async ({ event_name, properties }) => ({
      content: [{
        type: "text",
        text: JSON.stringify({ event: event_name, properties, status: "tracked" }),
      }],
    })
  );
}
```

2. Import in `src/tools/index.ts`:

```typescript
import { registerAnalyticsTools } from "./analytics-tools.js";

export function registerTools(server: McpServer) {
  // ... existing tools ...
  registerAnalyticsTools(server);
}
```

### Zod Schema Patterns

```typescript
// String
{ name: z.string().describe("User's name") }

// Number with default
{ count: z.number().default(10) }

// Enum
{ severity: z.enum(["low", "medium", "high", "critical"]) }

// Optional
{ notes: z.string().optional() }

// UUID
{ id: z.string().uuid() }

// Array
{ tags: z.array(z.string()) }

// Object
{ config: z.object({ key: z.string(), value: z.unknown() }) }

// Record (dynamic keys)
{ metadata: z.record(z.string()) }
```

## Naming Conventions

- **Tool names:** `snake_case` — e.g., `check_meta_title`, `submit_bug`
- **Descriptions:** Full sentences — "Check if a meta title meets SEO best practices"
- **Parameters:** Descriptive names with `.describe()` (TS) or docstrings (Python)

## Testing Tools Locally

### Python
```bash
python -m src.server
# Server runs at http://localhost:8000/mcp

# Test with curl:
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/call","params":{"name":"my_tool","arguments":{"input":"test"}},"id":1}'
```

### TypeScript
```bash
npm run dev
# Test same way with curl
```

## Error Handling

Return clear errors without leaking internals:

```python
@mcp.tool
def my_tool(id: str) -> dict:
    try:
        result = fetch_data(id)
        if not result:
            return {"error": "Not found", "id": id}
        return result
    except Exception:
        return {"error": "Failed to process request"}
```

```typescript
server.tool("my_tool", "Description", { id: z.string() }, async ({ id }) => {
  try {
    const result = await fetchData(id);
    return { content: [{ type: "text", text: JSON.stringify(result) }] };
  } catch {
    return {
      content: [{ type: "text", text: JSON.stringify({ error: "Failed to process request" }) }],
      isError: true,
    };
  }
});
```
