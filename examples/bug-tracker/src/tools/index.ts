import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function registerTools(server: McpServer) {
  server.tool(
    "submit_bug",
    "Submit a new bug report",
    {
      title: z.string().describe("Bug title"),
      description: z.string().describe("Detailed bug description"),
      severity: z.enum(["low", "medium", "high", "critical"]).describe("Bug severity level"),
      app_name: z.string().describe("Which application this affects"),
    },
    async ({ title, description, severity, app_name }) => {
      // In production, this writes to Supabase using the user's JWT
      const bug = {
        id: crypto.randomUUID(),
        title,
        description,
        severity,
        app_name,
        status: "new",
        created_at: new Date().toISOString(),
      };

      return {
        content: [{ type: "text", text: JSON.stringify(bug, null, 2) }],
      };
    }
  );

  server.tool(
    "list_bugs",
    "List bugs with optional filters",
    {
      status: z.enum(["new", "reviewing", "in_progress", "needs_human", "resolved", "closed"]).optional().describe("Filter by status"),
      severity: z.enum(["low", "medium", "high", "critical"]).optional().describe("Filter by severity"),
      app_name: z.string().optional().describe("Filter by application name"),
      limit: z.number().default(20).describe("Maximum number of results"),
    },
    async ({ status, severity, app_name, limit }) => {
      // In production, queries Supabase with user's JWT (RLS)
      const placeholder = {
        message: "Connect to Supabase to query real data",
        filters: { status, severity, app_name, limit },
      };

      return {
        content: [{ type: "text", text: JSON.stringify(placeholder, null, 2) }],
      };
    }
  );

  server.tool(
    "update_bug_status",
    "Update the status of a bug",
    {
      bug_id: z.string().uuid().describe("The bug ID to update"),
      status: z.enum(["reviewing", "in_progress", "needs_human", "resolved", "closed"]).describe("New status"),
      notes: z.string().optional().describe("Optional notes about the status change"),
    },
    async ({ bug_id, status, notes }) => {
      const result = {
        id: bug_id,
        status,
        notes: notes || null,
        updated_at: new Date().toISOString(),
      };

      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      };
    }
  );

  server.tool(
    "add_bug_comment",
    "Add a comment to a bug report",
    {
      bug_id: z.string().uuid().describe("The bug ID to comment on"),
      comment: z.string().describe("Comment text"),
      is_internal: z.boolean().default(false).describe("Whether this is an internal-only comment"),
    },
    async ({ bug_id, comment, is_internal }) => {
      const result = {
        id: crypto.randomUUID(),
        bug_id,
        comment,
        is_internal,
        created_at: new Date().toISOString(),
      };

      return {
        content: [{ type: "text", text: JSON.stringify(result, null, 2) }],
      };
    }
  );

  server.tool(
    "get_bug_details",
    "Get full details of a specific bug including comments and history",
    {
      bug_id: z.string().uuid().describe("The bug ID to look up"),
    },
    async ({ bug_id }) => {
      const placeholder = {
        id: bug_id,
        message: "Connect to Supabase to fetch real bug details",
        fields: ["title", "description", "severity", "status", "app_name", "comments", "history", "created_at", "updated_at"],
      };

      return {
        content: [{ type: "text", text: JSON.stringify(placeholder, null, 2) }],
      };
    }
  );
}
