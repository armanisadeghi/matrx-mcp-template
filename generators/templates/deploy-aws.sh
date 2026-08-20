#!/usr/bin/env bash
set -euo pipefail

# Deploys one generated MCP container to AWS App Runner. Authentication comes
# from the caller's AWS workload/profile; this script never accepts AWS keys.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_SLUG="{{MCP_SLUG}}"
MCP_NAME="{{MCP_NAME}}"

AWS_REGION="${AWS_REGION:-us-east-1}"
EXPECTED_AWS_ACCOUNT_ID="${EXPECTED_AWS_ACCOUNT_ID:-}"
ECR_REPOSITORY="${ECR_REPOSITORY:-matrx-mcp/${MCP_SLUG}}"
APP_RUNNER_SERVICE="${APP_RUNNER_SERVICE:-matrx-mcp-${MCP_SLUG}}"
APP_RUNNER_CPU="${APP_RUNNER_CPU:-1 vCPU}"
APP_RUNNER_MEMORY="${APP_RUNNER_MEMORY:-2 GB}"
RUNTIME_CONFIG="${RUNTIME_CONFIG:-${SCRIPT_DIR}/.aws-runtime.json}"

red='\033[0;31m'; green='\033[0;32m'; cyan='\033[0;36m'; reset='\033[0m'
error() { echo -e "${red}Error: $1${reset}" >&2; exit 1; }
info() { echo -e "${green}→${reset} $1"; }

require_commands() {
    local command_name
    for command_name in aws docker python3 git curl; do
        command -v "$command_name" >/dev/null 2>&1 || error "$command_name is required"
    done
}

aws_identity() {
    AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text --region "$AWS_REGION")"
    [[ -n "$AWS_ACCOUNT_ID" && "$AWS_ACCOUNT_ID" != "None" ]] || error "AWS identity is unavailable"
    if [[ -n "$EXPECTED_AWS_ACCOUNT_ID" && "$AWS_ACCOUNT_ID" != "$EXPECTED_AWS_ACCOUNT_ID" ]]; then
        error "Refusing account ${AWS_ACCOUNT_ID}; expected ${EXPECTED_AWS_ACCOUNT_ID}"
    fi
    ECR_HOST="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
    IMAGE_REPOSITORY="${ECR_HOST}/${ECR_REPOSITORY}"
    APP_RUNNER_ACCESS_ROLE_ARN="${APP_RUNNER_ACCESS_ROLE_ARN:-arn:aws:iam::${AWS_ACCOUNT_ID}:role/matrx/mcp-hosting/matrx-mcp-apprunner-ecr-access}"
    APP_RUNNER_INSTANCE_ROLE_ARN="${APP_RUNNER_INSTANCE_ROLE_ARN:-arn:aws:iam::${AWS_ACCOUNT_ID}:role/matrx/mcp-hosting/matrx-mcp-runtime}"
}

image_tag() {
    if [[ -n "${MCP_IMAGE_TAG:-}" ]]; then
        IMAGE_TAG="$MCP_IMAGE_TAG"
    else
        git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || error "Commit the MCP or set MCP_IMAGE_TAG to a 40-character Git SHA"
        git -C "$SCRIPT_DIR" diff --quiet && git -C "$SCRIPT_DIR" diff --cached --quiet || error "Commit local changes before deployment so the running image is auditable"
        IMAGE_TAG="$(git -C "$SCRIPT_DIR" rev-parse HEAD)"
    fi
    [[ "$IMAGE_TAG" =~ ^[0-9a-f]{40}$ ]] || error "MCP_IMAGE_TAG must be a full 40-character lowercase Git SHA"
    IMAGE_URI="${IMAGE_REPOSITORY}:${IMAGE_TAG}"
}

ensure_repository() {
    if ! aws ecr describe-repositories --repository-names "$ECR_REPOSITORY" --region "$AWS_REGION" >/dev/null 2>&1; then
        info "Creating immutable, scan-on-push ECR repository ${ECR_REPOSITORY}"
        aws ecr create-repository \
            --repository-name "$ECR_REPOSITORY" \
            --image-tag-mutability IMMUTABLE \
            --image-scanning-configuration scanOnPush=true \
            --encryption-configuration encryptionType=AES256 \
            --tags Key=System,Value=ai-matrx-mcp-hosting Key=ManagedBy,Value=matrx-mcp-factory \
            --region "$AWS_REGION" >/dev/null
    fi

    local lifecycle_file
    lifecycle_file="$(mktemp)"
    printf '%s' '{"rules":[{"rulePriority":1,"description":"Keep the newest 20 immutable releases","selection":{"tagStatus":"any","countType":"imageCountMoreThan","countNumber":20},"action":{"type":"expire"}}]}' > "$lifecycle_file"
    aws ecr put-lifecycle-policy --repository-name "$ECR_REPOSITORY" --lifecycle-policy-text "file://${lifecycle_file}" --region "$AWS_REGION" >/dev/null
    rm -f "$lifecycle_file"
}

