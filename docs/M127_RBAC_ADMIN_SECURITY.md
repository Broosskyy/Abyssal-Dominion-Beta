# M127 — Shared RBAC for Web Admin + Ingame Admin

All administrative capability is permission-based. A role is only a bundle of granular permissions; staff may have multiple roles.

Examples:
- Content Editor may create/edit drafts but cannot publish.
- Content Manager can validate/publish/rollback normal content.
- Game Designer edits gameplay/balance but does not automatically receive payment or staff rights.
- LiveOps Manager controls event scheduling/publishing.
- Support and Moderator roles are separated from content/economy.
- Monetization Manager can edit product configuration but does not receive entitlement grants or payment configuration automatically.
- Release/Technical Admin have separate operational rights.
- Super Admin exists but should be rare.

Both Web Admin and Ingame Admin consume the same server-verified staff identity and effective permission snapshot. UI hiding is not security; every write must be checked server-side.

Critical changes use additional approval policy. Economy/payment/entitlements/staff-role/permission/server-management operations are configured for two-person approval in the contract.

The existing M94 local developer AdminMode remains a testing tool only and never grants production RBAC permissions.
