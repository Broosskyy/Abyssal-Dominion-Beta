# M149 — P1 Regional Runtime Integration

M149 connects the M148 swap assets to the actual W2/P1 runtime path for Crimson Sea (PL6–10) and Drowned Reach (PL11–15).

## Runtime connections

- Regional NPC and Admiral slots now resolve through the dedicated M148 GLBs.
- The Admiral resolver accepts the canonical V3.7 `admiral_slot` field.
- Crimson and Drowned monster pools now feed weighted encounter selection without turning bosses into permanent residents.
- Crimson coral/coastal-flower and Drowned coral/mangrove/reed kits feed island dressing.
- Region-specific coast modules become the island visual layer while canonical island identity remains metadata.
- Redhaven and Mourning Port use their dedicated harbor shells and regional presentation accents.
- Canonical region IDs now drive regional combat-role presentation instead of relying only on old aliases.

## Platform presentation

Desktop/macOS use LOD0 for heroes and LOD1 for ordinary ships. Android/iOS and Web preview use LOD1 heroes and LOD2 ordinary ships. Web disables regional shadow casting and uses the lowest VFX density; it remains preview-only.

All presentation layers are visual-only. Collision, damage, AI, rewards, quest credit, progression, spawn qualification and economy remain outside GLBs and under gameplay/server authority. GLOBAL remains locked.
