-- MCP Registry: Tracks all deployed MCP servers
-- Applied to: automation-matrix Supabase project (txzxabzwovsujtloxrus)
-- Date: 2026-02-08

CREATE TABLE IF NOT EXISTS public.mcp_registry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT DEFAULT 'An MCP server',
    language TEXT NOT NULL CHECK (language IN ('python', 'typescript')),
    tier TEXT NOT NULL CHECK (tier IN ('cloudflare', 'vps')),
    auth_type TEXT NOT NULL DEFAULT 'apikey' CHECK (auth_type IN ('none', 'apikey', 'supabase')),
    db_type TEXT NOT NULL DEFAULT 'none' CHECK (db_type IN ('none', 'supabase', 'postgres')),
    endpoint_url TEXT,
    status TEXT NOT NULL DEFAULT 'scaffolded' CHECK (status IN ('scaffolded', 'developing', 'deployed', 'active', 'inactive', 'deprecated')),
    repo_url TEXT,
    is_separate_repo BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    deployed_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- Index for common queries
CREATE INDEX IF NOT EXISTS idx_mcp_registry_status ON public.mcp_registry(status);
CREATE INDEX IF NOT EXISTS idx_mcp_registry_tier ON public.mcp_registry(tier);
CREATE INDEX IF NOT EXISTS idx_mcp_registry_slug ON public.mcp_registry(slug);

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_mcp_registry_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_mcp_registry_updated_at
    BEFORE UPDATE ON public.mcp_registry
    FOR EACH ROW
    EXECUTE FUNCTION public.update_mcp_registry_updated_at();

-- Enable RLS (service role will bypass, regular users read-only)
ALTER TABLE public.mcp_registry ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone authenticated can read the registry
CREATE POLICY "Authenticated users can read MCP registry"
    ON public.mcp_registry
    FOR SELECT
    TO authenticated
    USING (true);

-- Policy: Service role can do everything
CREATE POLICY "Service role has full access to MCP registry"
    ON public.mcp_registry
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

COMMENT ON TABLE public.mcp_registry IS 'Registry of all MCP servers created by the AI Matrx MCP Factory';
