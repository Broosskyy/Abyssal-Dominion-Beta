# M143 — Unified Admin & Content Authority Foundation

## Outcome

M143 establishes one canonical administrative model for the future web dashboard and the ingame staff surface. Both clients must consume the same schemas, permissions, workflow and server decisions. The milestone deliberately avoids a fake production server: local tools can create, edit, validate and preview drafts, while publish, schedule, rollback, payment, entitlement, staff and server mutations remain server-only.

## Preserved systems

No M142 gameplay feature was intentionally removed. The three earned starter ships, later main design progression, ships/NPCs/monsters, cannons, ammunition and cannonballs, harpoons, support weapons, quests, encounters, events, guild systems, settings, touch steering, responsive HUD, camera, ocean presentation, LOD profiles and replaceable asset slots remain in scope.

## Added admin coverage

The module registry now represents overview, game content, world, balance, economy, LiveOps, assets, players, guilds, support, website/CMS, monetization/payment, moderation, staff, server operations, analytics, audit and system settings. Module visibility is only a convenience; every write must still be authorized by the server.

The canonical content registry now has 27 types. Cannon, badge and branding assets are explicit records rather than hidden hard-coded exceptions. Branding records use stable asset slots so logos and their light, dark, mobile and localized variants can be replaced without changing calling code.

## Production workflow

Drafts are versioned and validated against schema, references, world graph and asset readiness. Ordinary content can require one approval. Economy, monetization, payment, entitlement, staff rights and server operations require two distinct staff approvals; the requester cannot self-approve a critical change. Activation produces a signed versioned snapshot and an audit event. Rollback creates another version instead of editing history.

## Asset production

The existing stable AssetSlot system remains the replacement boundary for the 707-entry production plan. Runtime VFX stay separate from GLB geometry. Final GLB, icon, UI, audio and VFX files can replace placeholders without changing gameplay IDs.

## Known boundary for M144+

M143 provides the Godot-side contract, module browser, local draft tooling and verified-snapshot consumer boundary. The uploaded Web V38 code still requires a migration that unifies its conflicting role tables, imports the current M143 content schema and implements real integration tests against PostgreSQL. That work must precede any production claim.
