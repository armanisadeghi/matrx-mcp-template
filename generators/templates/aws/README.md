# {{MCP_NAME}}

{{MCP_DESCRIPTION}}

This MCP is packaged as a stateless Streamable HTTP container for AWS App Runner. Stateless transport
is intentional: App Runner can replace or horizontally scale instances without losing MCP sessions.

## Develop

Use `pip install -r requirements.txt` and `PYTHONPATH=src python -m server` for Python, or
`npm install && npm run dev` for TypeScript. Add business tools only under `src/tools/`.

```bash
curl http://localhost:8000/health
```

## Deploy

The AWS account must first have the baseline from `matrx-ship/infrastructure/aws/mcp-hosting`.
The deployer uses the current AWS workload/profile and never reads static AWS keys.

```bash
./deploy-aws.sh --plan
./deploy-aws.sh --create
./deploy-aws.sh --status
./deploy-aws.sh --logs
```

AWS supplies the HTTPS hostname automatically. The script prints the final `/mcp` URL only after
App Runner reports `RUNNING` and `/health` succeeds. It never changes Cloudflare or production DNS.

For protected values, copy `.aws-runtime.example.json` to `.aws-runtime.json` and reference Secrets
Manager ARNs. The local file is ignored by Git. Do not put secret values in it.
