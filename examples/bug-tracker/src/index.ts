import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { registerTools } from "./tools/index.js";
import http from "http";

const MCP_NAME = process.env.MCP_NAME || "Bug Tracker";
const PORT = parseInt(process.env.PORT || "8000", 10);

const server = new McpServer({
  name: MCP_NAME,
  version: "1.0.0",
});

registerTools(server);

const httpServer = http.createServer(async (req, res) => {
  if (req.url === "/mcp" && req.method === "POST") {
    const transport = new StreamableHTTPServerTransport("/mcp");
    await server.connect(transport);
    await transport.handleRequest(req, res);
  } else if (req.url === "/health") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", name: MCP_NAME }));
  } else {
    res.writeHead(404);
    res.end("Not found");
  }
});

httpServer.listen(PORT, "0.0.0.0", () => {
  console.log(`${MCP_NAME} MCP server running on port ${PORT}`);
});
