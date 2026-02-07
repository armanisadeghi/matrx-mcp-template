/**
 * Authentication utilities for MCP servers.
 * Supports: No auth, API key, and Supabase JWT verification.
 */

import { jwtVerify, type JWTPayload } from "jose";

// --- API Key Auth ---

const VALID_API_KEYS = new Set(
  (process.env.MCP_API_KEYS || "")
    .split(",")
    .map((k) => k.trim())
    .filter(Boolean)
);

export function validateApiKey(apiKey: string): boolean {
  return VALID_API_KEYS.has(apiKey);
}

export function extractBearerToken(authHeader: string | null): string {
  if (!authHeader) return "";
  return authHeader.replace(/^Bearer\s+/i, "").trim();
}

export function requireApiKey(authHeader: string | null): void {
  const key = extractBearerToken(authHeader);
  if (!validateApiKey(key)) {
    throw new Error("Invalid or missing API key");
  }
}

// --- Supabase JWT Auth ---

function getSupabaseJwtSecret(): Uint8Array {
  const secret = process.env.SUPABASE_JWT_SECRET;
  if (!secret) {
    throw new Error("SUPABASE_JWT_SECRET environment variable is not set");
  }
  return new TextEncoder().encode(secret);
}

export interface SupabaseUserPayload extends JWTPayload {
  sub: string;
  email?: string;
  role?: string;
  aud?: string;
}

export async function verifySupabaseToken(
  token: string
): Promise<SupabaseUserPayload> {
  try {
    const { payload } = await jwtVerify(token, getSupabaseJwtSecret(), {
      audience: "authenticated",
    });
    return payload as SupabaseUserPayload;
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Invalid token: ${error.message}`);
    }
    throw new Error("Invalid token");
  }
}

export async function extractUserId(token: string): Promise<string> {
  const payload = await verifySupabaseToken(token);
  if (!payload.sub) {
    throw new Error("Token does not contain a user ID");
  }
  return payload.sub;
}

export async function requireSupabaseAuth(
  authHeader: string | null
): Promise<SupabaseUserPayload> {
  const token = extractBearerToken(authHeader);
  if (!token) {
    throw new Error("Missing Authorization header");
  }
  return verifySupabaseToken(token);
}