build_and_push() {
    if aws ecr describe-images --repository-name "$ECR_REPOSITORY" --image-ids "imageTag=${IMAGE_TAG}" --region "$AWS_REGION" >/dev/null 2>&1; then
        info "Immutable image ${IMAGE_TAG} already exists; reusing it"
        return
    fi
    info "Building ${IMAGE_URI} for linux/amd64"
    aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_HOST" >/dev/null
    docker buildx build --platform linux/amd64 --provenance=false --load -t "$IMAGE_URI" "$SCRIPT_DIR"
    docker push "$IMAGE_URI"
}

write_app_runner_config() {
    source_file="$(mktemp)"
    instance_file="$(mktemp)"
    trap 'rm -f "${source_file:-}" "${instance_file:-}"' EXIT
    local runtime_path="$RUNTIME_CONFIG"
    [[ -f "$runtime_path" ]] || runtime_path=""

    python3 - "$source_file" "$instance_file" "$runtime_path" <<PY
import json, sys
source_path, instance_path, runtime_path = sys.argv[1:]
runtime = {"variables": {}, "secrets": {}}
if runtime_path:
    with open(runtime_path, encoding="utf-8") as handle:
        runtime = json.load(handle)
for key in ("variables", "secrets"):
    if not isinstance(runtime.get(key, {}), dict):
        raise SystemExit(f"{key} in .aws-runtime.json must be an object")
variables = {"MCP_NAME": "${MCP_NAME}"}
variables.update({str(k): str(v) for k, v in runtime.get("variables", {}).items()})
source = {
    "AuthenticationConfiguration": {"AccessRoleArn": "${APP_RUNNER_ACCESS_ROLE_ARN}"},
    "AutoDeploymentsEnabled": False,
    "ImageRepository": {
        "ImageIdentifier": "${IMAGE_URI}",
        "ImageRepositoryType": "ECR",
        "ImageConfiguration": {
            "Port": "8000",
            "RuntimeEnvironmentVariables": variables,
            "RuntimeEnvironmentSecrets": runtime.get("secrets", {}),
        },
    },
}
instance = {
    "Cpu": "${APP_RUNNER_CPU}",
    "Memory": "${APP_RUNNER_MEMORY}",
    "InstanceRoleArn": "${APP_RUNNER_INSTANCE_ROLE_ARN}",
}
with open(source_path, "w", encoding="utf-8") as handle:
    json.dump(source, handle)
with open(instance_path, "w", encoding="utf-8") as handle:
    json.dump(instance, handle)
PY
}

find_service_arn() {
    aws apprunner list-services --region "$AWS_REGION" \
        --query "ServiceSummaryList[?ServiceName=='${APP_RUNNER_SERVICE}'].ServiceArn | [0]" --output text
}

wait_until_running() {
    local service_arn="$1" status url attempt
    for attempt in $(seq 1 120); do
        status="$(aws apprunner describe-service --service-arn "$service_arn" --region "$AWS_REGION" --query Service.Status --output text)"
        case "$status" in
            RUNNING)
                url="$(aws apprunner describe-service --service-arn "$service_arn" --region "$AWS_REGION" --query Service.ServiceUrl --output text)"
                curl --fail --silent --show-error --retry 6 --retry-delay 5 "https://${url}/health" >/dev/null
                echo "https://${url}/mcp"
                return
                ;;
            CREATE_FAILED|DELETE_FAILED|PAUSED)
                error "App Runner entered ${status}; inspect with ./deploy-aws.sh --status and --logs"
                ;;
        esac
        sleep 10
    done
    error "Timed out waiting for App Runner service"
}

update_registry_if_available() {
    local endpoint="$1"
    if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
        info "Canonical MCP catalog update skipped because deployer registry credentials are unavailable"
        return
    fi
    if [[ "$SUPABASE_URL" == *supabase.co* && "$SUPABASE_URL" != *brsgrqvjdzwihsvnfqkf* ]]; then
        error "Refusing to register this MCP outside canonical Supabase East"
    fi
    local payload response response_code existing
    existing="$(curl --fail --silent --show-error \
        "${SUPABASE_URL}/rest/v1/mcp_server?slug=eq.${MCP_SLUG}&select=metadata" \
        -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
        -H "Accept-Profile: tool")"
    payload="$(python3 - "$endpoint" "$IMAGE_URI" "$service_arn" "$existing" <<'PY'
import datetime, json, sys
endpoint, image, service_arn, existing_json = sys.argv[1:]
rows = json.loads(existing_json)
if not rows:
    raise SystemExit("MCP catalog row does not exist; scaffold registration must succeed before deploy")
metadata = rows[0].get("metadata") or {}
metadata.update({"managed_by": "matrx-mcp-factory", "hosting_target": "aws",
                 "image": image, "app_runner_service_arn": service_arn})
