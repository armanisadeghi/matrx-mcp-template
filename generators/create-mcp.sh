#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# AI Matrx MCP Factory — Generator Script
# Creates a new MCP server from templates with all boilerplate pre-filled.
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# --- Defaults ---
AUTH="apikey"
DB="none"
DESCRIPTION="An MCP server"
SEPARATE_REPO=false
NAME=""
LANG=""
TIER=""

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Platform Detection ---
IS_MACOS=false
[[ "$(uname)" == "Darwin" ]] && IS_MACOS=true

# Helper: cross-platform sed -i
sed_i() {
    if $IS_MACOS; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# --- Functions ---

usage() {
    cat <<EOF
${CYAN}AI Matrx MCP Factory — Create a new MCP server${NC}

Usage:
  ./generators/create-mcp.sh --name <name> --lang <language> --tier <tier> [options]

Required:
  --name <name>          Display name for the MCP (e.g., "Marketing SEO Tools")
  --lang <language>      Language: python | typescript
  --tier <tier>          Deployment tier: cloudflare | vps

Options:
  --auth <type>          Auth type: none | apikey | supabase (default: apikey)
  --db <type>            Database: none | supabase | postgres (default: none)
  --description <desc>   MCP description (default: "An MCP server")
  --separate-repo        Initialize as a standalone git repo
  --help                 Show this help message

Examples:
  # Simple Cloudflare Worker with API key auth
  ./generators/create-mcp.sh \\
    --name "Meta Tag Checker" \\
    --lang python \\
    --tier cloudflare \\
    --auth none \\
    --description "SEO meta tag analysis tools"

  # VPS-deployed MCP with Supabase auth and DB
  ./generators/create-mcp.sh \\
    --name "Bug Tracker" \\
    --lang typescript \\
    --tier vps \\
    --auth supabase \\
    --db supabase \\
    --description "Bug tracking and management tools"

  # Standalone repo for client delivery
  ./generators/create-mcp.sh \\
    --name "Client Marketing Tools" \\
    --lang python \\
    --tier cloudflare \\
    --auth apikey \\
    --separate-repo
EOF
    exit 0
}

error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

info() {
    echo -e "${GREEN}→${NC} $1"
}

warn() {
    echo -e "${YELLOW}!${NC} $1"
}

slugify() {
    echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

# --- Parse Arguments ---

while [[ $# -gt 0 ]]; do
    case $1 in
        --name) NAME="$2"; shift 2 ;;
        --lang) LANG="$2"; shift 2 ;;
        --tier) TIER="$2"; shift 2 ;;
        --auth) AUTH="$2"; shift 2 ;;
        --db) DB="$2"; shift 2 ;;
        --description) DESCRIPTION="$2"; shift 2 ;;
        --separate-repo) SEPARATE_REPO=true; shift ;;
        --help) usage ;;
        *) error "Unknown option: $1" ;;
    esac
done

# --- Validate Inputs ---

[[ -z "$NAME" ]] && error "Missing required flag: --name"
[[ -z "$LANG" ]] && error "Missing required flag: --lang"
[[ -z "$TIER" ]] && error "Missing required flag: --tier"

[[ "$LANG" != "python" && "$LANG" != "typescript" ]] && error "Invalid --lang: must be 'python' or 'typescript'"
[[ "$TIER" != "cloudflare" && "$TIER" != "vps" ]] && error "Invalid --tier: must be 'cloudflare' or 'vps'"
[[ "$AUTH" != "none" && "$AUTH" != "apikey" && "$AUTH" != "supabase" ]] && error "Invalid --auth: must be 'none', 'apikey', or 'supabase'"
[[ "$DB" != "none" && "$DB" != "supabase" && "$DB" != "postgres" ]] && error "Invalid --db: must be 'none', 'supabase', or 'postgres'"

if [[ "$DB" == "postgres" && "$TIER" == "cloudflare" ]]; then
    error "Cannot use --db postgres with --tier cloudflare (no Docker support). Use --tier vps instead."
fi

MCP_SLUG=$(slugify "$NAME")
TEMPLATE_DIR="$TEMPLATES_DIR/${LANG}-${TIER}"
OUTPUT_DIR="$REPO_ROOT/mcps/$MCP_SLUG"

[[ ! -d "$TEMPLATE_DIR" ]] && error "Template not found: $TEMPLATE_DIR"
[[ -d "$OUTPUT_DIR" ]] && error "MCP already exists: $OUTPUT_DIR"

# --- Create MCP ---

echo ""
echo -e "${CYAN}Creating MCP: ${NAME}${NC}"
echo -e "  Slug:     ${MCP_SLUG}"
echo -e "  Language: ${LANG}"
echo -e "  Tier:     ${TIER}"
echo -e "  Auth:     ${AUTH}"
echo -e "  Database: ${DB}"
echo ""

info "Copying template from ${LANG}-${TIER}..."
mkdir -p "$(dirname "$OUTPUT_DIR")"
cp -r "$TEMPLATE_DIR" "$OUTPUT_DIR"

# --- Replace Placeholders ---

