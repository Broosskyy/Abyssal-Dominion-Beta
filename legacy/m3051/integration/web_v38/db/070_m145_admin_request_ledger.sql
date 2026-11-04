-- M145 server-side reference migration. Execute only in a reviewed V38 backend deployment.
CREATE TABLE IF NOT EXISTS admin_request_ledger (
    request_id UUID PRIMARY KEY,
    actor_account_id UUID NOT NULL,
    environment VARCHAR(16) NOT NULL CHECK (environment IN ('TEST','STAGING','GLOBAL')),
    operation VARCHAR(96) NOT NULL,
    request_hash CHAR(64) NOT NULL,
    status VARCHAR(24) NOT NULL DEFAULT 'processing',
    response_json JSONB,
    audit_event_id UUID,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ NOT NULL
);

CREATE INDEX IF NOT EXISTS ix_admin_request_ledger_expiry ON admin_request_ledger (expires_at);

CREATE TABLE IF NOT EXISTS content_snapshot_receipt (
    receipt_id UUID PRIMARY KEY,
    environment VARCHAR(16) NOT NULL,
    content_version VARCHAR(96) NOT NULL,
    content_hash CHAR(64) NOT NULL,
    signature_key_id VARCHAR(96) NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL,
    UNIQUE(environment, content_version)
);
