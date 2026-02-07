import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function registerTools(server: McpServer) {
  server.tool(
    "hello",
    "Say hello to someone",
    { name: z.string() },
    async ({ name }) => ({
      content: [{ type: "text", text: `Hello, ${name}! This is the {{MCP_NAME}} MCP server.` }],
    })
  );

  server.tool(
    "add",
    "Add two numbers",
    { a: z.number(), b: z.number() },
    async ({ a, b }) => ({
      content: [{ type: "text", text: `${a + b}` }],
    })
  );
}
