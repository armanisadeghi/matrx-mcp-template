#!/usr/bin/env bash
set -euo pipefail

# Registers a generated MCP in the one canonical East catalog: tool.mcp_server.
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

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
    echo "Registry update skipped: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY is unavailable."
    exit 0
fi
if [[ "$SUPABASE_URL" == *supabase.co* && "$SUPABASE_URL" != *brsgrqvjdzwihsvnfqkf* ]]; then
    echo "Refusing to register an MCP outside canonical Supabase East." >&2
    exit 1
fi

NAME=""; SLUG=""; DESCRIPTION="An MCP server"; LANG=""; TIER=""; AUTH="apikey"; DB="none"; SEPARATE_REPO="false"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --name) NAME="$2"; shift 2 ;;
        --slug) SLUG="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --lang) LANG="$2"; shift 2 ;;
        --tier) TIER="$2"; shift 2 ;;
        --auth) AUTH="$2"; shift 2 ;;
        --db) DB="$2"; shift 2 ;;
        --separate-repo) SEPARATE_REPO="true"; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done
[[ -n "$NAME" && -n "$SLUG" && -n "$LANG" && -n "$TIER" ]] || { echo "name, slug, lang, and tier are required" >&2; exit 1; }

case "$AUTH" in
    apikey) AUTH_STRATEGY="api_key" ;;
    supabase) AUTH_STRATEGY="bearer" ;;
    none) AUTH_STRATEGY="none" ;;
    *) echo "Unsupported auth strategy: $AUTH" >&2; exit 1 ;;
esac

PAYLOAD="$(python3 - "$NAME" "$SLUG" "$DESCRIPTION" "$AUTH_STRATEGY" "$LANG" "$TIER" "$AUTH" "$DB" "$SEPARATE_REPO" <<'PY'
import json, sys
name, slug, description, strategy, language, tier, auth, database, separate = sys.argv[1:]
print(json.dumps({
    "name": name, "slug": slug, "vendor": "AI Matrx", "description": description,
    "category": "developer", "transport": "http", "auth_strategy": strategy,
    "has_remote": False, "has_local": False, "status": "coming_soon",
    "metadata": {"managed_by": "matrx-mcp-factory", "language": language,
                 "hosting_target": tier, "auth_type": auth, "database_mode": database,
                 "separate_repository": separate == "true"},
}))
PY
)"

HTTP_CODE="$(curl --silent --output /dev/null --write-out '%{http_code}' \
    -X POST "${SUPABASE_URL}/rest/v1/mcp_server" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" -H "Content-Profile: tool" -d "$PAYLOAD")"

if [[ "$HTTP_CODE" == "201" ]]; then
    echo "Registered ${SLUG} in tool.mcp_server"
elif [[ "$HTTP_CODE" == "409" ]]; then
    echo "Registry row ${SLUG} already exists; it was not overwritten."
else
    echo "Registry update failed with HTTP ${HTTP_CODE}." >&2
    exit 1
fi
