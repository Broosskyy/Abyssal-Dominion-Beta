-- M104 FUTURE SERVER SCHEMA DRAFT. NOT EXECUTED BY GODOT CLIENT.
CREATE TABLE accounts (
 account_id UUID PRIMARY KEY, status TEXT NOT NULL, revision BIGINT NOT NULL DEFAULT 0,
 created_at TIMESTAMPTZ NOT NULL, updated_at TIMESTAMPTZ NOT NULL);
CREATE TABLE captains (
 captain_id UUID PRIMARY KEY, account_id UUID NOT NULL REFERENCES accounts(account_id),
 captain_name TEXT NOT NULL, revision BIGINT NOT NULL DEFAULT 0, locale TEXT);
CREATE TABLE account_providers (
 provider_link_id UUID PRIMARY KEY, account_id UUID NOT NULL REFERENCES accounts(account_id),
 provider TEXT NOT NULL, provider_subject TEXT NOT NULL, verified_at TIMESTAMPTZ NOT NULL,
 UNIQUE(provider, provider_subject));
CREATE TABLE sessions (
 session_id UUID PRIMARY KEY, account_id UUID NOT NULL REFERENCES accounts(account_id),
 environment TEXT NOT NULL, token_hash TEXT NOT NULL, issued_at TIMESTAMPTZ NOT NULL,
 expires_at TIMESTAMPTZ NOT NULL, revoked_at TIMESTAMPTZ);
CREATE TABLE inventory_items (
 inventory_item_id UUID PRIMARY KEY, account_id UUID NOT NULL REFERENCES accounts(account_id),
 definition_id TEXT NOT NULL, quantity BIGINT NOT NULL DEFAULT 0, revision BIGINT NOT NULL DEFAULT 0,
 UNIQUE(account_id, definition_id));
CREATE TABLE wallet_balances (
 wallet_balance_id UUID PRIMARY KEY, account_id UUID NOT NULL REFERENCES accounts(account_id),
 currency_id TEXT NOT NULL, balance BIGINT NOT NULL DEFAULT 0, revision BIGINT NOT NULL DEFAULT 0,
 UNIQUE(account_id, currency_id));
CREATE TABLE entitlements (
 entitlement_id UUID PRIMARY KEY, account_id UUID NOT NULL REFERENCES accounts(account_id),
 entitlement_key TEXT NOT NULL, source TEXT NOT NULL, granted_at TIMESTAMPTZ NOT NULL, revoked_at TIMESTAMPTZ,
 UNIQUE(account_id, entitlement_key));
CREATE TABLE transaction_ledger (
 transaction_id UUID PRIMARY KEY, client_request_id TEXT NOT NULL UNIQUE,
 account_id UUID NOT NULL REFERENCES accounts(account_id), environment TEXT NOT NULL,
 domain TEXT NOT NULL, operation TEXT NOT NULL, definition_id TEXT NOT NULL,
 quantity BIGINT NOT NULL, expected_revision BIGINT NOT NULL, result TEXT NOT NULL,
 created_at TIMESTAMPTZ NOT NULL);
CREATE TABLE progression (
 captain_id UUID PRIMARY KEY REFERENCES captains(captain_id),
 pirate_level INT NOT NULL DEFAULT 1, xp BIGINT NOT NULL DEFAULT 0,
 map_level INT NOT NULL DEFAULT 1, revision BIGINT NOT NULL DEFAULT 0);
