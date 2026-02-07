from fastmcp import FastMCP
from tools import register_tools

mcp = FastMCP(
    name="Meta Tag Checker",
    instructions="SEO meta tag analysis and validation tools for marketing professionals."
)

register_tools(mcp)

if __name__ == "__main__":
    mcp.run(transport="streamable-http", host="0.0.0.0", port=8000)
