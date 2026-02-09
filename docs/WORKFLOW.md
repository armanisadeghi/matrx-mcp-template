# MCP Factory Workflow — From Code to Live Tool

This document walks through the complete process: starting from code you want to
expose as a tool, all the way to a live, globally-accessible MCP endpoint.

---

## Quick Reference

```
┌─────────────────────────────────────────────────────────────────┐
│  1. SCAFFOLD     ./generators/create-mcp.sh --name ... --tier   │
│  2. ADD TOOLS    Write functions in src/tools/                   │
│  3. TEST LOCAL   python -m server / npm run dev                  │
│  4. DEPLOY       ./deploy-vps.sh --create  (or wrangler deploy)  │
│  5. VERIFY       curl https://your-mcp.mcp.aimatrx.com/mcp      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Create the MCP Project

Run the generator from the repo root:

```bash
# Python + VPS (recommended for Python)
./generators/create-mcp.sh \
  --name "Image Optimizer" \
  --lang python \
  --tier vps \
  --auth none \
  --description "Image optimization and conversion tools"

# TypeScript + Cloudflare (recommended for lightweight tools)
./generators/create-mcp.sh \
  --name "Text Analyzer" \
  --lang typescript \
  --tier cloudflare \
  --auth apikey \
  --description "Text analysis and NLP tools"

# One-click: scaffold + deploy immediately
./generators/create-mcp.sh \
  --name "Image Optimizer" \
  --lang python \
  --tier vps \
  --deploy
```

**What this creates:**

```
mcps/image-optimizer/
├── src/
│   ├── server.py              # Server entrypoint (DO NOT EDIT — template handles this)
│   └── tools/
│       ├── __init__.py        # Tool registry (you ADD imports here)
│       └── example_tools.py   # Starter tools (you REPLACE with your tools)
├── Dockerfile                 # Container config (DO NOT EDIT)
├── requirements.txt           # Python dependencies (ADD yours here)
├── deploy-vps.sh             # Deploy script (VPS only)
├── .env.example              # Environment vars template
└── .gitignore
```

**Choose your tier:**

| Tier | Best For | Deploy Command | URL Pattern |
|------|----------|---------------|-------------|
| **VPS** | Python MCPs, heavy tools, DB access | `./deploy-vps.sh --create` | `https://{slug}.mcp.aimatrx.com/mcp` |
| **Cloudflare** | TypeScript, lightweight, edge-global | `npx wrangler deploy` | `https://{slug}.arman-e37.workers.dev/mcp` |

---

## Step 2: Add Your Tools

This is where your business logic goes. You only touch files in `src/tools/`.

### Python — The Pattern

Each tool is a function decorated with `@mcp.tool` inside a `register(mcp)` function:

```python
# src/tools/image_tools.py

def register(mcp):
    @mcp.tool
    def resize_image(url: str, width: int, height: int, format: str = "webp") -> dict:
        """Resize an image to the specified dimensions.

        Args:
            url: URL of the source image
            width: Target width in pixels
            height: Target height in pixels
            format: Output format (webp, png, jpg)
        """
        # YOUR CODE HERE — this is where your existing logic goes
        resized = do_resize(url, width, height, format)
        return {
            "original_url": url,
            "resized_url": resized.url,
            "dimensions": f"{width}x{height}",
            "format": format,
            "size_bytes": resized.size
        }

    @mcp.tool
    def analyze_image(url: str) -> dict:
        """Analyze image properties like dimensions, format, and file size."""
        info = get_image_info(url)
        return {
            "width": info.width,
            "height": info.height,
            "format": info.format,
            "size_kb": info.size / 1024
        }
```

**Key rules:**
- The function name becomes the tool name (snake_case)
- The docstring becomes the tool description (first line) and parameter descriptions (Args section)
- Type hints generate the input schema automatically
- Return any JSON-serializable value (dict, list, str, int, etc.)
- Optional parameters use `param: type = default`
- Nullable parameters use `param: type | None = None`

### Then Register It

```python
# src/tools/__init__.py

def register_tools(mcp):
    # Remove or keep example_tools as needed
    # from .example_tools import register as register_example
    # register_example(mcp)

    from .image_tools import register as register_image
    register_image(mcp)
```

### TypeScript — The Pattern

```typescript
// src/tools/text-tools.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function registerTextTools(server: McpServer) {
  server.tool(
    "analyze_sentiment",
    "Analyze the sentiment of a text passage",
    {
      text: z.string().describe("The text to analyze"),
      language: z.string().default("en").describe("ISO language code"),
    },
    async ({ text, language }) => {
      // YOUR CODE HERE
      const result = analyzeSentiment(text, language);
      return {
        content: [{
          type: "text",
          text: JSON.stringify({
            sentiment: result.sentiment,
            confidence: result.confidence,
            language,
          }),
        }],
      };
    }
  );
}
```

```typescript
// src/tools/index.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { registerTextTools } from "./text-tools.js";

export function registerTools(server: McpServer) {
  registerTextTools(server);
}
```

### Adding Dependencies

If your tools need external packages:

**Python (VPS):**
```bash
# Add to requirements.txt
echo "Pillow>=10.0.0" >> requirements.txt
echo "httpx>=0.27.0" >> requirements.txt
```

**TypeScript:**
```bash
npm install sharp axios
```

---

## Step 3: Test Locally

### Python VPS

