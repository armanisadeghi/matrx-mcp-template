# AI Matrx MCP Factory — Complete Implementation Guide

## Purpose

This document contains all final decisions, architecture, and step-by-step instructions for building the AI Matrx MCP Factory system. It is designed to be consumed by a cloud-based AI agent that will implement everything.

**Repository:** `https://github.com/armanisadeghi/matrx-mcp-template.git`

---

## 1. Architecture Overview

The system uses a **two-tier deployment strategy**:

### Tier 1: Cloudflare Workers (Lightweight, Stateless MCPs)
- For simple utility MCPs (marketing tools, PDF manipulation, text processing, etc.)
- Near-zero cold starts, global edge deployment
- Free tier: 100,000 requests/day; Paid: $5/month for 10M requests
- Each MCP deploys as its own Worker at `{name}.workers.dev/mcp`
- Supports both Python and TypeScript

### Tier 2: Hostinger VPS + Coolify (Stateful, Complex MCPs)
- For MCPs that need database connections, long-running operations, or persistent state
- Hostinger KVM 2 plan (~$6.99–$10/month) with pre-installed Coolify template (Ubuntu 24.04)
- Each MCP runs as a Docker container managed by Coolify
- Each MCP gets its own subdomain via Coolify's Traefik/SSL: `{name}-mcp.yourdomain.com/mcp`
- Git-push deploys via GitHub integration
- Fixed cost, no timeout limits

### Hostinger-Specific Advantages
- **Pre-installed Coolify template**: Select "Ubuntu 24.04 with Coolify" during VPS onboarding
- **Public API**: Programmatic VPS management (start/stop/restart, metrics, backups, firewall, Docker containers, DNS)
- **Official MCP Server**: `npm install -g hostinger-api-mcp` — AI agents can manage the VPS directly
- **Kodee AI Assistant**: Built-in AI for VPS management via chat (200+ actions)
- Coolify accessible at `http://{vps-ip}:8000` after setup

---

## 2. Repository Structure

This is a **monorepo template** with generators. One repo, multiple MCP output targets.

```
matrx-mcp-template/
├── README.md
├── generators/                      # Scripts to scaffold new MCPs
│   ├── create-mcp.sh               # Main CLI: ./generators/create-mcp.sh --name "bug-tracker" --lang python --tier vps
│   └── templates/
│       ├── python-cloudflare/       # FastMCP + Cloudflare Worker (Python)
│       │   ├── src/
│       │   │   ├── server.py        # FastMCP server entry point
│       │   │   └── tools/           # Tool modules (one file per tool group)
│       │   │       └── __init__.py
│       │   ├── wrangler.toml        # Cloudflare Workers config
│       │   ├── requirements.txt
│       │   ├── .env.example
│       │   └── README.md
│       ├── typescript-cloudflare/   # TypeScript SDK + Cloudflare Worker
│       │   ├── src/
│       │   │   ├── index.ts         # MCP server entry point
│       │   │   └── tools/           # Tool modules
│       │   │       └── index.ts
│       │   ├── wrangler.toml
│       │   ├── package.json
│       │   ├── tsconfig.json
│       │   ├── .env.example
│       │   └── README.md
│       ├── python-vps/              # FastMCP + Docker (for Coolify/VPS)
│       │   ├── src/
│       │   │   ├── server.py
│       │   │   └── tools/
│       │   │       └── __init__.py
│       │   ├── Dockerfile
│       │   ├── docker-compose.yml
│       │   ├── requirements.txt
│       │   ├── .env.example
│       │   └── README.md
│       └── typescript-vps/          # TypeScript SDK + Docker (for Coolify/VPS)
│           ├── src/
│           │   ├── index.ts
│           │   └── tools/
│           │       └── index.ts
│           ├── Dockerfile
│           ├── docker-compose.yml
│           ├── package.json
│           ├── tsconfig.json
│           ├── .env.example
│           └── README.md
├── shared/                          # Shared utilities across all MCPs
│   ├── python/
│   │   ├── auth.py                  # Supabase JWT verification + API key auth
│   │   ├── supabase_client.py       # Reusable Supabase connection helper
│   │   └── logging_config.py        # Structured logging setup
│   └── typescript/
│       ├── auth.ts                  # Supabase JWT verification + API key auth
│       ├── supabase-client.ts       # Reusable Supabase connection helper
│       └── logging.ts              # Structured logging setup
├── examples/                        # Working example MCPs (copy & modify)
│   ├── meta-tag-checker/            # Simple stateless (Cloudflare, Python)
│   ├── pdf-tools/                   # Medium complexity (Cloudflare, Python)
│   ├── bug-tracker/                 # Stateful with DB (VPS, TypeScript)
│   └── virtual-tables/             # Complex with direct Supabase (VPS, Python)
├── docs/
│   ├── DEPLOYMENT-CLOUDFLARE.md     # Step-by-step Cloudflare deployment
│   ├── DEPLOYMENT-VPS.md            # Step-by-step Hostinger + Coolify deployment
│   ├── AUTH-GUIDE.md                # Authentication patterns explained
│   └── ADDING-TOOLS.md             # How to add new tools to an existing MCP
└── infrastructure/
    ├── hostinger-setup.md           # One-time VPS + Coolify setup instructions
    └── coolify-mcp-template.yml     # Coolify Docker Compose template for MCPs
```

