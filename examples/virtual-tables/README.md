# Virtual Tables MCP

A VPS-deployed MCP server that provides user-customizable virtual tables backed by Supabase. Each user's table definitions and row data are isolated via Supabase Row Level Security (RLS) and authenticated through Supabase JWT tokens.

## Available Tools

| Tool | Description |
|---|---|
| `create_virtual_table` | Create a new virtual table definition with named, typed columns. |
| `list_virtual_tables` | List all virtual tables belonging to the authenticated user. |
| `get_table_schema` | Get the column schema for a specific virtual table. |
| `insert_row` | Insert a row of data into a virtual table. |
| `query_rows` | Query rows with optional equality filters, limit, and offset. |
| `update_row` | Update a specific row by its ID. |
| `delete_row` | Delete a specific row by its ID. |
| `add_column` | Add a new column to an existing virtual table definition. |

## Placeholder Implementations

All tools currently return demo/placeholder data. Each tool body contains `TODO` comments showing the Supabase queries that should replace the placeholders. To make this production-ready you would:

1. Initialize a Supabase client using `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`.
2. Extract the authenticated user ID from the incoming Supabase JWT.
3. Replace the placeholder return values with real Supabase table queries.
4. Create the backing Supabase tables (`virtual_table_definitions`, `virtual_table_rows`) with appropriate RLS policies.

## Quick Start

```bash
# Copy and fill in environment variables
cp .env.example .env

# Run with Docker Compose
docker compose up --build
```

The server will be available at `http://localhost:8000/mcp`.

## Environment Variables

| Variable | Description |
|---|---|
| `MCP_NAME` | Display name for the MCP server. |
| `PORT` | Port to listen on (default `8000`). |
| `TRANSPORT` | FastMCP transport type (default `streamable-http`). |
| `SUPABASE_URL` | Your Supabase project URL. |
| `SUPABASE_JWT_SECRET` | JWT secret for verifying Supabase auth tokens. |
| `SUPABASE_SERVICE_ROLE_KEY` | Service role key for server-side Supabase access. |
