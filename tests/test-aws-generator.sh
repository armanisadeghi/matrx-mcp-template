#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

generate() {
    MCP_FACTORY_OUTPUT_ROOT="$TEST_ROOT" MCP_FACTORY_SKIP_REGISTRY=true \
        "$REPO_ROOT/generators/create-mcp.sh" "$@" >/dev/null
}

generate --name "AWS Python Proof" --lang python --tier aws --auth supabase --db supabase
PYTHON_MCP="$TEST_ROOT/aws-python-proof"
test -x "$PYTHON_MCP/deploy-aws.sh"
test ! -e "$PYTHON_MCP/docker-compose.yml"
grep -q 'stateless_http=True' "$PYTHON_MCP/src/server.py"
grep -q 'AWS App Runner' "$PYTHON_MCP/README.md"
bash -n "$PYTHON_MCP/deploy-aws.sh"
"$PYTHON_MCP/deploy-aws.sh" --plan | grep -q 'no DNS is changed'
grep -q 'supabase>=' "$PYTHON_MCP/requirements.txt"
grep -q 'PyJWT>=' "$PYTHON_MCP/requirements.txt"
PYTHONPATH="$PYTHON_MCP/src" python3 -m py_compile "$PYTHON_MCP/src/server.py" "$PYTHON_MCP/src/auth.py" "$PYTHON_MCP/src/supabase_client.py"

generate --name "AWS TypeScript Proof" --lang typescript --tier aws --auth supabase --db supabase
TS_MCP="$TEST_ROOT/aws-typescript-proof"
test -x "$TS_MCP/deploy-aws.sh"
test ! -e "$TS_MCP/docker-compose.yml"
grep -q 'sessionIdGenerator: undefined' "$TS_MCP/src/index.ts"
grep -q '"jose"' "$TS_MCP/package.json"
grep -q '"@supabase/supabase-js"' "$TS_MCP/package.json"
bash -n "$TS_MCP/deploy-aws.sh"
"$TS_MCP/deploy-aws.sh" --plan | grep -q 'current AWS workload/profile only'
(cd "$TS_MCP" && npm ci --ignore-scripts >/dev/null && npm run build >/dev/null)

if generate --name "Invalid AWS Postgres" --lang python --tier aws --auth none --db postgres 2>/dev/null; then
    echo "AWS generator incorrectly accepted a sidecar Postgres database" >&2
    exit 1
fi

echo "AWS MCP generator checks passed"
