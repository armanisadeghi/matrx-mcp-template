import { spawn } from "node:child_process";
import { createHash, timingSafeEqual } from "node:crypto";
import { createServer, IncomingMessage, ServerResponse } from "node:http";
import { mkdir, readFile, rm, stat, writeFile } from "node:fs/promises";
import path from "node:path";

type OverlayFile = {
  path: string;
  content: string;
  encoding?: "utf8" | "base64";
};

type DeployRequest = {
  name: string;
  description?: string;
  slug?: string;
  hostname?: string;
  files?: OverlayFile[];
  dryRun?: boolean;
  overwrite?: boolean;
  workersDev?: boolean;
};

type RunResult = {
  code: number;
  stdout: string;
  stderr: string;
};

const PORT = Number(process.env.PORT || "8080");
const DEPLOYER_API_KEY = process.env.DEPLOYER_API_KEY || "";
const CLOUDFLARE_ACCOUNT_ID = process.env.CLOUDFLARE_ACCOUNT_ID || "";
const CLOUDFLARE_API_TOKEN = process.env.CLOUDFLARE_API_TOKEN || "";
const DEFAULT_DOMAIN = normalizeHostname(process.env.CLOUDFLARE_DEFAULT_DOMAIN || "");
const WORKERS_SUBDOMAIN = normalizeHostname(process.env.CLOUDFLARE_WORKERS_SUBDOMAIN || "");
const PROJECTS_DIR = path.resolve(process.env.WORKER_PROJECTS_DIR || "/data/workers");
const TEMPLATE_DIR = path.resolve(
  process.env.MCP_TEMPLATE_DIR ||
    path.join(import.meta.dirname, "../../../generators/templates/typescript-cloudflare")
);
const DEPLOY_TIMEOUT_MS = Number(process.env.DEPLOY_TIMEOUT_MS || "300000");
const VERIFY_TIMEOUT_MS = Number(process.env.VERIFY_TIMEOUT_MS || "30000");

const activeDeployments = new Set<string>();

function json(res: ServerResponse, status: number, body: unknown) {
  const data = JSON.stringify(body, null, 2);
  res.writeHead(status, {
    "Content-Type": "application/json",
    "Cache-Control": "no-store",
  });
  res.end(data);
}

function normalizeHostname(value: string): string {
  return value.trim().replace(/^https?:\/\//, "").replace(/\/.*$/, "").toLowerCase();
}

function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "");
}

function assertSlug(slug: string): string {
  if (!/^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$/.test(slug)) {
    throw httpError(400, "Slug must be 3-64 lowercase letters, numbers, or hyphens.");
  }
  return slug;
}

function assertHostname(hostname: string): string {
  const normalized = normalizeHostname(hostname);
  if (!normalized) return "";
  if (normalized.includes("*") || normalized.includes(":")) {
    throw httpError(400, "Hostname must be an exact domain or subdomain without wildcard or port.");
  }
  if (!/^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$/.test(normalized)) {
    throw httpError(400, "Hostname is not a valid DNS name.");
  }
  return normalized;
}

function httpError(status: number, message: string) {
  const error = new Error(message) as Error & { status?: number };
  error.status = status;
  return error;
}

function isAuthorized(req: IncomingMessage): boolean {
  if (!DEPLOYER_API_KEY) return false;
  const header = req.headers.authorization || "";
  const token = header.replace(/^Bearer\s+/i, "").trim();
  if (!token) return false;

  const expected = createHash("sha256").update(DEPLOYER_API_KEY).digest();
  const actual = createHash("sha256").update(token).digest();
  return timingSafeEqual(expected, actual);
}

async function readJsonBody(req: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let total = 0;

  for await (const chunk of req) {
    const buffer = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk);
    total += buffer.length;
    if (total > 2_000_000) {
      throw httpError(413, "Request body is too large.");
    }
    chunks.push(buffer);
  }

  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    throw httpError(400, "Request body must be valid JSON.");
  }
}