### Workflow for Creating a New MCP

```bash
# From the template repo root:
./generators/create-mcp.sh \
  --name "client-marketing-tools" \
  --lang python \
  --tier cloudflare \
  --auth apikey \
  --description "SEO and marketing utility tools for client X"

# This creates a new directory: ./mcps/client-marketing-tools/
# with all boilerplate pre-filled, ready to add tools and deploy.
```

The generator should:
1. Copy the appropriate template
2. Replace placeholder values (name, description)
3. Set up the auth pattern chosen
4. Create the output in `./mcps/{name}/`
5. Optionally initialize as a separate git repo if `--separate-repo` flag is passed

For MCPs that need their own repo (client deliverables), use `--separate-repo` and the generator creates a standalone repo-ready directory that can be pushed to a new GitHub repo.

---

## 3. Authentication Strategy

Three auth tiers, chosen per-MCP:

### Tier A: No Auth (Open)
- For completely public utility MCPs
- No token required
- Use case: Simple calculators, public data formatters, open reference tools
- Flag: `--auth none`

### Tier B: API Key (Server-to-Server)
- Simple shared secret in the `Authorization: Bearer {key}` header
- The MCP server validates the key against an environment variable
- Use case: Internal tools, client-specific MCPs where the client's agent passes a pre-shared key
- Multiple keys can be supported (one per client/agent) stored as comma-separated env var
- Flag: `--auth apikey`

**Implementation (Python):**
```python
import os
from functools import wraps

VALID_API_KEYS = set(os.environ.get("MCP_API_KEYS", "").split(","))

def require_api_key(func):
    @wraps(func)
    async def wrapper(*args, **kwargs):
        # Extract from request context (FastMCP provides this)
        api_key = get_request_header("Authorization", "").replace("Bearer ", "")
        if api_key not in VALID_API_KEYS:
            raise PermissionError("Invalid API key")
        return await func(*args, **kwargs)
    return wrapper
```

### Tier C: Supabase JWT Pass-Through
- For MCPs that act on behalf of authenticated AI Matrx users
- The calling agent/client passes the user's Supabase JWT in the Authorization header
- The MCP server verifies the JWT against the Supabase project's JWT secret
- The MCP server can then use that JWT to make authenticated Supabase calls on behalf of the user
- Use case: Virtual tables MCP, bug tracker MCP, anything user-scoped
- Flag: `--auth supabase`

