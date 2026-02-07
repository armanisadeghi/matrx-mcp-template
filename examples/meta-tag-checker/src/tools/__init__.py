def register_tools(mcp):
    """Import and register all tool modules."""
    from .seo_tools import register
    register(mcp)
