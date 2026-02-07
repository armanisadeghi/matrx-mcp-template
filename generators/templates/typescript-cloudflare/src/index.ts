import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { registerTools } from "./tools/index.js";

const server = new McpServer({
  name: "{{MCP_NAME}}",
  version: "1.0.0",
});

registerTools(server);

export default server;