**Implementation (Python):**
```python
import os
import jwt
from supabase import create_client

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_JWT_SECRET = os.environ["SUPABASE_JWT_SECRET"]
SUPABASE_SERVICE_KEY = os.environ["SUPABASE_SERVICE_ROLE_KEY"]

def verify_supabase_token(token: str) -> dict:
    """Verify and decode a Supabase JWT. Returns the decoded payload."""
    try:
        payload = jwt.decode(
            token,
            SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            audience="authenticated"
        )
        return payload
    except jwt.InvalidTokenError as e:
        raise PermissionError(f"Invalid token: {e}")

def get_user_supabase_client(token: str):
    """Create a Supabase client authenticated as the user (respects RLS)."""
    return create_client(SUPABASE_URL, token)

def get_service_supabase_client():
    """Create a Supabase client with service role (bypasses RLS)."""
    return create_client(SUPABASE_URL, SUPABASE_SERVICE_KEY)
```

### Auth Decision Matrix

| MCP Type | Auth Level | Example |
|----------|-----------|---------|
| Public utility | None | Meta tag length checker |
| Client-specific tool | API Key | Marketing tools for Client X |
| Internal tool (agent-to-agent) | API Key | Bug review automation agent |
| User-scoped data access | Supabase JWT | Virtual tables, user bug submissions |
| Mixed (some tools public, some private) | Per-tool | PDF tools: convert=open, user-files=JWT |

---

## 4. Transport Protocol

**Use Streamable HTTP for ALL new MCPs.** SSE is deprecated as of the June 2025 MCP spec update.

- Cloudflare Workers: Streamable HTTP is natively supported
- VPS/Docker MCPs: FastMCP supports `mcp.run(transport="streamable-http")` 
- For MCP clients that don't yet support Streamable HTTP, the `mcp-remote` npm package can proxy it over stdio

**Endpoint convention:** All MCPs expose their endpoint at `/mcp` on their respective domain.

---

## 5. Template Details

### 5a. Python + Cloudflare Workers Template

**`src/server.py`:**
```python
from fastmcp import FastMCP
from tools import register_tools

mcp = FastMCP(
    name="{{MCP_NAME}}",
    instructions="{{MCP_DESCRIPTION}}"
)

# Register all tools from the tools/ directory
register_tools(mcp)

if __name__ == "__main__":
    mcp.run(transport="streamable-http", host="0.0.0.0", port=8000)
```

**`src/tools/__init__.py`:**
```python
def register_tools(mcp):
    """Import and register all tool modules."""
    from .example_tools import register
    register(mcp)
```

**`src/tools/example_tools.py`:**
```python
def register(mcp):
    @mcp.tool
    def hello(name: str) -> str:
        """Say hello to someone."""
        return f"Hello, {name}! This is the {{MCP_NAME}} MCP server."

    @mcp.tool
    def add(a: int, b: int) -> int:
        """Add two numbers together."""
        return a + b
```

**`wrangler.toml`:**
```toml
name = "{{MCP_SLUG}}"
main = "src/server.py"
compatibility_date = "2024-12-01"
compatibility_flags = ["python_workers"]

[vars]
MCP_NAME = "{{MCP_NAME}}"
```

**`requirements.txt`:**
```
fastmcp>=2.0,<3
```

### 5b. TypeScript + Cloudflare Workers Template

**`src/index.ts`:**
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { registerTools } from "./tools/index.js";

const server = new McpServer({
  name: "{{MCP_NAME}}",
  version: "1.0.0",
});

registerTools(server);

export default server;
```

**`src/tools/index.ts`:**
```typescript
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function registerTools(server: McpServer) {
  server.tool(
    "hello",
    "Say hello to someone",
    { name: z.string() },
    async ({ name }) => ({
      content: [{ type: "text", text: `Hello, ${name}!` }],
    })
  );

  server.tool(
    "add",
    "Add two numbers",
    { a: z.number(), b: z.number() },
    async ({ a, b }) => ({
      content: [{ type: "text", text: `${a + b}` }],
    })
  );
}
```

**`wrangler.toml`:**
```toml
name = "{{MCP_SLUG}}"
main = "src/index.ts"
compatibility_date = "2024-12-01"