function validateDeployRequest(value: unknown): DeployRequest {
  if (!value || typeof value !== "object") {
    throw httpError(400, "Request body must be a JSON object.");
  }

  const body = value as Record<string, unknown>;
  if (typeof body.name !== "string" || !body.name.trim()) {
    throw httpError(400, "name is required.");
  }

  const files = body.files;
  if (files !== undefined) {
    if (!Array.isArray(files) || files.length > 32) {
      throw httpError(400, "files must be an array with at most 32 entries.");
    }
    for (const file of files) {
      if (!file || typeof file !== "object") {
        throw httpError(400, "Each file overlay must be an object.");
      }
      const overlay = file as Record<string, unknown>;
      if (typeof overlay.path !== "string" || typeof overlay.content !== "string") {
        throw httpError(400, "Each file overlay needs string path and content fields.");
      }
      if (overlay.encoding !== undefined && overlay.encoding !== "utf8" && overlay.encoding !== "base64") {
        throw httpError(400, "File encoding must be utf8 or base64.");
      }
      if (overlay.content.length > 1_500_000) {
        throw httpError(400, `Overlay file ${overlay.path} is too large.`);
      }
    }
  }

  return {
    name: body.name.trim(),
    description: typeof body.description === "string" ? body.description.trim() : "An MCP server",
    slug: typeof body.slug === "string" && body.slug.trim() ? body.slug.trim() : undefined,
    hostname: typeof body.hostname === "string" && body.hostname.trim() ? body.hostname.trim() : undefined,
    files: files as OverlayFile[] | undefined,
    dryRun: body.dryRun === true,
    overwrite: body.overwrite !== false,
    workersDev: body.workersDev !== false,
  };
}

async function copyTemplate(source: string, target: string) {
  await mkdir(target, { recursive: true });
  const entries = await import("node:fs/promises").then((fs) => fs.readdir(source, { withFileTypes: true }));

  for (const entry of entries) {
    const from = path.join(source, entry.name);
    const to = path.join(target, entry.name);

    if (entry.isDirectory()) {
      await copyTemplate(from, to);
    } else if (entry.isFile()) {
      const content = await readFile(from);
      await mkdir(path.dirname(to), { recursive: true });
      await writeFile(to, content);
    }
  }
}

async function replacePlaceholders(projectDir: string, replacements: Record<string, string>) {
  const fs = await import("node:fs/promises");
  const editable = new Set([".ts", ".json", ".toml", ".md", ".example"]);

  async function visit(dir: string) {
    const entries = await fs.readdir(dir, { withFileTypes: true });
    for (const entry of entries) {
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        await visit(fullPath);
        continue;
      }
      if (!entry.isFile()) continue;

      const ext = path.extname(entry.name);
      if (!editable.has(ext)) continue;

      let content = await fs.readFile(fullPath, "utf8");
      for (const [from, to] of Object.entries(replacements)) {
        content = content.split(from).join(to);
      }
      await fs.writeFile(fullPath, content);
    }
  }

  await visit(projectDir);
}

function assertOverlayPath(relativePath: string): string {
  if (relativePath.includes("\0")) throw httpError(400, "File path cannot contain null bytes.");
  if (path.isAbsolute(relativePath)) throw httpError(400, `File path ${relativePath} must be relative.`);

  const normalized = path.normalize(relativePath);
  if (normalized.startsWith("..") || normalized.includes(`${path.sep}..${path.sep}`)) {
    throw httpError(400, `File path ${relativePath} cannot escape the project directory.`);
  }
  if (normalized === "wrangler.toml" || normalized.endsWith(`${path.sep}wrangler.toml`)) {
    throw httpError(400, "wrangler.toml is managed by the deployer.");
  }
  if (normalized === ".env" || normalized.endsWith(`${path.sep}.env`)) {
    throw httpError(400, ".env overlays are not allowed.");
  }

  return normalized;
}

async function applyOverlayFiles(projectDir: string, files: OverlayFile[] = []) {
  for (const file of files) {
    const relativePath = assertOverlayPath(file.path);
    const content = file.encoding === "base64"
      ? Buffer.from(file.content, "base64")
      : Buffer.from(file.content, "utf8");
    const outputPath = path.join(projectDir, relativePath);

    await mkdir(path.dirname(outputPath), { recursive: true });
    await writeFile(outputPath, content);
  }
}

