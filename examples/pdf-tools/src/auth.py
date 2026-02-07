import os
from functools import wraps

VALID_API_KEYS = set(
    key.strip()
    for key in os.environ.get("MCP_API_KEYS", "").split(",")
    if key.strip()
)

def validate_api_key(api_key: str) -> bool:
    return api_key in VALID_API_KEYS
