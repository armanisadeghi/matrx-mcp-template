#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Update the status of an MCP in the registry
# Usage: ./scripts/update-mcp-status.sh --slug my-mcp --status active [--endpoint https://...]
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# --- Load env if available ---
if [[ -f "$REPO_ROOT/.env" ]]; then
    set -a
    source "$REPO_ROOT/.env"
    set +a
fi

# --- Validate ---
if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
    echo -e "${RED}Error: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set.${NC}"
    exit 1
fi

# --- Parse Arguments ---
SLUG=""
STATUS=""
ENDPOINT=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --slug) SLUG="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --endpoint) ENDPOINT="$2"; shift 2 ;;
        *) echo -e "${RED}Unknown option: $1${NC}" >&2; exit 1 ;;
    esac
done

if [[ -z "$SLUG" || -z "$STATUS" ]]; then
    echo "Usage: update-mcp-status.sh --slug <slug> --status <status> [--endpoint <url>]"
    echo ""
    echo "Status values: scaffolded, developing, deployed, active, inactive, deprecated"
    exit 1
fi

# --- Build JSON payload ---
PAYLOAD="{\"status\": \"$STATUS\""

if [[ -n "$ENDPOINT" ]]; then
    PAYLOAD="$PAYLOAD, \"endpoint_url\": \"$ENDPOINT\""
fi

if [[ "$STATUS" == "deployed" || "$STATUS" == "active" ]]; then
    PAYLOAD="$PAYLOAD, \"deployed_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\""
fi

PAYLOAD="$PAYLOAD}"

# --- Update in Supabase ---
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X PATCH "${SUPABASE_URL}/rest/v1/mcp_registry?slug=eq.${SLUG}" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" \
    -H "Prefer: return=representation" \
    -d "$PAYLOAD" 2>/dev/null || echo -e "\n000")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
    echo -e "${GREEN}✓${NC} Updated ${SLUG} → status: ${STATUS}"
    if [[ -n "$ENDPOINT" ]]; then
        echo -e "  Endpoint: ${ENDPOINT}"
    fi
else
    echo -e "${RED}Error: Failed to update ${SLUG} (HTTP $HTTP_CODE)${NC}"
    if [[ -n "$BODY" ]]; then
        echo "  Response: $BODY"
    fi
    exit 1
fi
