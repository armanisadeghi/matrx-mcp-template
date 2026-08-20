#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
load_env_value() {
    local key="$1" value
    [[ -n "${!key:-}" || ! -f "$REPO_ROOT/.env" ]] && return
    value="$(grep -m1 "^${key}=" "$REPO_ROOT/.env" 2>/dev/null | cut -d= -f2-)"
    value="${value%\"}"; value="${value#\"}"; value="${value%\'}"; value="${value#\'}"
    printf -v "$key" '%s' "$value"; export "$key"
}
load_env_value SUPABASE_URL
load_env_value SUPABASE_SERVICE_ROLE_KEY
[[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_SERVICE_ROLE_KEY:-}" ]] || { echo "Supabase registry credentials are required" >&2; exit 1; }
if [[ "$SUPABASE_URL" == *supabase.co* && "$SUPABASE_URL" != *brsgrqvjdzwihsvnfqkf* ]]; then
    echo "Refusing to list an MCP catalog outside canonical Supabase East." >&2
    exit 1
fi

curl --fail --silent --show-error \
    "${SUPABASE_URL}/rest/v1/mcp_server?select=name,slug,status,endpoint_url,metadata,created_at&vendor=eq.AI%20Matrx&order=created_at.desc" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Accept-Profile: tool" | python3 -m json.tool
