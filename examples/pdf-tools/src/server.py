from fastmcp import FastMCP
from tools import register_tools

mcp = FastMCP(
    name="PDF Tools",
    instructions="PDF manipulation and text extraction tools."
)

register_tools(mcp)

if __name__ == "__main__":
    mcp.run(transport="streamable-http", host="0.0.0.0", port=8000)