print(json.dumps({
    "endpoint_url": endpoint,
    "has_remote": True,
    "status": "active",
    "last_tested_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
    "last_test_ok": True,
    "metadata": metadata,
}))
PY
)"
    response="$(curl --silent --write-out $'\n%{http_code}' \
        -X PATCH "${SUPABASE_URL}/rest/v1/mcp_server?slug=eq.${MCP_SLUG}" \
        -H "apikey: ${SUPABASE_SERVICE_ROLE_KEY}" \
        -H "Authorization: Bearer ${SUPABASE_SERVICE_ROLE_KEY}" \
        -H "Content-Type: application/json" -H "Content-Profile: tool" \
        -H "Prefer: return=representation" -d "$payload")"
    response_code="$(printf '%s' "$response" | tail -1)"
    [[ "$response_code" == "200" ]] || error "MCP catalog update failed with HTTP ${response_code}"
    info "Canonical East MCP catalog updated"
}

deploy() {
    require_commands
    aws_identity
    image_tag
    ensure_repository
    build_and_push
    write_app_runner_config

    local service_arn
    service_arn="$(find_service_arn)"
    if [[ -z "$service_arn" || "$service_arn" == "None" ]]; then
        info "Creating App Runner service ${APP_RUNNER_SERVICE}"
        service_arn="$(aws apprunner create-service \
            --service-name "$APP_RUNNER_SERVICE" \
            --source-configuration "file://${source_file}" \
            --instance-configuration "file://${instance_file}" \
            --health-check-configuration Protocol=HTTP,Path=/health,Interval=10,Timeout=5,HealthyThreshold=1,UnhealthyThreshold=5 \
            --tags Key=System,Value=ai-matrx-mcp-hosting Key=ManagedBy,Value=matrx-mcp-factory Key=McpSlug,Value="$MCP_SLUG" \
            --region "$AWS_REGION" --query Service.ServiceArn --output text)"
    else
        info "Updating App Runner service ${APP_RUNNER_SERVICE} to ${IMAGE_TAG}"
        aws apprunner update-service --service-arn "$service_arn" \
            --source-configuration "file://${source_file}" \
            --instance-configuration "file://${instance_file}" \
            --health-check-configuration Protocol=HTTP,Path=/health,Interval=10,Timeout=5,HealthyThreshold=1,UnhealthyThreshold=5 \
            --region "$AWS_REGION" >/dev/null
    fi
    info "Waiting for the service and real health endpoint"
    local endpoint
    endpoint="$(wait_until_running "$service_arn")"
    update_registry_if_available "$endpoint"
    echo -e "${green}Deployment healthy${reset}"
    echo -e "  MCP URL: ${cyan}${endpoint}${reset}"
    echo "  Image:   ${IMAGE_URI}"
    python3 - "$service_arn" "$endpoint" "$IMAGE_URI" <<'PY'
import json, sys
print("MCP_DEPLOY_RESULT=" + json.dumps({"service_arn": sys.argv[1], "mcp_url": sys.argv[2], "image": sys.argv[3]}, separators=(",", ":")))
PY
}

status() {
    require_commands
    aws_identity
    local service_arn
    service_arn="$(find_service_arn)"
    [[ -n "$service_arn" && "$service_arn" != "None" ]] || error "Service ${APP_RUNNER_SERVICE} does not exist"
    aws apprunner describe-service --service-arn "$service_arn" --region "$AWS_REGION" \
        --query 'Service.{name:ServiceName,status:Status,url:ServiceUrl,image:SourceConfiguration.ImageRepository.ImageIdentifier,created:CreatedAt,updated:UpdatedAt}' --output table
}

logs() {
    require_commands
    aws_identity
    local service_arn service_id
    service_arn="$(find_service_arn)"
    [[ -n "$service_arn" && "$service_arn" != "None" ]] || error "Service ${APP_RUNNER_SERVICE} does not exist"
    service_id="${service_arn##*/}"
    aws logs tail "/aws/apprunner/${APP_RUNNER_SERVICE}/${service_id}/application" --since 1h --follow --region "$AWS_REGION"
}

plan() {
    echo "AWS App Runner MCP deployment plan"
    echo "  Region:       ${AWS_REGION}"
    echo "  ECR:          matrx-mcp/${MCP_SLUG} (immutable, scan on push)"
    echo "  Service:      ${APP_RUNNER_SERVICE}"
    echo "  Port/health:  8000 /health"
    echo "  Public URL:   AWS-generated HTTPS URL; no DNS is changed"
    echo "  Credentials:  current AWS workload/profile only; no static keys"
}

case "${1:---deploy}" in
    --create|--deploy) deploy ;;
    --status) status ;;
    --logs) logs ;;
    --plan) plan ;;
    --help|-h)
        echo "Usage: ./deploy-aws.sh [--create|--deploy|--status|--logs|--plan]"
        echo "Account bootstrap: infrastructure/aws/mcp-hosting in matrx-ship"
        ;;
    *) error "Unknown action: $1" ;;
esac
