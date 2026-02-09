import { randomUUID } from "node:crypto";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { isInitializeRequest } from "@modelcontextprotocol/sdk/types.js";
import { registerTools } from "./tools/index.js";
import http from "node:http";

const MCP_NAME = process.env.MCP_NAME || "{{MCP_NAME}}";
const PORT = parseInt(process.env.PORT || "8000", 10);

// Session transport map for stateful connections
const transports: Record<string, StreamableHTTPServerTransport> = {};

function createServer(): McpServer {
  const server = new McpServer({ name: MCP_NAME, version: "1.0.0" });
  registerTools(server);
  return server;
}

const httpServer = http.createServer(async (req, res) => {
  const url = req.url ?? "";

  // Health check
  if (url === "/health" && req.method === "GET") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ status: "ok", name: MCP_NAME }));
    return;
  }

  // Root status
  if (url === "/" && req.method === "GET") {
    res.writeHead(200, { "Content-Type": "application/json" });
    res.end(JSON.stringify({ name: MCP_NAME, version: "1.0.0", mcp_endpoint: "/mcp", status: "running" }));
    return;
  }

  // MCP endpoint
  if (url === "/mcp") {
    if (req.method === "POST") {
      // Read body
      const chunks: Buffer[] = [];
      for await (const chunk of req) chunks.push(chunk as Buffer);
      const body = JSON.parse(Buffer.concat(chunks).toString());

      const sessionId = req.headers["mcp-session-id"] as string | undefined;

      try {
        if (sessionId && transports[sessionId]) {
          // Existing session
          await transports[sessionId].handleRequest(req, res, body);
        } else if (!sessionId && isInitializeRequest(body)) {
          // New session
          const transport = new StreamableHTTPServerTransport({
            sessionIdGenerator: () => randomUUID(),
            onsessioninitialized: (sid) => {
              transports[sid] = transport;
            },
          });

          transport.onclose = () => {
            const sid = transport.sessionId;
            if (sid && transports[sid]) {
              delete transports[sid];
            }
          };

          const server = createServer();
          await server.connect(transport);
          await transport.handleRequest(req, res, body);
        } else {
          res.writeHead(400, { "Content-Type": "application/json" });
          res.end(JSON.stringify({
            jsonrpc: "2.0",
            error: { code: -32000, message: "Bad Request: No valid session ID provided" },
            id: null,
          }));
        }
      } catch (error) {
        console.error("Error handling MCP request:", error);
        if (!res.headersSent) {
          res.writeHead(500, { "Content-Type": "application/json" });
          res.end(JSON.stringify({
            jsonrpc: "2.0",
            error: { code: -32603, message: "Internal server error" },
            id: null,
          }));
        }
      }
      return;
    }

    if (req.method === "GET") {
      const sessionId = req.headers["mcp-session-id"] as string | undefined;
      if (!sessionId || !transports[sessionId]) {
        res.writeHead(400);
        res.end("Invalid or missing session ID");
        return;
      }
      await transports[sessionId].handleRequest(req, res);
      return;
    }

    if (req.method === "DELETE") {
      const sessionId = req.headers["mcp-session-id"] as string | undefined;
      if (!sessionId || !transports[sessionId]) {
        res.writeHead(400);
        res.end("Invalid or missing session ID");
        return;
      }
      await transports[sessionId].handleRequest(req, res);
      return;
    }
  }

  res.writeHead(404);
  res.end("Not found");
});

httpServer.listen(PORT, "0.0.0.0", () => {
  console.log(`${MCP_NAME} MCP server running on port ${PORT}`);
});

process.on("SIGINT", async () => {
  for (const sid in transports) {
    await transports[sid].close();
    delete transports[sid];
  }
  process.exit(0);
});
