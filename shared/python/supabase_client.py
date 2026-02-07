"""
Supabase client helpers for MCP servers.
Provides both user-scoped (RLS-respecting) and service-role clients.
"""

import os
from typing import Optional


def _get_env(key: str) -> str:
    """Get a required environment variable."""
    value = os.environ.get(key)
    if not value:
        raise RuntimeError(f"{key} environment variable is not set")
    return value


def get_supabase_url() -> str:
    """Get the Supabase project URL."""
    return _get_env("SUPABASE_URL")


def get_user_supabase_client(user_jwt: str):
    """
    Create a Supabase client authenticated as the user.
    This client respects Row Level Security (RLS) policies.
    """
    try:
        from supabase import create_client
    except ImportError:
        raise RuntimeError("supabase-py is required: pip install supabase")

    return create_client(get_supabase_url(), user_jwt)


def get_service_supabase_client():
    """
    Create a Supabase client with the service role key.
    This client BYPASSES Row Level Security (RLS).
    Use with caution — only for admin operations.
    """
    try:
        from supabase import create_client
    except ImportError:
        raise RuntimeError("supabase-py is required: pip install supabase")

    return create_client(get_supabase_url(), _get_env("SUPABASE_SERVICE_ROLE_KEY"))