async function configureWrangler(projectDir: string, hostname: string, workersDev: boolean) {
  const wranglerPath = path.join(projectDir, "wrangler.toml");
  let content = await readFile(wranglerPath, "utf8");

  content = content.replace(/\n?workers_dev\s*=.*\n/g, "\n");
  content += `\nworkers_dev = ${workersDev ? "true" : "false"}\n`;

  if (hostname) {
    content = content.replace(/\n?routes\s*=\s*\[[\s\S]*?\]\n/g, "\n");
    content += `\nroutes = [\n  { pattern = "${hostname}", custom_domain = true }\n]\n`;
  }

  await writeFile(wranglerPath, content);
}

function run(command: string, args: string[], cwd: string, timeoutMs: number): Promise<RunResult> {
  return new Promise((resolve, reject) => {
    const child = spawn(command, args, {
      cwd,
      env: {
        ...process.env,
        CLOUDFLARE_ACCOUNT_ID,
        CLOUDFLARE_API_TOKEN,
        WRANGLER_SEND_METRICS: "false",
      },
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    const timer = setTimeout(() => {
      child.kill("SIGTERM");
      reject(httpError(504, `${command} ${args.join(" ")} timed out after ${timeoutMs}ms.`));
    }, timeoutMs);

    child.stdout.on("data", (data) => {
      stdout += data.toString();
      stdout = stdout.slice(-12000);
    });
    child.stderr.on("data", (data) => {
      stderr += data.toString();
      stderr = stderr.slice(-12000);
    });
    child.on("error", (error) => {
      clearTimeout(timer);
      reject(error);
    });
    child.on("close", (code) => {
      clearTimeout(timer);
      resolve({ code: code ?? 1, stdout, stderr });
    });
  });
}

async function verifyMcp(url: string) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), VERIFY_TIMEOUT_MS);

  try {
    const health = await fetch(`${url}/`, { signal: controller.signal });
    if (!health.ok) throw new Error(`GET / returned ${health.status}`);

    const init = await fetch(`${url}/mcp`, {
      method: "POST",
      signal: controller.signal,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json, text/event-stream",
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: 1,
        method: "initialize",
        params: {
          protocolVersion: "2025-03-26",
          capabilities: {},
          clientInfo: { name: "matrx-cloudflare-deployer", version: "1.0.0" },
        },
      }),
    });

    const sessionId = init.headers.get("mcp-session-id");
    const initBody = await init.text();
    if (!init.ok) throw new Error(`MCP initialize returned ${init.status}: ${initBody.slice(0, 400)}`);
    if (!sessionId) throw new Error("MCP initialize did not return mcp-session-id.");

    const tools = await fetch(`${url}/mcp`, {
      method: "POST",
      signal: controller.signal,
      headers: {
        "Content-Type": "application/json",
        Accept: "application/json, text/event-stream",
        "mcp-session-id": sessionId,
      },
      body: JSON.stringify({
        jsonrpc: "2.0",
        id: 2,
        method: "tools/list",
        params: {},
      }),
    });

    const toolsBody = await tools.text();
    if (!tools.ok) throw new Error(`MCP tools/list returned ${tools.status}: ${toolsBody.slice(0, 400)}`);
    if (!toolsBody.includes("\"tools\"")) throw new Error("MCP tools/list response did not include tools.");
  } finally {
    clearTimeout(timer);
  }
}