[build]
command = "npm run build"
```

**`package.json`:**
```json
{
  "name": "{{MCP_SLUG}}",
  "version": "1.0.0",
  "private": true,
  "scripts": {
    "dev": "wrangler dev",
    "deploy": "wrangler deploy",
    "build": "tsc"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.12.0",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "@cloudflare/workers-types": "^4.0.0",
    "typescript": "^5.5.0",
    "wrangler": "^4.0.0"
  }
}
```

### 5c. Python + Docker/VPS Template

**`Dockerfile`:**
```dockerfile
FROM python:3.12-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/ ./src/

EXPOSE 8000

CMD ["python", "-m", "src.server"]
```

**`docker-compose.yml`:**
```yaml
version: '3.8'
services:
  mcp-server:
    build: .
    container_name: {{MCP_SLUG}}
    restart: always
    ports:
      - "${PORT:-8000}:8000"
    env_file:
      - .env
    environment:
      - MCP_NAME={{MCP_NAME}}
      - TRANSPORT=streamable-http
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/mcp"]
      interval: 30s
      timeout: 10s
      retries: 3
```

**`src/server.py` (VPS variant with optional Supabase):**
```python
import os
from fastmcp import FastMCP
from tools import register_tools

mcp = FastMCP(
    name=os.environ.get("MCP_NAME", "{{MCP_NAME}}"),
    instructions="{{MCP_DESCRIPTION}}"
)

register_tools(mcp)

if __name__ == "__main__":
    transport = os.environ.get("TRANSPORT", "streamable-http")
    host = os.environ.get("HOST", "0.0.0.0")
    port = int(os.environ.get("PORT", "8000"))
    mcp.run(transport=transport, host=host, port=port)
```

**`.env.example`:**
```bash
# MCP Server
MCP_NAME={{MCP_NAME}}
PORT=8000
TRANSPORT=streamable-http

# Auth (choose one or more)
MCP_API_KEYS=key1,key2,key3

# Supabase (if using Supabase auth or data access)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_JWT_SECRET=your-jwt-secret
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# Direct Postgres (rare — for MCPs with their own DB)
# DATABASE_URL=postgresql://user:pass@host:5432/dbname
```

### 5d. TypeScript + Docker/VPS Template

Same Docker structure as Python but with Node.js base image and TypeScript build step.

**`Dockerfile`:**
```dockerfile
FROM node:22-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:22-slim
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
EXPOSE 8000
CMD ["node", "dist/index.js"]
```

---

## 6. Database Access Patterns

MCPs that need data access have three options:

### Pattern A: Via AI Matrx API
- The MCP calls your existing AI Matrx REST/GraphQL endpoints
- Simplest; MCP is just a thin wrapper translating tool calls to API calls
- Auth: Pass the user's JWT or use a service API key

### Pattern B: Direct Supabase Client
- The MCP uses the Supabase client library directly
- Can use the user's JWT (respects RLS) or service role key (bypasses RLS)
- Best for: Virtual tables MCP, bug tracker MCP

### Pattern C: Direct PostgreSQL (Rare)
- For MCPs that have their own dedicated database
- Include postgres in the docker-compose.yml
- Best for: Isolated client systems, self-contained deployments
- Docker Compose includes a postgres service alongside the MCP

```yaml
# docker-compose.yml with local Postgres
version: '3.8'
services:
  mcp-server:
    build: .
    ports:
      - "${PORT:-8000}:8000"
    env_file:
      - .env
    depends_on:
      - db
  db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: ${DB_NAME:-mcpdata}
      POSTGRES_USER: ${DB_USER:-mcpuser}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"
volumes:
  pgdata:
```

---

## 7. Deployment Instructions

### 7a. Cloudflare Workers Deployment

**Prerequisites:**
- Cloudflare account (free tier works)
- `wrangler` CLI: `npm install -g wrangler`
- `wrangler login` to authenticate

**Deploy:**
```bash
cd mcps/{mcp-name}/
wrangler deploy
```

The MCP will be available at: `https://{mcp-slug}.{your-account}.workers.dev/mcp`

**Custom domain (optional):**
```bash
# In wrangler.toml, add:
# routes = [{ pattern = "mcp-name.yourdomain.com/*", zone_name = "yourdomain.com" }]
```

**Environment variables / secrets:**
```bash
wrangler secret put MCP_API_KEYS
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_JWT_SECRET
```

