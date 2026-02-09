from workers import WorkerEntrypoint
from fastapi import FastAPI
from fastmcp import FastMCP
import asgi

from tools import register_tools

# Create MCP server
mcp = FastMCP(
    name="{{MCP_NAME}}",
    instructions="{{MCP_DESCRIPTION}}"
)

register_tools(mcp)

# Create MCP ASGI app mounted at root (we'll mount it at /mcp in FastAPI)
mcp_app = mcp.http_app(path="/")

# Create FastAPI app with MCP lifespan (required for session management)
app = FastAPI(lifespan=mcp_app.lifespan)


@app.get("/")
async def health():
    return {
        "name": "{{MCP_NAME}}",
        "version": "1.0.0",
        "mcp_endpoint": "/mcp",
        "status": "running",
    }


# Mount MCP at /mcp
app.mount("/mcp", mcp_app)


# Cloudflare Workers entrypoint
class Default(WorkerEntrypoint):
    async def fetch(self, request):
        return await asgi.fetch(app, request, self.env)
