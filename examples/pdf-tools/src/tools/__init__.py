def register_tools(mcp):
    """Import and register all tool modules."""
    from .pdf_tools import register
    register(mcp)