### 7b. Hostinger VPS + Coolify Deployment

**One-Time VPS Setup:**

1. Purchase Hostinger KVM 2 VPS (or higher)
2. During onboarding, select **"Ubuntu 24.04 with Coolify"** template
3. Create root password, note the VPS IP address
4. Access Coolify at `http://{vps-ip}:8000`
5. Create admin account on first access
6. Select "localhost" during onboarding (deploy to same server)
7. Configure a wildcard domain: Point `*.mcp.yourdomain.com` to your VPS IP via DNS A record
8. In Coolify, configure the domain and SSL (auto Let's Encrypt)

**Install Hostinger MCP Server for AI Management:**
```bash
npm install -g hostinger-api-mcp
```

Configure your AI agent (Claude Desktop, Cursor, etc.):
```json
{
  "mcpServers": {
    "hostinger-api": {
      "command": "hostinger-api-mcp",
      "env": {
        "DEBUG": "false",
        "API_TOKEN": "YOUR_HOSTINGER_API_TOKEN"
      }
    }
  }
}
```

**Deploy a New MCP to Coolify:**

1. Push the MCP code to GitHub (its own repo or a subdirectory)
2. In Coolify dashboard → New Resource → Docker Compose
3. Connect GitHub repo
4. Set environment variables in Coolify UI
5. Set domain: `{mcp-name}.mcp.yourdomain.com`
6. Deploy

Coolify auto-deploys on git push once connected.

**Alternatively, deploy via Coolify API (for full automation):**
Coolify has a REST API that AI agents can use to create and manage deployments programmatically.

---

## 8. MCP Specification Compliance

All MCPs generated by this template system MUST follow these rules:

### Protocol
- Use **Streamable HTTP** transport (not SSE, not stdio for production)
- Endpoint at `/mcp`
- JSON-RPC 2.0 over HTTP POST

### Tool Design
- Every tool must have a clear, descriptive `name` and `description`
- Input schemas use typed parameters (Zod for TypeScript, Python type hints for FastMCP)
- Tools should be idempotent where possible
- Return deterministic results for the same inputs
- Use pagination for list operations

### Error Handling
- Return structured errors with machine-readable codes
- Never leak internal details (stack traces, DB queries) in error messages
- Use proper MCP error codes

### Versioning
- Each MCP has a semantic version in its config
- Breaking changes to tool signatures require a version bump

---

## 9. Example MCP Implementations

### Example 1: Meta Tag Checker (Cloudflare, Python, No Auth)

```python
# src/tools/seo_tools.py
import re

def register(mcp):
    @mcp.tool
    def check_meta_title(title: str) -> dict:
        """Check if a meta title tag meets SEO best practices.
        Returns length, character count, and recommendations."""
        length = len(title)
        return {
            "title": title,
            "length": length,
            "status": "good" if 30 <= length <= 60 else "warning",
            "recommendation": (
                "Title is within the recommended 30-60 character range."
                if 30 <= length <= 60
                else f"Title is {length} characters. Aim for 30-60 characters."
            )
        }

    @mcp.tool
    def check_meta_description(description: str) -> dict:
        """Check if a meta description meets SEO best practices."""
        length = len(description)
        return {
            "description": description[:100] + "..." if length > 100 else description,
            "length": length,
            "status": "good" if 120 <= length <= 160 else "warning",
            "recommendation": (
                "Description is within the recommended 120-160 character range."
                if 120 <= length <= 160
                else f"Description is {length} characters. Aim for 120-160 characters."
            )
        }

    @mcp.tool
    def analyze_heading_structure(html: str) -> dict:
        """Analyze H1-H6 heading structure from HTML content."""
        headings = {}
        for level in range(1, 7):
            found = re.findall(f'<h{level}[^>]*>(.*?)</h{level}>', html, re.IGNORECASE | re.DOTALL)
            if found:
                headings[f"h{level}"] = [h.strip() for h in found]

        issues = []
        h1_count = len(headings.get("h1", []))
        if h1_count == 0:
            issues.append("Missing H1 tag")
        elif h1_count > 1:
            issues.append(f"Multiple H1 tags found ({h1_count}). Use only one.")

        return {
            "headings": headings,
            "issues": issues,
            "status": "good" if not issues else "warning"
        }
```

### Example 2: Bug Tracker MCP (VPS, TypeScript, Supabase JWT Auth)

```typescript
// src/tools/bug-tools.ts
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import { getSupabaseClient } from "../shared/supabase-client.js";

export function registerBugTools(server: McpServer) {
  server.tool(
    "submit_bug",
    "Submit a new bug report",
    {
      title: z.string().describe("Bug title"),
      description: z.string().describe("Detailed bug description"),
      severity: z.enum(["low", "medium", "high", "critical"]),
      app_name: z.string().describe("Which AI Matrx app this affects"),
    },
    async ({ title, description, severity, app_name }) => {
      const supabase = getSupabaseClient(); // Uses user JWT from request context
      const { data, error } = await supabase
        .from("bugs")
        .insert({ title, description, severity, app_name, status: "new" })
        .select()
        .single();

      if (error) throw new Error(`Failed to submit bug: ${error.message}`);

      return {
        content: [{
          type: "text",
          text: JSON.stringify({ id: data.id, status: "submitted", severity })
        }],
      };
    }
  );

  server.tool(
    "list_bugs",
    "List bugs with optional filters",
    {
      status: z.enum(["new", "reviewing", "in_progress", "resolved", "closed"]).optional(),
      severity: z.enum(["low", "medium", "high", "critical"]).optional(),
      app_name: z.string().optional(),
      limit: z.number().default(20),
    },
    async ({ status, severity, app_name, limit }) => {
      const supabase = getSupabaseClient();
      let query = supabase.from("bugs").select("*").limit(limit).order("created_at", { ascending: false });

      if (status) query = query.eq("status", status);
      if (severity) query = query.eq("severity", severity);
      if (app_name) query = query.eq("app_name", app_name);

      const { data, error } = await query;
      if (error) throw new Error(`Failed to list bugs: ${error.message}`);

      return {
        content: [{ type: "text", text: JSON.stringify(data) }],
      };
    }
  );

  server.tool(
    "update_bug_status",
    "Update the status of a bug (for automated agents or human-in-the-loop)",
    {
      bug_id: z.string().uuid(),
      status: z.enum(["reviewing", "in_progress", "needs_human", "resolved", "closed"]),
      notes: z.string().optional().describe("Optional notes about the status change"),
    },
    async ({ bug_id, status, notes }) => {
      const supabase = getSupabaseClient();
      const update: any = { status, updated_at: new Date().toISOString() };
      if (notes) update.status_notes = notes;

      const { data, error } = await supabase
        .from("bugs")
        .update(update)
        .eq("id", bug_id)
        .select()
        .single();

      if (error) throw new Error(`Failed to update bug: ${error.message}`);

      return {
        content: [{ type: "text", text: JSON.stringify({ id: data.id, status: data.status }) }],
      };
    }
  );
}
```

---

## 10. Generator Script Specification

The `create-mcp.sh` script (or a Python equivalent if preferred) must:

### Inputs (CLI flags):
| Flag | Required | Values | Default |
|------|----------|--------|---------|
| `--name` | Yes | String (display name) | — |
| `--lang` | Yes | `python` \| `typescript` | — |
| `--tier` | Yes | `cloudflare` \| `vps` | — |
| `--auth` | No | `none` \| `apikey` \| `supabase` | `apikey` |
| `--db` | No | `none` \| `supabase` \| `postgres` | `none` |
| `--description` | No | String | `"An MCP server"` |
| `--separate-repo` | No | Flag (boolean) | `false` |

### Behavior:
1. Derive `MCP_SLUG` from `--name` (lowercase, hyphens, no spaces)
2. Copy the appropriate template from `generators/templates/{lang}-{tier}/`
3. Replace all `{{MCP_NAME}}`, `{{MCP_SLUG}}`, `{{MCP_DESCRIPTION}}` placeholders
4. If `--auth supabase`, include the Supabase auth module from `shared/`
5. If `--auth apikey`, include the API key auth module from `shared/`
6. If `--db supabase`, include the Supabase client from `shared/` and add env vars to `.env.example`
7. If `--db postgres`, add the postgres service to `docker-compose.yml`
8. Output to `./mcps/{MCP_SLUG}/`
9. If `--separate-repo`, also initialize a git repo in the output directory
10. Print next steps (how to add tools, how to deploy)

---

## 11. Key Technical Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Python MCP framework | FastMCP 2.x | Fastest to write, production-ready, handles all protocol complexity |
| TypeScript MCP SDK | `@modelcontextprotocol/sdk` | Official SDK, best Cloudflare Workers support |
| Transport | Streamable HTTP | Current spec standard (June 2025); SSE is deprecated |
| Stateless hosting | Cloudflare Workers | Near-zero cold starts, free tier, global edge |
| Stateful hosting | Hostinger VPS + Coolify | Pre-installed Coolify template, API + MCP for AI management, Docker-native |
| Auth | 3-tier (none/apikey/supabase-jwt) | Covers all use cases from open to user-scoped |
| Database | Supabase (primary) or self-contained Postgres | Flexibility; most MCPs use existing Supabase |
| Repo strategy | Monorepo with generator + option for standalone | Fast iteration internally, clean deliverables for clients |
| MCP endpoint | `/mcp` on each domain | Convention for consistency |
| Logging | Structured JSON | Production-ready, parseable |

---

## 12. Naming Conventions

- **MCP display name**: Human-readable, e.g., "Marketing SEO Tools"
- **MCP slug**: Lowercase kebab-case, e.g., `marketing-seo-tools`
- **Cloudflare Worker name**: Same as slug
- **Docker container name**: Same as slug
- **Coolify subdomain**: `{slug}.mcp.yourdomain.com`
- **Tool names**: snake_case, e.g., `check_meta_title`, `submit_bug`
- **Tool descriptions**: Full sentences, describe what the tool does and what it returns

---

## 13. Security Checklist

For every MCP before production:

- [ ] Auth level chosen and implemented (none/apikey/supabase)
- [ ] Environment secrets stored in Cloudflare secrets or Coolify env vars (never in code)
- [ ] No sensitive data in tool responses (no stack traces, no raw SQL errors)
- [ ] Rate limiting considered (Cloudflare has built-in; for VPS, implement in FastMCP middleware or reverse proxy)
- [ ] CORS headers configured if browser-based clients will connect
- [ ] Input validation on all tool parameters (Zod/type hints handle this)
- [ ] For Supabase JWT MCPs: JWT verification happens BEFORE any data access
- [ ] For VPS MCPs: Coolify's Traefik handles SSL/TLS automatically
- [ ] Docker containers run as non-root user where possible

---

## 14. Cost Summary

| Component | Monthly Cost | Notes |
|-----------|-------------|-------|
| Cloudflare Workers (free tier) | $0 | Up to 100K requests/day per account |
| Cloudflare Workers (paid) | $5 | 10M requests/month, then $0.30/M |
| Hostinger KVM 2 VPS | ~$7–10 | 2 vCPU, 8GB RAM, 100GB NVMe, Coolify pre-installed |
| Hostinger KVM 4 VPS | ~$13–17 | 4 vCPU, 16GB RAM, 200GB NVMe (if scaling needed) |
| Custom domain | $7–15/year | For `*.mcp.yourdomain.com` wildcard |
| **Total (startup)** | **$7–15/month** | Covers dozens of MCPs |

---

## 15. Next Steps After Implementation

1. **Set up the Hostinger VPS** with the Coolify template
2. **Configure the Hostinger MCP server** so AI agents can manage the VPS
3. **Build the generator script** in the template repo
4. **Create the first MCP** (recommend starting with the meta-tag-checker as a proof of concept)
5. **Deploy to Cloudflare** to validate the Cloudflare workflow
6. **Deploy the bug-tracker MCP** to Coolify to validate the VPS workflow
7. **Document the workflows** so team members and AI agents can create new MCPs independently
