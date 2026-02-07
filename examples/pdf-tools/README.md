# PDF Tools MCP

A working example of a PDF manipulation and text extraction MCP server deployed to Cloudflare Workers with API key authentication. Built with Python and [FastMCP](https://github.com/jlowin/fastmcp).

## Available Tools

| Tool | Description |
|------|-------------|
| `extract_text_from_pdf` | Extract all text from a base64-encoded PDF. Returns the full text, page count, and character count. |
| `get_pdf_metadata` | Extract metadata (title, author, subject, creator, producer, dates, page count) from a PDF. |
| `count_pdf_pages` | Return the total number of pages in a PDF. |
| `extract_text_from_page` | Extract text from a specific page (0-indexed) of a PDF. |
| `merge_pdfs_info` | Get step-by-step instructions and sample code for merging multiple PDFs. |

All tools accept PDFs as base64-encoded strings and handle errors gracefully with clear error messages.

## Setup

1. Copy the environment file and set your API keys:

   ```bash
   cp .env.example .env
   ```

2. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

3. Run locally:

   ```bash
   python src/server.py
   ```

## Deploy to Cloudflare Workers

```bash
npx wrangler deploy
```

Set your API keys as a secret:

```bash
npx wrangler secret put MCP_API_KEYS
```

## Authentication

The server uses API key authentication. Set the `MCP_API_KEYS` environment variable to a comma-separated list of valid keys. The `src/auth.py` module provides the `validate_api_key` helper used to verify incoming requests.
