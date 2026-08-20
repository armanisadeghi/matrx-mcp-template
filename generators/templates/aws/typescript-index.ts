import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { registerTools } from "./tools/index.js";
import http from "node:http";

const MCP_NAME = process.env.MCP_NAME || "{{MCP_NAME}}";
const PORT = Number.parseInt(process.env.PORT || "8000", 10);

function createServer(): McpServer {
  const server = new McpServer({ name: MCP_NAME, version: "1.0.0" });
  registerTools(server);
  return server;
}

const httpServer = http.createServer(async (req, res) => {
  const url = req.url ?? "";
  if ((url === "/" || url === "/health") && req.method === "GET") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({
      status: "running",
      name: MCP_NAME,
      version: "1.0.0",
      mcp_endpoint: "/mcp",
      transport: "streamable-http-stateless",
    }));
    return;
  }

  if (url === "/mcp" && req.method === "POST") {
    try {
      const chunks: Buffer[] = [];
      for await (const chunk of req) chunks.push(chunk as Buffer);
      const body = JSON.parse(Buffer.concat(chunks).toString());
      const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });
      const server = createServer();
      res.on("close", () => void transport.close());
      await server.connect(transport);
      await transport.handleRequest(req, res, body);
    } catch (error) {
      console.error("MCP request failed", error);
      if (!res.headersSent) {
        res.writeHead(500, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ jsonrpc: "2.0", error: { code: -32603, message: "Internal server error" }, id: null }));
      }
    }
    return;
  }

  if (url === "/mcp") {
    res.writeHead(405, { Allow: "POST" });
    res.end("Stateless MCP transport accepts POST requests");
    return;
  }

  res.writeHead(404);
  res.end("Not found");
});

httpServer.listen(PORT, "0.0.0.0", () => {
  console.log(`${MCP_NAME} MCP server running on port ${PORT}`);
});
