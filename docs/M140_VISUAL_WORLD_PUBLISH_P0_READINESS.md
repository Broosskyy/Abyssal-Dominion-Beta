# M140 — Visual Diversity + World Publish Integrity + P0 Production Readiness

## Runtime visual improvement
The twenty island production silhouettes now influence actual procedural placeholder visuals. Secondary visual masses create readable coves, splits, twins and delta-like forms without moving gameplay collision out of the stable wrapper.

NPC fallback visuals now receive one of ten regional pirate-material families aligned to the V3.7 world bands. Hull, sails and trim change by region while preserving original pirate/wood/sail identity.

## Publish integrity
ContentPublishValidator no longer contains the dead event-reference placeholder loop. It uses explicit reference types and validates sector map positions, level range, dangling references and reciprocal graph edges before a content snapshot is accepted locally.

This is client-side validation architecture only. Production publishing must repeat validation on the authoritative backend.

## Save/reconnect
World save data now stores stable sector ID, safe sector-local position and content version. Old world coordinates remain migratable. Local positions are clamped inside sector bounds on restore. A content-version mismatch is recorded as diagnostic metadata rather than silently assuming the world is unchanged.

## P0 production
A dedicated 22-slot P0 readiness manifest covers:
- 3 starter ships
- 5 PL1-5 NPC ships
- first monster
- Haven's Reach
- 4 early island placeholders
- 8 core HUD icon families

All remain visual-only replacements with stable wrapper-owned gameplay/collision/sockets.
