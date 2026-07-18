-- Protein database schema (Postgres).
-- Derived from the original MySQL/InnoDB design (see docs/er-diagram.png),
-- translated to idiomatic Postgres: identity PKs, TIMESTAMPTZ, explicit FK
-- indexes (Postgres does not auto-index FK columns the way InnoDB does).

-- ============================================================
-- Core table
-- ============================================================

CREATE TABLE proteins (
    protein_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    entry         TEXT NOT NULL UNIQUE,       -- UniProt accession, e.g. P58486
    entry_name    TEXT NOT NULL,              -- e.g. MENC_SALTY
    organism      TEXT,
    protein_names TEXT,
    sequence      TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================
-- One-to-many detail tables (protein_id -> proteins.protein_id)
-- ============================================================

CREATE TABLE functions (
    function_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id   INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    description  TEXT NOT NULL
);
CREATE INDEX idx_functions_protein_id ON functions(protein_id);

CREATE TABLE subcellular_locations (
    location_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id   INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    location     TEXT NOT NULL
);
CREATE INDEX idx_subcellular_locations_protein_id ON subcellular_locations(protein_id);

CREATE TABLE disease_involvement (
    disease_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id   INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    disease_name TEXT,
    description  TEXT,
    omim_id      TEXT
);
CREATE INDEX idx_disease_involvement_protein_id ON disease_involvement(protein_id);

CREATE TABLE biotechnological_uses (
    use_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id   INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    description  TEXT NOT NULL
);
CREATE INDEX idx_biotechnological_uses_protein_id ON biotechnological_uses(protein_id);

CREATE TABLE pharmaceutical_uses (
    pharma_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id   INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    description  TEXT NOT NULL
);
CREATE INDEX idx_pharmaceutical_uses_protein_id ON pharmaceutical_uses(protein_id);

CREATE TABLE toxic_doses (
    dose_id           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id        INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    dose_description  TEXT NOT NULL,
    measurement_unit  TEXT
);
CREATE INDEX idx_toxic_doses_protein_id ON toxic_doses(protein_id);

CREATE TABLE allergenic_properties (
    property_id  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id   INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    description  TEXT NOT NULL
);
CREATE INDEX idx_allergenic_properties_protein_id ON allergenic_properties(protein_id);

CREATE TABLE interactions (
    interaction_id    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id        INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    interacting_protein TEXT NOT NULL,
    interaction_type  TEXT
);
CREATE INDEX idx_interactions_protein_id ON interactions(protein_id);

CREATE TABLE taxonomic_lineage (
    lineage_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id   INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    rank_order   INTEGER NOT NULL,   -- position in the lineage, 0 = highest rank
    lineage_path TEXT NOT NULL       -- a single taxon name at this rank
);
CREATE INDEX idx_taxonomic_lineage_protein_id ON taxonomic_lineage(protein_id);

CREATE TABLE active_sites (
    site_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id   INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    description  TEXT,
    position     TEXT
);
CREATE INDEX idx_active_sites_protein_id ON active_sites(protein_id);

CREATE TABLE binding_sites (
    binding_id      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id      INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    start_position  INTEGER,
    end_position    INTEGER,
    ligand          TEXT,
    description     TEXT
);
CREATE INDEX idx_binding_sites_protein_id ON binding_sites(protein_id);

CREATE TABLE mutagenesis (
    mutagenesis_id     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id         INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    position_start     INTEGER,
    position_end       INTEGER,
    original_residue   TEXT,
    mutated_residue    TEXT,
    description        TEXT,
    effect              TEXT
);
CREATE INDEX idx_mutagenesis_protein_id ON mutagenesis(protein_id);

CREATE TABLE topological_domains (
    domain_id       INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    protein_id      INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    domain_name     TEXT,
    start_position  INTEGER,
    end_position    INTEGER,
    description     TEXT
);
CREATE INDEX idx_topological_domains_protein_id ON topological_domains(protein_id);

-- ============================================================
-- Reference tables + many-to-many junctions
-- ============================================================

CREATE TABLE genes (
    gene_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gene_name TEXT NOT NULL UNIQUE
);

CREATE TABLE protein_genes (
    protein_id INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    gene_id    INTEGER NOT NULL REFERENCES genes(gene_id) ON DELETE CASCADE,
    PRIMARY KEY (protein_id, gene_id)
);
CREATE INDEX idx_protein_genes_gene_id ON protein_genes(gene_id);

CREATE TABLE pathways (
    pathway_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    pathway_name TEXT NOT NULL UNIQUE
);

CREATE TABLE protein_pathways (
    protein_id INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    pathway_id INTEGER NOT NULL REFERENCES pathways(pathway_id) ON DELETE CASCADE,
    PRIMARY KEY (protein_id, pathway_id)
);
CREATE INDEX idx_protein_pathways_pathway_id ON protein_pathways(pathway_id);

CREATE TABLE protein_families (
    family_id   INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    family_name TEXT NOT NULL UNIQUE
);

CREATE TABLE protein_family_memberships (
    protein_id INTEGER NOT NULL REFERENCES proteins(protein_id) ON DELETE CASCADE,
    family_id  INTEGER NOT NULL REFERENCES protein_families(family_id) ON DELETE CASCADE,
    PRIMARY KEY (protein_id, family_id)
);
CREATE INDEX idx_protein_family_memberships_family_id ON protein_family_memberships(family_id);
