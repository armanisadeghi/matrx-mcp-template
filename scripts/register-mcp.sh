#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Register an MCP in the Supabase registry
# Called by create-mcp.sh after scaffolding, or manually.
# Requires SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in environment or .env
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
    echo -e "${YELLOW}Warning: SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set.${NC}"
    echo "Registry update skipped. Set these in .env or environment to enable auto-registration."
    exit 0  # Soft fail — don't block MCP creation
fi

# --- Parse Arguments ---
NAME=""
SLUG=""
DESCRIPTION="An MCP server"
LANG=""
TIER=""
AUTH="apikey"
DB="none"
SEPARATE_REPO="false"

while [[ $# -gt 0 ]]; do
    case $1 in
        --name) NAME="$2"; shift 2 ;;
        --slug) SLUG="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --lang) LANG="$2"; shift 2 ;;
        --tier) TIER="$2"; shift 2 ;;
        --auth) AUTH="$2"; shift 2 ;;
        --db) DB="$2"; shift 2 ;;
        --separate-repo) SEPARATE_REPO="true"; shift ;;
        *) echo -e "${RED}Unknown option: $1${NC}" >&2; exit 1 ;;
    esac
done

if [[ -z "$NAME" || -z "$SLUG" || -z "$LANG" || -z "$TIER" ]]; then
    echo "Usage: register-mcp.sh --name <name> --slug <slug> --lang <lang> --tier <tier> [--auth <auth>] [--db <db>] [--description <desc>] [--separate-repo]"
    exit 1
fi

# --- Build JSON payload ---
PAYLOAD=$(cat <<EOF
{
    "name": "$NAME",
    "slug": "$SLUG",
    "description": "$DESCRIPTION",
    "language": "$LANG",
    "tier": "$TIER",
    "auth_type": "$AUTH",
    "db_type": "$DB",
    "is_separate_repo": $SEPARATE_REPO,
    "status": "scaffolded"
}
EOF
)

# --- Upsert to Supabase ---
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST "${SUPABASE_URL}/rest/v1/mcp_registry" \
    -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
    -H "Content-Type: application/json" \
    -H "Prefer: resolution=merge-duplicates" \
    "$PAYLOAD" 2>/dev/null || echo -e "\n000")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 300 ]]; then
    echo -e "${GREEN}→${NC} Registered in MCP registry: ${SLUG}"
else
    echo -e "${YELLOW}Warning: Registry update failed (HTTP $HTTP_CODE). MCP was still created.${NC}"
    if [[ -n "$BODY" ]]; then
        echo "  Response: $BODY"
    fi
fi
