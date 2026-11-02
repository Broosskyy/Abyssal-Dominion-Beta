# M150 — P1 Regional Visual Acceptance

M150 converts the M149 Crimson Sea and Drowned Reach runtime batch into a replaceable visual-acceptance layer while preserving the V3.7 gameplay, admin and platform contracts.

## Delivered

- Two region environment profiles covering background, ambient light, sun, fog and water.
- Eight external `StandardMaterial3D` placeholders: ship, monster, world and harbor for each region.
- Runtime environment controller connected to world-sector transitions.
- Placeholder-only regional material adapter. User replacement GLBs retain their authored materials.
- Regional water shader parameter switching without changing gameplay or collision.
- Dedicated oblique mobile sea-map QA scene comparing NPC, Admiral, monster, island and harbor.
- Binding ship-direction guard: three starters (PL1/2/3), 100 regular ship classes, five Prestige classes and mastery levels 1–10 per playable design.

## Asset replacement contract

Geometry belongs in the GLB. Water, reef, foam, movement, light, smoke, wake, trails, impacts and magic stay in Godot. Replacing a registered placeholder GLB must not require gameplay-code changes. A reserved class is not counted as a completed silhouette until its scheduled production wave supplies a genuinely distinct model.

## Preserved

Admin/GM, RBAC/MFA/audit/approval, cannons, ammunition/cannonballs, ships, logos, badges, settings, mobile controls, login/home flow, cross-platform presets and server-authority boundaries remain in place. GLOBAL stays locked.
