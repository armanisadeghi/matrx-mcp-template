#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# AI Matrx MCP Factory — VPS Deploy Script
# Builds, pushes, and deploys an MCP server to the VPS via Coolify API.
#
# Usage:
#   ./deploy-vps.sh              # Redeploy (build + push + restart)
#   ./deploy-vps.sh --create     # First-time deploy (creates Coolify app)
#   ./deploy-vps.sh --status     # Check deployment status
#   ./deploy-vps.sh --logs       # Tail container logs
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Configuration ---
# These are filled in by create-mcp.sh or can be overridden by .env.deploy
MCP_SLUG="{{MCP_SLUG}}"
MCP_NAME="{{MCP_NAME}}"
MCP_DOMAIN="{{MCP_DOMAIN}}"

VPS_IP="${VPS_IP:-191.101.15.190}"
VPS_USER="${VPS_USER:-root}"
VPS_MCP_DIR="/opt/mcps/${MCP_SLUG}"

REGISTRY_HOST="${REGISTRY_HOST:-localhost:5000}"
REGISTRY_USER="${REGISTRY_USER:-fi0fYTPXqNQJVaIm}"
REGISTRY_PASS="${REGISTRY_PASS:-pWA7R813XUDTt8AStO2xm99QBZgndLgh}"

COOLIFY_URL="${COOLIFY_URL:-http://191.101.15.190:8000}"
COOLIFY_TOKEN="${COOLIFY_TOKEN:-}"
COOLIFY_PROJECT_UUID="${COOLIFY_PROJECT_UUID:-hcw40ckwss4gkgwkckc004wc}"
COOLIFY_SERVER_UUID="${COOLIFY_SERVER_UUID:-sggkws4cgwoo0kckk4oogcss}"
COOLIFY_ENVIRONMENT="${COOLIFY_ENVIRONMENT:-production}"

# Coolify app UUID — set after first deploy, stored in .coolify-uuid
COOLIFY_APP_UUID=""

# --- Load .env.deploy if it exists (overrides above defaults) ---
if [[ -f "${SCRIPT_DIR}/.env.deploy" ]]; then
    set -a
    source "${SCRIPT_DIR}/.env.deploy"
    set +a
fi

# --- Load Coolify API token from parent .env if not set ---
if [[ -z "$COOLIFY_TOKEN" ]]; then
    REPO_ENV="${SCRIPT_DIR}/../../.env"
    if [[ -f "$REPO_ENV" ]]; then
        COOLIFY_TOKEN=$(grep '^COOLIFY_API_TOKEN=' "$REPO_ENV" | cut -d'=' -f2- | tr -d '"' | tr -d "'")
    fi
fi

# --- Load saved Coolify app UUID ---
UUID_FILE="${SCRIPT_DIR}/.coolify-uuid"
if [[ -f "$UUID_FILE" ]]; then
    COOLIFY_APP_UUID=$(cat "$UUID_FILE" | tr -d '[:space:]')
fi

# --- Helper Functions ---

error() { echo -e "${RED}Error: $1${NC}" >&2; exit 1; }
info() { echo -e "${GREEN}→${NC} $1"; }
warn() { echo -e "${YELLOW}!${NC} $1"; }

check_prerequisites() {
    [[ -z "$COOLIFY_TOKEN" ]] && error "COOLIFY_TOKEN not set. Add it to .env.deploy or the repo root .env file."
    command -v ssh >/dev/null 2>&1 || error "ssh not found"
    command -v rsync >/dev/null 2>&1 || error "rsync not found"
    command -v curl >/dev/null 2>&1 || error "curl not found"

    # Verify SSH connectivity
    if ! ssh -o ConnectTimeout=5 -o BatchMode=yes "${VPS_USER}@${VPS_IP}" "echo ok" >/dev/null 2>&1; then
        error "Cannot SSH to ${VPS_USER}@${VPS_IP}. Check your SSH key or VPS_IP."
    fi
}

coolify_api() {
    local method="$1"
    local endpoint="$2"
    local data="${3:-}"

    local args=(-s -X "$method"
        -H "Authorization: Bearer ${COOLIFY_TOKEN}"
        -H "Content-Type: application/json"
    )

    if [[ -n "$data" ]]; then
        args+=(-d "$data")
    fi

    curl "${args[@]}" "${COOLIFY_URL}/api/v1${endpoint}"
}

# --- Sync Files to VPS ---

sync_to_vps() {
    info "Syncing project files to VPS:${VPS_MCP_DIR}..."
    ssh "${VPS_USER}@${VPS_IP}" "mkdir -p ${VPS_MCP_DIR}"
    rsync -avz --delete \
        --exclude='node_modules' \
        --exclude='.venv' \
        --exclude='__pycache__' \
        --exclude='.git' \
        --exclude='.env' \
        --exclude='.env.deploy' \
        --exclude='.coolify-uuid' \
        "${SCRIPT_DIR}/" "${VPS_USER}@${VPS_IP}:${VPS_MCP_DIR}/"
    info "Files synced."
}

# --- Build and Push Image ---

build_and_push() {
    local IMAGE="${REGISTRY_HOST}/${MCP_SLUG}:latest"

    info "Building Docker image on VPS..."
    ssh "${VPS_USER}@${VPS_IP}" << BUILDEOF
set -e
cd ${VPS_MCP_DIR}
docker build -t ${IMAGE} .
echo "Build complete."

echo "Logging into registry..."
echo "${REGISTRY_PASS}" | docker login ${REGISTRY_HOST} -u "${REGISTRY_USER}" --password-stdin

echo "Pushing to registry..."
docker push ${IMAGE}
echo "Push complete."
BUILDEOF

    info "Image ${IMAGE} built and pushed to registry."
}

