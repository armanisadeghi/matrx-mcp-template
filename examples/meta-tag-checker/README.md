# Meta Tag Checker MCP

A working example of a simple, stateless MCP server deployed to Cloudflare Workers with no authentication. It provides SEO meta tag analysis and validation tools aimed at marketing professionals.

## Available Tools

| Tool | Description |
|---|---|
| `check_meta_title` | Validates a title tag against the recommended 30-60 character range. |
| `check_meta_description` | Validates a meta description against the recommended 120-160 character range. |
| `analyze_heading_structure` | Parses H1-H6 tags from HTML and checks for exactly one H1. |
| `check_open_graph_tags` | Extracts and validates `og:title`, `og:description`, `og:image`, and `og:url` from HTML. |
| `analyze_keyword_density` | Calculates keyword frequency and density percentage within a block of text. |

## Running Locally

```bash
pip install -r requirements.txt
python src/server.py
```

The server starts on `http://0.0.0.0:8000` using the streamable-http transport.

## Deploying to Cloudflare Workers

```bash
npx wrangler deploy
```