info "Replacing placeholders..."
find "$OUTPUT_DIR" -type f \( -name "*.py" -o -name "*.ts" -o -name "*.json" -o -name "*.toml" -o -name "*.yml" -o -name "*.yaml" -o -name "*.md" -o -name "*.txt" -o -name "*.example" -o -name "*.cfg" -o -name "Dockerfile" \) -print0 | while IFS= read -r -d '' file; do
    sed_i \
        -e "s/{{MCP_NAME}}/$NAME/g" \
        -e "s/{{MCP_SLUG}}/$MCP_SLUG/g" \
        -e "s/{{MCP_DESCRIPTION}}/$DESCRIPTION/g" \
        "$file"
done

# --- Auth Setup ---

if [[ "$AUTH" == "apikey" ]]; then
    info "Setting up API key authentication..."

    if [[ "$LANG" == "python" ]]; then
        cp "$REPO_ROOT/shared/python/auth.py" "$OUTPUT_DIR/src/auth.py"
        # Uncomment API key env vars in .env.example
        if [[ -f "$OUTPUT_DIR/.env.example" ]]; then
            sed_i 's/^# MCP_API_KEYS=/MCP_API_KEYS=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
        fi
    elif [[ "$LANG" == "typescript" ]]; then
        cp "$REPO_ROOT/shared/typescript/auth.ts" "$OUTPUT_DIR/src/auth.ts"
        if [[ -f "$OUTPUT_DIR/.env.example" ]]; then
            sed_i 's/^# MCP_API_KEYS=/MCP_API_KEYS=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
        fi
    fi

elif [[ "$AUTH" == "supabase" ]]; then
    info "Setting up Supabase JWT authentication..."

    if [[ "$LANG" == "python" ]]; then
        cp "$REPO_ROOT/shared/python/auth.py" "$OUTPUT_DIR/src/auth.py"
        # Add PyJWT to requirements
        echo "PyJWT>=2.8.0" >> "$OUTPUT_DIR/requirements.txt"
        # Uncomment Supabase env vars
        if [[ -f "$OUTPUT_DIR/.env.example" ]]; then
            sed_i 's/^# SUPABASE_URL=/SUPABASE_URL=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
            sed_i 's/^# SUPABASE_JWT_SECRET=/SUPABASE_JWT_SECRET=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
            sed_i 's/^# SUPABASE_SERVICE_ROLE_KEY=/SUPABASE_SERVICE_ROLE_KEY=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
        fi
    elif [[ "$LANG" == "typescript" ]]; then
        cp "$REPO_ROOT/shared/typescript/auth.ts" "$OUTPUT_DIR/src/auth.ts"
        # Add jose to package.json dependencies via sed
        if [[ -f "$OUTPUT_DIR/package.json" ]]; then
            sed_i 's/"zod": "^3.23.0"/"jose": "^5.0.0",\n    "zod": "^3.23.0"/' "$OUTPUT_DIR/package.json" 2>/dev/null || warn "Could not auto-add jose dependency. Run: npm install jose"
        fi
        if [[ -f "$OUTPUT_DIR/.env.example" ]]; then
            sed_i 's/^# SUPABASE_URL=/SUPABASE_URL=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
            sed_i 's/^# SUPABASE_JWT_SECRET=/SUPABASE_JWT_SECRET=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
            sed_i 's/^# SUPABASE_SERVICE_ROLE_KEY=/SUPABASE_SERVICE_ROLE_KEY=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
        fi
    fi
fi

# --- Database Setup ---

if [[ "$DB" == "supabase" ]]; then
    info "Setting up Supabase database client..."

    if [[ "$LANG" == "python" ]]; then
        cp "$REPO_ROOT/shared/python/supabase_client.py" "$OUTPUT_DIR/src/supabase_client.py"
        echo "supabase>=2.0.0" >> "$OUTPUT_DIR/requirements.txt"
        # Ensure env vars are uncommented
        if [[ -f "$OUTPUT_DIR/.env.example" ]]; then
            sed_i 's/^# SUPABASE_URL=/SUPABASE_URL=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
            sed_i 's/^# SUPABASE_SERVICE_ROLE_KEY=/SUPABASE_SERVICE_ROLE_KEY=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
        fi
    elif [[ "$LANG" == "typescript" ]]; then
        cp "$REPO_ROOT/shared/typescript/supabase-client.ts" "$OUTPUT_DIR/src/supabase-client.ts"
        # Add @supabase/supabase-js to package.json dependencies via sed
        if [[ -f "$OUTPUT_DIR/package.json" ]]; then
            sed_i 's/"zod": "^3.23.0"/"@supabase\/supabase-js": "^2.0.0",\n    "zod": "^3.23.0"/' "$OUTPUT_DIR/package.json" 2>/dev/null || warn "Could not auto-add @supabase/supabase-js. Run: npm install @supabase/supabase-js"
        fi
        if [[ -f "$OUTPUT_DIR/.env.example" ]]; then
            sed_i 's/^# SUPABASE_URL=/SUPABASE_URL=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
            sed_i 's/^# SUPABASE_SERVICE_ROLE_KEY=/SUPABASE_SERVICE_ROLE_KEY=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
        fi
    fi

