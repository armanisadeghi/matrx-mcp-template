"""
Authentication utilities for MCP servers.
Supports: No auth, API key, and Supabase JWT verification.
"""

import os
from functools import wraps
from typing import Optional

# --- API Key Auth ---

VALID_API_KEYS = set(
    key.strip()
    for key in os.environ.get("MCP_API_KEYS", "").split(",")
    if key.strip()
)


def validate_api_key(api_key: str) -> bool:
    """Validate an API key against the configured keys."""
    return api_key in VALID_API_KEYS


def require_api_key(func):
    """Decorator to require a valid API key for a tool function."""

    @wraps(func)
    async def wrapper(*args, **kwargs):
        # FastMCP provides request context - extract Authorization header
        api_key = ""
        context = kwargs.get("context")
        if context and hasattr(context, "request"):
            auth_header = context.request.headers.get("Authorization", "")
            api_key = auth_header.replace("Bearer ", "").strip()

        if not validate_api_key(api_key):
            raise PermissionError("Invalid or missing API key")
        return await func(*args, **kwargs)

    return wrapper


# --- Supabase JWT Auth ---


def get_supabase_jwt_secret() -> str:
    """Get the Supabase JWT secret from environment."""
    secret = os.environ.get("SUPABASE_JWT_SECRET")
    if not secret:
        raise RuntimeError("SUPABASE_JWT_SECRET environment variable is not set")
    return secret


def verify_supabase_token(token: str) -> dict:
    """
    Verify and decode a Supabase JWT.
    Returns the decoded payload with user info.
    Raises PermissionError if the token is invalid.
    """
    try:
        import jwt
    except ImportError:
        raise RuntimeError("PyJWT is required for Supabase auth: pip install PyJWT")

    try:
        payload = jwt.decode(
            token,
            get_supabase_jwt_secret(),
            algorithms=["HS256"],
            audience="authenticated",
        )
        return payload
    except jwt.ExpiredSignatureError:
        raise PermissionError("Token has expired")
    except jwt.InvalidTokenError as e:
        raise PermissionError(f"Invalid token: {e}")


def extract_user_id(token: str) -> str:
    """Extract the user ID (sub claim) from a Supabase JWT."""
    payload = verify_supabase_token(token)
    user_id = payload.get("sub")
    if not user_id:
        raise PermissionError("Token does not contain a user ID")
    return user_id


def require_supabase_auth(func):
    """Decorator to require valid Supabase JWT authentication."""

    @wraps(func)
    async def wrapper(*args, **kwargs):
        token = ""
        context = kwargs.get("context")
        if context and hasattr(context, "request"):
            auth_header = context.request.headers.get("Authorization", "")
            token = auth_header.replace("Bearer ", "").strip()

        if not token:
            raise PermissionError("Missing Authorization header")

        payload = verify_supabase_token(token)
        kwargs["user_payload"] = payload
        kwargs["user_id"] = payload.get("sub")
        return await func(*args, **kwargs)

    return wrapper
