#!/usr/bin/env bash
set -euo pipefail

# Updates endpoint and lifecycle in the canonical East tool.mcp_server catalog.
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
    echo "Refusing to update an MCP outside canonical Supabase East." >&2
    exit 1
fi

SLUG=""; STATUS=""; ENDPOINT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --slug) SLUG="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --endpoint) ENDPOINT="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done
[[ -n "$SLUG" && -n "$STATUS" ]] || { echo "slug and status are required" >&2; exit 1; }
case "$STATUS" in
    scaffolded|developing) CATALOG_STATUS="coming_soon" ;;
    deployed|active) CATALOG_STATUS="active" ;;
    deprecated) CATALOG_STATUS="deprecated" ;;
    *) echo "Unsupported status: $STATUS" >&2; exit 1 ;;
esac

PAYLOAD="$(python3 - "$CATALOG_STATUS" "$ENDPOINT" <<'PY'
import datetime, json, sys
status, endpoint = sys.argv[1:]
payload = {"status": status, "has_remote": bool(endpoint),
           "updated_at": datetime.datetime.now(datetime.timezone.utc).isoformat()}
if endpoint:
    payload["endpoint_url"] = endpoint
print(json.dumps(payload))
PY
)"

RESPONSE="$(curl --silent --write-out $'\n%{http_code}' \
    -X PATCH "${SUPABASE_URL}/rest/v1/mcp_server?slug=eq.${SLUG}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" -H "Content-Profile: tool" \
    -H "Prefer: return=representation" -d "$PAYLOAD")"
HTTP_CODE="$(printf '%s' "$RESPONSE" | tail -1)"
BODY="$(printf '%s' "$RESPONSE" | sed '$d')"
[[ "$HTTP_CODE" == "200" ]] || { echo "Registry update failed with HTTP ${HTTP_CODE}" >&2; exit 1; }
[[ "$BODY" != "[]" ]] || { echo "No MCP catalog row matched ${SLUG}" >&2; exit 1; }
echo "Updated ${SLUG} in tool.mcp_server"
