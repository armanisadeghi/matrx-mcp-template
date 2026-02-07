def register_tools(mcp):
    """Import and register all tool modules."""
    from .example_tools import register
    register(mcp)
