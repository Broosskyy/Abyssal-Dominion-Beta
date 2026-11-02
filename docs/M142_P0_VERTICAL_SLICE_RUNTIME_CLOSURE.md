# M142 — P0 Vertical Slice Runtime Closure

M142 deepens the PL1–5 production slice rather than adding another broad system.

- Repairs explicit WorldMapSystem runtime state declarations and keeps stable sector ID authoritative.
- Replaces String.hash()-based world seed with deterministic StableContentSeed derived from sector ID + content version.
- Built-in and admin-authored POIs receive globally stable sector-scoped instance IDs.
- POI interaction uses each POI's own radius, supports authored local positions, and persists consumed non-repeatable POIs in the local prototype save.
- A contextual mobile/desktop POI prompt is rendered above the lower HUD without changing Tap-to-Sail.
- P0 production runtime data explicitly records the 3 starter fleet, five early NPC silhouette slots, first Kraken, Haven's Reach modules and replacement rules.

Truth boundary: POI persistence is local prototype state, not server authority. Final GLBs/icons remain replaceable placeholders. Native Godot/Android/Web/Desktop QA remains pending.