elif [[ "$DB" == "postgres" ]]; then
    info "Setting up PostgreSQL database..."

    # Add postgres service to docker-compose.yml
    if [[ -f "$OUTPUT_DIR/docker-compose.yml" ]]; then
        cat >> "$OUTPUT_DIR/docker-compose.yml" <<'PGEOF'

  db:
    image: postgres:16-alpine
    restart: always
    environment:
      POSTGRES_DB: ${DB_NAME:-mcpdata}
      POSTGRES_USER: ${DB_USER:-mcpuser}
      POSTGRES_PASSWORD: ${DB_PASSWORD:?DB_PASSWORD is required}
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  pgdata:
PGEOF

        # Add depends_on to the mcp-server service
        sed_i '/restart: always/a\    depends_on:\n      - db' "$OUTPUT_DIR/docker-compose.yml" 2>/dev/null || true
    fi

    if [[ "$LANG" == "python" ]]; then
        echo "psycopg2-binary>=2.9.0" >> "$OUTPUT_DIR/requirements.txt"
        echo "sqlalchemy>=2.0.0" >> "$OUTPUT_DIR/requirements.txt"
    elif [[ "$LANG" == "typescript" ]]; then
        # Add pg to package.json dependencies via sed
        if [[ -f "$OUTPUT_DIR/package.json" ]]; then
            sed_i 's/"zod": "^3.23.0"/"pg": "^8.0.0",\n    "zod": "^3.23.0"/' "$OUTPUT_DIR/package.json" 2>/dev/null || warn "Could not auto-add pg. Run: npm install pg"
            sed_i 's/"typescript": "^5.5.0"/"@types\/pg": "^8.0.0",\n    "typescript": "^5.5.0"/' "$OUTPUT_DIR/package.json" 2>/dev/null || true
        fi
    fi

    # Uncomment DATABASE_URL in .env.example
    if [[ -f "$OUTPUT_DIR/.env.example" ]]; then
        sed_i 's/^# DATABASE_URL=/DATABASE_URL=/' "$OUTPUT_DIR/.env.example" 2>/dev/null || true
    fi
fi

# --- Logging Setup ---

info "Adding structured logging..."
if [[ "$LANG" == "python" ]]; then
    cp "$REPO_ROOT/shared/python/logging_config.py" "$OUTPUT_DIR/src/logging_config.py"
elif [[ "$LANG" == "typescript" ]]; then
    cp "$REPO_ROOT/shared/typescript/logging.ts" "$OUTPUT_DIR/src/logging.ts"
fi

# --- Separate Repo ---

if [[ "$SEPARATE_REPO" == true ]]; then
    info "Initializing as standalone git repository..."
    (cd "$OUTPUT_DIR" && git init && git add . && git commit -m "Initial MCP scaffold: $NAME")
fi

# --- Register in MCP Registry ---

REGISTER_SCRIPT="$REPO_ROOT/scripts/register-mcp.sh"
if [[ -x "$REGISTER_SCRIPT" ]]; then
    REGISTER_ARGS=(--name "$NAME" --slug "$MCP_SLUG" --lang "$LANG" --tier "$TIER" --auth "$AUTH" --db "$DB" --description "$DESCRIPTION")
    [[ "$SEPARATE_REPO" == true ]] && REGISTER_ARGS+=(--separate-repo)
    "$REGISTER_SCRIPT" "${REGISTER_ARGS[@]}" || true
fi

# --- Done ---

echo ""
echo -e "${GREEN}✓ MCP created successfully!${NC}"
echo ""
echo -e "  ${CYAN}Location:${NC}  $OUTPUT_DIR"
echo -e "  ${CYAN}Language:${NC}  $LANG"
echo -e "  ${CYAN}Tier:${NC}      $TIER"
echo -e "  ${CYAN}Auth:${NC}      $AUTH"
echo -e "  ${CYAN}Database:${NC}  $DB"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""

if [[ "$LANG" == "python" ]]; then
    echo "  1. cd $OUTPUT_DIR"
    echo "  2. cp .env.example .env && edit .env"
    echo "  3. pip install -r requirements.txt"
    echo "  4. Add your tools in src/tools/"
    echo "  5. python -m src.server"
else
    echo "  1. cd $OUTPUT_DIR"
    echo "  2. cp .env.example .env && edit .env"
    echo "  3. npm install"
    echo "  4. Add your tools in src/tools/"
    echo "  5. npm run dev"
fi

echo ""

if [[ "$TIER" == "cloudflare" ]]; then
    echo -e "  ${CYAN}Deploy:${NC} wrangler deploy"
    echo -e "  ${CYAN}URL:${NC}    https://${MCP_SLUG}.your-account.workers.dev/mcp"
else
    echo -e "  ${CYAN}Deploy:${NC} docker compose up --build  (or push to GitHub for Coolify auto-deploy)"
    echo -e "  ${CYAN}URL:${NC}    https://${MCP_SLUG}.mcp.yourdomain.com/mcp"
fi

echo ""
