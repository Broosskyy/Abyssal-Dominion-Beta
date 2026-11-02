# M144 — Admin Service Adapter and Build Hardening

M144 connects the M143 no-code admin model to a concrete future server boundary without pretending that a backend already exists. It also removes inherited parser/type blockers discovered by the supplemental native editor scan.

## Implemented

`ContentDraftStore` saves the admin draft snapshot in the Godot user data directory. Seed data remains the fallback for a new installation. Local statuses are restricted to `draft`, `validated`, `review` and `archived`.

`ContentAdminGateway` and `m144_admin_api_contract.json` define the same envelope for web and ingame admin. Writes include request ID, permission, environment, surface, client version and payload. A response is accepted only for a pending request, with all server fields, through verified transport.

The gateway reports `network_adapter: NOT_CONNECTED`. HTTP, staff session, MFA, idempotency storage, database transaction and audit signature belong to the future Abyssal Dominion backend.

`integration/web_v38/db/069_m144_unified_admin.sql` provides the relational foundation for staff roles, permissions, assignments, approval votes and append-only audit events. The route manifest lists the V38 integration points without claiming deployed routes.

The ingame overlay can select persisted drafts, edit JSON, save locally, validate, request local review and preview a future publish request. Publish preview never activates content.

## Replacement workflow

Stable gameplay IDs stay separate from visual payloads. Final `.glb`, texture, icon, UI, audio or VFX files replace existing AssetSlot payloads without renaming gameplay IDs.

## Deferred server work

- Implement authenticated `/api/admin/v1` handlers.
- Bind staff sessions and MFA to database identities.
- Enforce RBAC, approval separation and revisions transactionally.
- Store immutable audit evidence and signed snapshots.
- Connect V38 web and Godot to the same service.
- Certify exports with the exact Godot 4.7.2 editor and templates.
