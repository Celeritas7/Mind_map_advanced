-- ============================================================
-- Mind Map App - Database Schema
-- Mirrors Logi Assembly structure (Projects → Assemblies → Nodes + Links)
-- ============================================================

-- ============================================================
-- PROJECTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS mind_map_app_projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  icon TEXT DEFAULT '🧠',
  color TEXT DEFAULT '#3498db',
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- ASSEMBLIES TABLE (Mind Maps / Task Trees)
-- ============================================================
CREATE TABLE IF NOT EXISTS mind_map_app_assemblies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID REFERENCES mind_map_app_projects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  is_visible BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- NODES TABLE (Tasks / Ideas)
-- ============================================================
CREATE TABLE IF NOT EXISTS mind_map_app_nodes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assembly_id UUID NOT NULL REFERENCES mind_map_app_assemblies(id) ON DELETE CASCADE,
  name TEXT NOT NULL DEFAULT 'New Node',
  status TEXT DEFAULT 'NOT_STARTED',
  priority TEXT DEFAULT 'MEDIUM',
  notes TEXT DEFAULT '',
  tags TEXT DEFAULT '',
  qty INTEGER DEFAULT 1,
  group_num INTEGER DEFAULT 0,
  is_orphan BOOLEAN DEFAULT false,
  is_locked BOOLEAN DEFAULT false,
  x REAL DEFAULT 0,
  y REAL DEFAULT 0,
  deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- LINKS TABLE (Parent-Child Relationships)
-- ============================================================
CREATE TABLE IF NOT EXISTS mind_map_app_links (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assembly_id UUID NOT NULL REFERENCES mind_map_app_assemblies(id) ON DELETE CASCADE,
  parent_id UUID NOT NULL REFERENCES mind_map_app_nodes(id) ON DELETE CASCADE,
  child_id UUID NOT NULL REFERENCES mind_map_app_nodes(id) ON DELETE CASCADE,
  label TEXT DEFAULT '',
  deleted BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_mma_assemblies_project ON mind_map_app_assemblies(project_id);
CREATE INDEX IF NOT EXISTS idx_mma_nodes_assembly ON mind_map_app_nodes(assembly_id);
CREATE INDEX IF NOT EXISTS idx_mma_nodes_deleted ON mind_map_app_nodes(deleted);
CREATE INDEX IF NOT EXISTS idx_mma_links_assembly ON mind_map_app_links(assembly_id);
CREATE INDEX IF NOT EXISTS idx_mma_links_parent ON mind_map_app_links(parent_id);
CREATE INDEX IF NOT EXISTS idx_mma_links_child ON mind_map_app_links(child_id);

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION mind_map_app_update_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS mind_map_app_projects_updated ON mind_map_app_projects;
CREATE TRIGGER mind_map_app_projects_updated
  BEFORE UPDATE ON mind_map_app_projects
  FOR EACH ROW EXECUTE FUNCTION mind_map_app_update_timestamp();

DROP TRIGGER IF EXISTS mind_map_app_assemblies_updated ON mind_map_app_assemblies;
CREATE TRIGGER mind_map_app_assemblies_updated
  BEFORE UPDATE ON mind_map_app_assemblies
  FOR EACH ROW EXECUTE FUNCTION mind_map_app_update_timestamp();

DROP TRIGGER IF EXISTS mind_map_app_nodes_updated ON mind_map_app_nodes;
CREATE TRIGGER mind_map_app_nodes_updated
  BEFORE UPDATE ON mind_map_app_nodes
  FOR EACH ROW EXECUTE FUNCTION mind_map_app_update_timestamp();

DROP TRIGGER IF EXISTS mind_map_app_links_updated ON mind_map_app_links;
CREATE TRIGGER mind_map_app_links_updated
  BEFORE UPDATE ON mind_map_app_links
  FOR EACH ROW EXECUTE FUNCTION mind_map_app_update_timestamp();

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================
ALTER TABLE mind_map_app_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE mind_map_app_assemblies ENABLE ROW LEVEL SECURITY;
ALTER TABLE mind_map_app_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mind_map_app_links ENABLE ROW LEVEL SECURITY;

-- Public read/write for anon (same as logi assembly pattern)
CREATE POLICY mind_map_app_projects_all ON mind_map_app_projects FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY mind_map_app_assemblies_all ON mind_map_app_assemblies FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY mind_map_app_nodes_all ON mind_map_app_nodes FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY mind_map_app_links_all ON mind_map_app_links FOR ALL USING (true) WITH CHECK (true);
