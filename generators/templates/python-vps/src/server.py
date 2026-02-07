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
