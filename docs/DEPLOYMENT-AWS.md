# AWS App Runner deployment

The cross-platform rules live in
[`common-docs/systems/mcp-hosting/FEATURE.md`](../../common-docs/systems/mcp-hosting/FEATURE.md).

## One-time account baseline

Apply `matrx-ship/infrastructure/aws/mcp-hosting` with the bootstrap AWS administrator. This creates
the App Runner image-pull/runtime roles and gives the audited production operator narrowly scoped MCP
deployment permissions. It creates no MCP service and changes no DNS.

## Generate and deploy

```bash
./generators/create-mcp.sh \
  --name "Client Research Tools" \
  --lang typescript \
  --tier aws \
  --auth supabase \
  --db supabase \
  --separate-repo

cd mcps/client-research-tools
./deploy-aws.sh --plan
./deploy-aws.sh --create
```

The deployer uses the current AWS profile/workload identity. It requires committed source, creates an
immutable `matrx-mcp/{slug}:{full-git-sha}` ECR image, creates or updates `matrx-mcp-{slug}` in App
Runner, waits for `/health`, and prints the final `/mcp` URL.

## Runtime values

Non-secret variables and Secrets Manager ARN references can be declared in `.aws-runtime.json`:

```json
{
  "variables": { "LOG_LEVEL": "INFO" },
  "secrets": { "MCP_API_KEYS": "arn:aws:secretsmanager:us-east-1:ACCOUNT:secret:NAME" }
}
```

The file is ignored by Git. Do not place secret values in it. The default runtime role has no AWS
permissions; attach a reviewed policy for the exact AWS resource a tool needs.

## Operate

```bash
./deploy-aws.sh --status
./deploy-aws.sh --logs
./deploy-aws.sh             # immutable redeploy after committing a new SHA
```

App Runner's generated hostname is the supported initial endpoint. Custom domains require a separate
explicit DNS operation after verification.
