#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# List all MCPs from the registry
# Usage: ./scripts/list-mcps.sh [--status active] [--tier cloudflare]
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
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

# --- Parse filters ---
FILTERS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --status) FILTERS="${FILTERS}&status=eq.$2"; shift 2 ;;
        --tier) FILTERS="${FILTERS}&tier=eq.$2"; shift 2 ;;
        --lang) FILTERS="${FILTERS}&language=eq.$2"; shift 2 ;;
        --json) JSON_OUTPUT=true; shift ;;
        *) echo -e "${RED}Unknown option: $1${NC}" >&2; exit 1 ;;
    esac
done

# --- Query Supabase ---
RESPONSE=$(curl -s \
    "${SUPABASE_URL}/rest/v1/mcp_registry?select=name,slug,language,tier,auth_type,status,endpoint_url,created_at${FILTERS}&order=created_at.desc" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    2>/dev/null)

if [[ "${JSON_OUTPUT:-false}" == "true" ]]; then
    echo "$RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$RESPONSE"
    exit 0
fi

# --- Pretty print ---
echo ""
echo -e "${CYAN}MCP Registry${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "%-25s %-12s %-12s %-10s %-10s %s\n" "NAME" "LANGUAGE" "TIER" "AUTH" "STATUS" "ENDPOINT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "$RESPONSE" | python3 -c "
import json, sys
data = json.load(sys.stdin)
if not data:
    print('  No MCPs found.')
else:
    for mcp in data:
        endpoint = mcp.get('endpoint_url') or '-'
        print(f\"  {mcp['name']:<23} {mcp['language']:<10} {mcp['tier']:<10} {mcp['auth_type']:<8} {mcp['status']:<8} {endpoint}\")
" 2>/dev/null || echo "  Error parsing response. Try --json flag."

echo ""
