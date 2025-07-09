-- #############################################################################
-- #
-- #  Optimized Schema (Fully Relational) with Timestamps for Storing 200M+ URLs
-- #
-- #############################################################################

-- Create test schema and set search_path
CREATE SCHEMA IF NOT EXISTS test;
SET search_path TO test;

-- Install necessary extension if it's not already installed.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =============================================================================
--  1. LOOKUP TABLES
-- =============================================================================

CREATE TABLE url_schemes (
    id          SMALLSERIAL PRIMARY KEY,
    scheme_name VARCHAR(8) NOT NULL UNIQUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE url_schemes IS 'Stores unique URL schemes like http, https, etc.';
COMMENT ON COLUMN url_schemes.created_at IS 'Timestamp of when the scheme was first seen.';


CREATE TABLE url_components (
    id             SERIAL PRIMARY KEY,
    component_text TEXT NOT NULL UNIQUE,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE url_components IS 'Unified store for all unique string parts of hosts and paths.';
COMMENT ON COLUMN url_components.created_at IS 'Timestamp of when the component string was first seen.';


CREATE TABLE query_keys (
    id         SERIAL PRIMARY KEY,
    key_name   TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE query_keys IS 'Stores unique query parameter key names (e.g., "utm_source", "q").';
COMMENT ON COLUMN query_keys.created_at IS 'Timestamp of when the query key was first seen.';


CREATE TABLE query_values (
    id         SERIAL PRIMARY KEY,
    value_text TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE query_values IS 'Stores unique query parameter value strings (e.g., "google", "12345").';
COMMENT ON COLUMN query_values.created_at IS 'Timestamp of when the query value was first seen.';


-- =============================================================================
--  2. STRUCTURE TABLES
-- =============================================================================

CREATE TABLE hosts (
    id                    SERIAL PRIMARY KEY,
    reverse_component_ids INT[] NOT NULL UNIQUE,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
COMMENT ON TABLE hosts IS 'Represents unique hostnames, stored as an array of reversed component IDs.';
COMMENT ON COLUMN hosts.created_at IS 'Timestamp of when the host was first seen.';

CREATE INDEX idx_hosts_reverse_components ON hosts USING GIN (reverse_component_ids);


CREATE TABLE urls (
    id                   BIGSERIAL PRIMARY KEY,
    url_uuid             UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    scheme_id            SMALLINT NOT NULL,
    host_id              INT NOT NULL,
    path_component_ids   INT[],
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT fk_urls_scheme FOREIGN KEY (scheme_id) REFERENCES url_schemes (id),
    CONSTRAINT fk_urls_host   FOREIGN KEY (host_id)   REFERENCES hosts (id)
);
COMMENT ON TABLE urls IS 'The main table storing URL structures, without query parameters.';
COMMENT ON COLUMN urls.created_at IS 'Timestamp of when the base URL (scheme/host/path) was first inserted.';


CREATE TABLE url_query_params (
    url_id     BIGINT NOT NULL,
    key_id     INT NOT NULL,
    value_id   INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (url_id, key_id),

    CONSTRAINT fk_query_url   FOREIGN KEY (url_id)   REFERENCES urls (id) ON DELETE CASCADE,
    CONSTRAINT fk_query_key   FOREIGN KEY (key_id)   REFERENCES query_keys (id),
    CONSTRAINT fk_query_value FOREIGN KEY (value_id) REFERENCES query_values (id)
);
COMMENT ON TABLE url_query_params IS 'Linking table for the many-to-many relationship between URLs and their query key-value pairs.';
COMMENT ON COLUMN url_query_params.created_at IS 'Timestamp of when this parameter was associated with the URL.';


-- =============================================================================
--  3. INDEXES ON MAIN TABLES (for performance)
-- =============================================================================

-- Indexes on the query parameter linking table
CREATE INDEX idx_url_query_params_key_value ON url_query_params (key_id, value_id);

-- Indexes on the main urls table
CREATE INDEX idx_urls_path_components ON urls USING GIN (path_component_ids);
CREATE INDEX idx_urls_host_id ON urls (host_id);

-- #############################################################################
-- #  End of Schema Definition
-- #############################################################################