# Bug Tracker MCP

A VPS-deployed MCP server for bug tracking, built with TypeScript and designed for Supabase JWT authentication.

## Overview

This example demonstrates a Model Context Protocol server that exposes bug tracking tools over HTTP. It is intended to run on a VPS (via Docker) and authenticate users through Supabase JWTs. Row Level Security (RLS) in Supabase ensures each user only accesses their own data.

## Available Tools

| Tool | Description |
|------|-------------|
| `submit_bug` | Submit a new bug report with title, description, severity, and app name |
| `list_bugs` | List bugs with optional filters for status, severity, app name, and limit |
| `update_bug_status` | Update the status of a bug (reviewing, in_progress, needs_human, resolved, closed) |
| `add_bug_comment` | Add a comment to a bug report, with support for internal-only comments |
| `get_bug_details` | Get full details of a specific bug including comments and history |

## Setup

1. Copy the environment file and fill in your values:
   ```bash
   cp .env.example .env
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Run in development mode:
   ```bash
   npm run dev
   ```

4. Or build and run with Docker:
   ```bash
   docker compose up --build
   ```

The server listens on port 8000 by default with the MCP endpoint at `POST /mcp` and a health check at `GET /health`.

## Important Note

The tool implementations in this example are **placeholder/demo** only. They return mock data and do not connect to a real database. To make this production-ready, you need to:

- Wire up each tool to real Supabase queries using `@supabase/supabase-js`
- Validate incoming JWTs with `jose` and extract the user context
- Apply the user's JWT when creating the Supabase client so that RLS policies are enforced
- Create the corresponding tables and RLS policies in your Supabase project