# --- Create Coolify Application (First Deploy) ---

create_coolify_app() {
    info "Creating Coolify application for ${MCP_SLUG}..."

    local RESPONSE
    RESPONSE=$(coolify_api POST "/applications/dockerimage" "{
        \"project_uuid\": \"${COOLIFY_PROJECT_UUID}\",
        \"environment_name\": \"${COOLIFY_ENVIRONMENT}\",
        \"server_uuid\": \"${COOLIFY_SERVER_UUID}\",
        \"name\": \"${MCP_SLUG}\",
        \"docker_registry_image_name\": \"${REGISTRY_HOST}/${MCP_SLUG}\",
        \"docker_registry_image_tag\": \"latest\",
        \"ports_exposes\": \"8000\",
        \"domains\": \"${MCP_DOMAIN}\",
        \"instant_deploy\": true
    }")

    # Extract UUID from response
    local UUID
    UUID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin).get('uuid',''))" 2>/dev/null || echo "")

    if [[ -z "$UUID" ]]; then
        echo "$RESPONSE"
        error "Failed to create Coolify application. Response above."
    fi

    COOLIFY_APP_UUID="$UUID"
    echo "$UUID" > "$UUID_FILE"
    info "Coolify application created. UUID: ${UUID}"
    info "Domain: ${MCP_DOMAIN}"
}

# --- Restart (Redeploy) ---

restart_app() {
    [[ -z "$COOLIFY_APP_UUID" ]] && error "No Coolify app UUID found. Run with --create first."

    info "Restarting Coolify application ${COOLIFY_APP_UUID}..."
    local RESPONSE
    RESPONSE=$(coolify_api POST "/applications/${COOLIFY_APP_UUID}/restart")
    info "Restart triggered. Coolify is pulling the latest image and restarting."
}

# --- Status Check ---

check_status() {
    [[ -z "$COOLIFY_APP_UUID" ]] && error "No Coolify app UUID found. Run with --create first."

    info "Checking application status..."
    local RESPONSE
    RESPONSE=$(coolify_api GET "/applications/${COOLIFY_APP_UUID}")
    echo "$RESPONSE" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print(f\"  Name:    {d.get('name', 'N/A')}\")
print(f\"  Status:  {d.get('status', 'N/A')}\")
print(f\"  Domain:  {d.get('fqdn', 'N/A')}\")
print(f\"  Image:   {d.get('docker_registry_image_name', 'N/A')}:{d.get('docker_registry_image_tag', 'N/A')}\")
print(f\"  UUID:    {d.get('uuid', 'N/A')}\")
" 2>/dev/null || echo "$RESPONSE"

    echo ""
    info "Health check:"
    local HEALTH
    HEALTH=$(curl -s --max-time 5 "${MCP_DOMAIN}/" 2>/dev/null || echo "UNREACHABLE")
    echo "  ${HEALTH}"
}

# --- Tail Logs ---

tail_logs() {
    [[ -z "$COOLIFY_APP_UUID" ]] && error "No Coolify app UUID found. Run with --create first."

    info "Fetching container logs from VPS..."
    ssh "${VPS_USER}@${VPS_IP}" "docker logs \$(docker ps -q -f name=${MCP_SLUG} | head -1) --tail 100 2>&1" || warn "Could not find running container for ${MCP_SLUG}"
}

# --- Main ---

ACTION="${1:-deploy}"

case "$ACTION" in
    --create)
        check_prerequisites
        sync_to_vps
        build_and_push
        create_coolify_app
        echo ""
        echo -e "${GREEN}First deploy complete!${NC}"
        echo -e "  URL:  ${CYAN}${MCP_DOMAIN}/mcp${NC}"
        echo -e "  UUID: ${CYAN}${COOLIFY_APP_UUID}${NC}"
        echo ""
        echo "Wait ~30 seconds for HTTPS provisioning, then verify:"
        echo "  curl ${MCP_DOMAIN}/"
        ;;
    --status)
        check_status
        ;;
    --logs)
        tail_logs
        ;;
    deploy|--deploy)
        check_prerequisites
        sync_to_vps
        build_and_push
        restart_app
        echo ""
        echo -e "${GREEN}Redeploy complete!${NC}"
        echo -e "  URL: ${CYAN}${MCP_DOMAIN}/mcp${NC}"
        echo ""
        echo "Wait ~15 seconds for restart, then verify:"
        echo "  curl ${MCP_DOMAIN}/"
        ;;
    --help|-h)
        echo ""
        echo -e "${CYAN}AI Matrx MCP — VPS Deploy Script${NC}"
        echo ""
        echo "Usage:"
        echo "  ./deploy-vps.sh              Redeploy (sync + build + push + restart)"
        echo "  ./deploy-vps.sh --create     First-time deploy (creates Coolify app)"
        echo "  ./deploy-vps.sh --status     Check deployment status and health"
        echo "  ./deploy-vps.sh --logs       Tail container logs"
        echo ""
        echo "Configuration:"
        echo "  Set VPS_IP, COOLIFY_TOKEN, etc. in .env.deploy or the repo root .env file."
        echo ""
        ;;
    *)
        error "Unknown action: ${ACTION}. Use --help for usage."
        ;;
esac
