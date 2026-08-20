import os

import uvicorn
from fastmcp import FastMCP
from starlette.applications import Starlette
from starlette.requests import Request
from starlette.responses import JSONResponse
from starlette.routing import Route

from tools import register_tools

MCP_NAME = os.environ.get("MCP_NAME", "{{MCP_NAME}}")

mcp = FastMCP(
    name=MCP_NAME,
    instructions="{{MCP_DESCRIPTION}}",
    stateless_http=True,
)
register_tools(mcp)


async def health(request: Request) -> JSONResponse:
    return JSONResponse(
        {
            "name": MCP_NAME,
            "version": "1.0.0",
            "mcp_endpoint": "/mcp",
            "status": "running",
            "transport": "streamable-http-stateless",
        }
    )


mcp_app = mcp.http_app(path="/mcp")
app = Starlette(
    routes=[
        Route("/", endpoint=health, methods=["GET"]),
        Route("/health", endpoint=health, methods=["GET"]),
    ],
    lifespan=mcp_app.lifespan,
)
app.mount("/", mcp_app)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", "8000")))
