def register(mcp):
    @mcp.tool
    def hello(name: str) -> str:
        """Say hello to someone."""
        return f"Hello, {name}! This is the {{MCP_NAME}} MCP server."

    @mcp.tool
    def add(a: int, b: int) -> int:
        """Add two numbers together."""
        return a + b
