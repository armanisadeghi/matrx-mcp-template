/**
 * Supabase client helpers for MCP servers.
 * Provides both user-scoped (RLS-respecting) and service-role clients.
 */

import { createClient, type SupabaseClient } from "@supabase/supabase-js";

function getEnvRequired(key: string): string {
  const value = process.env[key];
  if (!value) {
    throw new Error(`${key} environment variable is not set`);
  }
  return value;
}

export function getSupabaseUrl(): string {
  return getEnvRequired("SUPABASE_URL");
}

/**
 * Create a Supabase client authenticated as the user.
 * This client respects Row Level Security (RLS) policies.
 */
export function getUserSupabaseClient(userJwt: string): SupabaseClient {
  return createClient(getSupabaseUrl(), userJwt);
}

/**
 * Create a Supabase client with the service role key.
 * This client BYPASSES Row Level Security (RLS).
 * Use with caution — only for admin operations.
 */
export function getServiceSupabaseClient(): SupabaseClient {
  return createClient(
    getSupabaseUrl(),
    getEnvRequired("SUPABASE_SERVICE_ROLE_KEY")
  );
}