async function deployMcp(body: DeployRequest) {
  if (!CLOUDFLARE_ACCOUNT_ID || !CLOUDFLARE_API_TOKEN) {
    throw httpError(500, "CLOUDFLARE_ACCOUNT_ID and CLOUDFLARE_API_TOKEN must be configured.");
  }

  await stat(TEMPLATE_DIR).catch(() => {
    throw httpError(500, `Template directory not found: ${TEMPLATE_DIR}`);
  });

  const slug = assertSlug(body.slug ? slugify(body.slug) : slugify(body.name));
  const hostname = assertHostname(body.hostname || (DEFAULT_DOMAIN ? `${slug}.${DEFAULT_DOMAIN}` : ""));
  const projectDir = path.join(PROJECTS_DIR, slug);
  const workersDevUrl = WORKERS_SUBDOMAIN ? `https://${slug}.${WORKERS_SUBDOMAIN}.workers.dev` : "";
  const url = hostname ? `https://${hostname}` : workersDevUrl;

  if (!body.dryRun && !url) {
    throw httpError(
      400,
      "Set hostname, CLOUDFLARE_DEFAULT_DOMAIN, or CLOUDFLARE_WORKERS_SUBDOMAIN so the deployed Worker can be verified."
    );
  }

  if (activeDeployments.has(slug)) {
    throw httpError(409, `Deployment already in progress for ${slug}.`);
  }
  activeDeployments.add(slug);

  try {
    if (body.overwrite) {
      await rm(projectDir, { recursive: true, force: true });
    } else {
      await stat(projectDir).then(
        () => {
          throw httpError(409, `Project already exists for ${slug}. Set overwrite=true to replace it.`);
        },
        () => undefined
      );
    }

    await copyTemplate(TEMPLATE_DIR, projectDir);
    await replacePlaceholders(projectDir, {
      "{{MCP_NAME}}": body.name,
      "{{MCP_SLUG}}": slug,
      "{{MCP_DESCRIPTION}}": body.description || "An MCP server",
    });
    await applyOverlayFiles(projectDir, body.files);
    await configureWrangler(projectDir, hostname, body.workersDev !== false);

    const install = await run("npm", ["install", "--no-audit", "--fund=false"], projectDir, DEPLOY_TIMEOUT_MS);
    if (install.code !== 0) {
      throw httpError(500, `npm install failed:\n${install.stderr || install.stdout}`);
    }

    const deployArgs = body.dryRun
      ? ["wrangler", "deploy", "--dry-run", "--outdir", path.join(projectDir, ".dry-run")]
      : ["wrangler", "deploy"];
    const deploy = await run("npx", deployArgs, projectDir, DEPLOY_TIMEOUT_MS);
    if (deploy.code !== 0) {
      throw httpError(500, `Wrangler deploy failed:\n${deploy.stderr || deploy.stdout}`);
    }

    let verified = false;
    let verificationError = "";
    if (!body.dryRun && url) {
      try {
        await verifyMcp(url);
        verified = true;
      } catch (error) {
        verificationError = error instanceof Error ? error.message : String(error);
      }
    }

    return {
      ok: true,
      slug,
      workerName: slug,
      hostname: hostname || null,
      url: url || null,
      mcpUrl: url ? `${url}/mcp` : null,
      projectDir,
      dryRun: body.dryRun === true,
      verified,
      verificationError: verificationError || undefined,
      deployLog: deploy.stdout.slice(-4000),
    };
  } finally {
    activeDeployments.delete(slug);
  }
}

async function handle(req: IncomingMessage, res: ServerResponse) {
  try {
    if (req.method === "GET" && req.url === "/health") {
      json(res, 200, {
        ok: true,
        service: "matrx-cloudflare-deployer",
        configured: {
          deployerApiKey: Boolean(DEPLOYER_API_KEY),
          cloudflareAccountId: Boolean(CLOUDFLARE_ACCOUNT_ID),
          cloudflareApiToken: Boolean(CLOUDFLARE_API_TOKEN),
          defaultDomain: DEFAULT_DOMAIN || null,
          workersSubdomain: WORKERS_SUBDOMAIN || null,
          templateDir: TEMPLATE_DIR,
          projectsDir: PROJECTS_DIR,
        },
      });
      return;
    }

    if (req.method === "POST" && req.url === "/v1/cloudflare/mcps") {
      if (!isAuthorized(req)) {
        json(res, 401, { ok: false, error: "Unauthorized" });
        return;
      }

      const body = validateDeployRequest(await readJsonBody(req));
      const result = await deployMcp(body);
      json(res, 200, result);
      return;
    }

    json(res, 404, { ok: false, error: "Not found" });
  } catch (error) {
    const status = typeof (error as { status?: unknown }).status === "number"
      ? (error as { status: number }).status
      : 500;
    const message = error instanceof Error ? error.message : String(error);
    json(res, status, { ok: false, error: message });
  }
}

createServer((req, res) => {
  void handle(req, res);
}).listen(PORT, "0.0.0.0", () => {
  console.log(`matrx-cloudflare-deployer listening on :${PORT}`);
});
