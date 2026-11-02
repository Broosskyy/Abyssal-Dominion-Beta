-- M144 canonical admin/content authority foundation for PostgreSQL.
-- The Godot client and V38 web surface remain non-authoritative consumers.

create table if not exists staff_roles (
  id text primary key,
  label text not null,
  description text not null default '',
  enabled boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists staff_permissions (
  id text primary key,
  description text not null default '',
  critical boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists staff_role_permissions (
  role_id text not null references staff_roles(id) on delete cascade,
  permission_id text not null references staff_permissions(id) on delete cascade,
  primary key (role_id, permission_id)
);

create table if not exists staff_user_roles (
  account_id uuid not null,
  role_id text not null references staff_roles(id) on delete cascade,
  environment text not null check (environment in ('TEST','STAGING','GLOBAL')),
  granted_by uuid not null,
  granted_at timestamptz not null default now(),
  revoked_at timestamptz,
  primary key (account_id, role_id, environment)
);

create table if not exists admin_content_types (
  id text primary key,
  schema_version integer not null default 1,
  schema_json jsonb not null,
  enabled boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists content_approvals (
  id uuid primary key,
  content_id text not null,
  revision integer not null,
  environment text not null check (environment in ('TEST','STAGING','GLOBAL')),
  required_votes integer not null check (required_votes between 1 and 2),
  requested_by uuid not null,
  requested_at timestamptz not null default now(),
  status text not null check (status in ('pending','approved','rejected','cancelled','executed')),
  unique (content_id, revision, environment)
);

create table if not exists content_approval_votes (
  approval_id uuid not null references content_approvals(id) on delete cascade,
  voter_account_id uuid not null,
  decision text not null check (decision in ('approve','reject')),
  reason text not null default '',
  voted_at timestamptz not null default now(),
  primary key (approval_id, voter_account_id)
);

create table if not exists admin_audit_events (
  id uuid primary key,
  request_id text not null unique,
  actor_account_id uuid not null,
  operation text not null,
  permission_id text not null,
  environment text not null,
  target_type text not null,
  target_id text not null,
  before_revision integer,
  after_revision integer,
  evidence jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists idx_staff_user_roles_active on staff_user_roles(account_id, environment) where revoked_at is null;
create index if not exists idx_content_approvals_status on content_approvals(environment, status, requested_at);
create index if not exists idx_admin_audit_target on admin_audit_events(target_type, target_id, created_at desc);
create index if not exists idx_admin_audit_actor on admin_audit_events(actor_account_id, created_at desc);