```bash
cd mcps/image-optimizer/

# Install dependencies
pip install -r requirements.txt

# Run the server (PYTHONPATH is needed so imports resolve correctly)
PYTHONPATH=src python -m server
# Server runs at http://localhost:8000

# Test health endpoint
curl http://localhost:8000/

# Test MCP initialize
curl -X POST http://localhost:8000/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "initialize",
    "params": {
      "protocolVersion": "2025-03-26",
      "capabilities": {},
      "clientInfo": {"name": "test", "version": "1.0.0"}
    }
  }'
```

### TypeScript (VPS or Cloudflare)

```bash
cd mcps/text-analyzer/

# Install dependencies
npm install

# Run locally
npm run dev
# VPS: Server at http://localhost:8000
# CF:  Server at http://localhost:8787 (via wrangler)

# Same curl commands as above (change port to 8787 for CF)
```

### Docker Test (VPS templates only)

```bash
cd mcps/image-optimizer/
docker build -t test-mcp .
docker run -p 8000:8000 -e MCP_NAME="Image Optimizer" test-mcp
# Now test at http://localhost:8000/mcp
```

---

## Step 4: Deploy

### VPS Deployment (Python or TypeScript)

```bash
cd mcps/image-optimizer/

# First deploy — creates everything on the VPS
./deploy-vps.sh --create
# Output:
#   → Syncing project files to VPS...
#   → Building Docker image on VPS...
#   → Image built and pushed to registry.
#   → Coolify application created. UUID: abc123...
#   → Domain: https://image-optimizer.mcp.aimatrx.com
#
#   URL: https://image-optimizer.mcp.aimatrx.com/mcp

# After making code changes — redeploy
./deploy-vps.sh

# Check status
./deploy-vps.sh --status

# View logs
./deploy-vps.sh --logs
```

### Cloudflare Deployment (TypeScript only for production)

```bash
cd mcps/text-analyzer/

# Deploy
npx wrangler deploy
# URL: https://text-analyzer.arman-e37.workers.dev/mcp
```

---

## Step 5: Verify It's Live

```bash
URL="https://image-optimizer.mcp.aimatrx.com"

# 1. Health check
curl -s "$URL/"
# {"name":"Image Optimizer","version":"1.0.0","mcp_endpoint":"/mcp","status":"running"}

# 2. Initialize MCP session
curl -s -D /tmp/mcp-h.txt -X POST "$URL/mcp" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}'

# 3. Call a tool (using the session from step 2)
SESSION=$(grep -i mcp-session-id /tmp/mcp-h.txt | awk '{print $2}' | tr -d '\r')
curl -s -X POST "$URL/mcp" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "mcp-session-id: $SESSION" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"resize_image","arguments":{"url":"https://example.com/photo.jpg","width":800,"height":600}}}'
```

---

## Real-World Example: Converting Existing Code

Say you have a Python function that checks SEO meta tags:

```python
# Your existing code
def check_title(title: str) -> dict:
    char_count = len(title)
    pixel_width = char_count * 8.5  # simplified
    return {
        "characters": char_count,
        "pixel_width": pixel_width,
        "too_long": char_count > 60,
        "too_short": char_count < 30,
    }
```

**To make it an MCP tool:**

1. Generate the project:
   ```bash
   ./generators/create-mcp.sh --name "SEO Tools" --lang python --tier vps --auth none
   ```

2. Create `mcps/seo-tools/src/tools/seo_tools.py`:
   ```python
   def register(mcp):
       @mcp.tool
       def check_title(title: str) -> dict:
           """Check a page title against SEO best practices."""
           char_count = len(title)
           pixel_width = char_count * 8.5
           return {
               "characters": char_count,
               "pixel_width": pixel_width,
               "too_long": char_count > 60,
               "too_short": char_count < 30,
           }
   ```

3. Update `mcps/seo-tools/src/tools/__init__.py`:
   ```python
   def register_tools(mcp):
       from .seo_tools import register as register_seo
       register_seo(mcp)
   ```

4. Deploy:
   ```bash
   cd mcps/seo-tools
   ./deploy-vps.sh --create
   ```

That's it. Your function is now a live MCP tool at `https://seo-tools.mcp.aimatrx.com/mcp`.

---

## What You Should NOT Edit

The generator handles all boilerplate. These files should rarely need changes:

| File | Purpose | Edit? |
|------|---------|-------|
| `src/server.py` / `src/index.ts` | Server entrypoint, routing, ASGI/HTTP setup | No |
| `Dockerfile` | Container build | No (unless adding system deps) |
| `docker-compose.yml` | Container orchestration | No |
| `deploy-vps.sh` | Deployment automation | No |
| `wrangler.toml` | CF Workers config | No |

**What you DO edit:**

| File | Purpose |
|------|---------|
| `src/tools/*.py` or `src/tools/*.ts` | Your tool implementations |
| `src/tools/__init__.py` or `src/tools/index.ts` | Tool registration |
| `requirements.txt` or `package.json` | Add your dependencies |
| `.env` | Set runtime env vars (API keys, etc.) |

---

## Available Template Combinations

| Language | Tier | Status | Use When |
|----------|------|--------|----------|
| TypeScript | Cloudflare | Production | Lightweight tools, edge-global latency, no Docker |
| TypeScript | VPS | Production | Heavier tools, DB access, long-running operations |
| Python | VPS | Production | Python-native tools, ML/data science, external packages |
| Python | Cloudflare | Experimental | Not yet available — CF blocks external Python packages |
