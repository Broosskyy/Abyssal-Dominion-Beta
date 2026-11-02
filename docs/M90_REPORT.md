# M90 — Guild Island World UX + Tower/Facility Presentation + Parallel World Polish

M90 turns the map-level-2 guild-island foundation into visible world UX without pretending the multiplayer backend exists.

- Guild Islands now participate in world-marker and POI drawing, minimap drawing, and global-map level cues.
- Proximity HUD exposes Dock / Guild / Defense / Facilities as large touch-safe interaction rows.
- Desktop can use the same interaction system with mouse/F; touch taps are consumed before sailing so interaction does not leak into Tap-to-Sail.
- Defense detail shows tower role, range, reload and DamageDefinition-style preview fields. Live tower damage/reload timing/ownership remain disabled and future-server-authoritative.
- Facility detail shows Hall/Warehouse/Repair/Dock with explicit server-required state for membership/vault/upgrade-dependent functionality.
- Relation presentation supports neutral-preview now and owned/ally/enemy/war contracts for the future server, without fabricating ownership.
- Critical M88/M89 source debt was fixed: nonexistent `AssetVisualLibrary.instantiate_model` calls were replaced with the established `AssetVisualLibrary.install` path.
- Non-guild world polish continues in parallel: sea-stack, beach-notch and low-reef stable island slots are wired under one-detail caps.
- Additional guild gate, shield core, objective, market/event/tower slots are prepared for direct GLB replacement.

No backend/server authority is claimed. Native Godot 4.7.2 parser/runtime, Android/iOS touch QA, gamepad QA and performance profiling remain pending.
