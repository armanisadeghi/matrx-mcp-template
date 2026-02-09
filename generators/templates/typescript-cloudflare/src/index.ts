import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { McpAgent } from "agents/mcp";
import { registerTools } from "./tools/index.js";

export class MCP extends McpAgent {
  server = new McpServer({
    name: "{{MCP_NAME}}",
    version: "1.0.0",
  });

  async init() {
    registerTools(this.server);
  }
}

export default {
  fetch(request: Request, env: Env, ctx: ExecutionContext) {
    const url = new URL(request.url);

    if (url.pathname === "/mcp" || url.pathname === "/mcp/") {
      return MCP.serve("/mcp").fetch(request, env, ctx);
    }

    if (url.pathname === "/") {
      return new Response(JSON.stringify({
        name: "{{MCP_NAME}}",
        version: "1.0.0",
        mcp_endpoint: "/mcp",
        status: "running",
      }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    return new Response("Not found", { status: 404 });
  },
};
