def register_tools(mcp):
    """Import and register all tool modules."""
    from .table_tools import register
    register(mcp)
