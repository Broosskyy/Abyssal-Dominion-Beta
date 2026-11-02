# M139 — Dynamic World Graph + Save Migration + Runtime Placeholder Diversity

This pass closes several consequences of removing the old hard-coded world table.

- Dynamic `sector` content can add new stable-ID sectors or overlay supported fields on existing sectors. This allows a published content snapshot to connect new maps to the existing graph without a client code deployment.
- Encounter persistence now uses stable Sector IDs. Legacy `x,y` encounter-state keys are migrated on load.
- World saves use schema 2 and stable Sector IDs. Exact old coordinates are still accepted as a migration source. Unknown/corrupt locations fall back safely to SECTOR-001 instead of crashing.
- WorldDressingComposer now consumes the actual platform decorator budget.
- The 50 progression ship silhouette descriptors now alter procedural fallback geometry at runtime. Player main designs and regional NPC fallbacks therefore do not all share the same apparent hull proportions while final GLBs are missing.
- Twenty island-base production silhouettes are defined as distinct small/medium/large/long forms, including coves, spits, cliffs, rings, deltas and ridges.
- Final GLBs remain visual replacements only; gameplay wrappers, sockets and collision remain stable.

Static validation does not replace Godot 4.7.2 parser/runtime/device testing.
