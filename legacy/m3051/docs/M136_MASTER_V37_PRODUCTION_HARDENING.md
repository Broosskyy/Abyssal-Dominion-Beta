# M136 — Master V3.7 + Production Hardening

This pass deliberately combines runtime cleanup, production readiness, optimization and placeholder work.

- World transitions/builds now use stable Sector IDs and registry runtime data as the primary source. Legacy Vector2i coordinates remain only as compatibility mirrors for older save/runtime consumers.
- Dynamic admin-authored POIs are inserted into actual sector composition with stable IDs, tags, interaction radius, marker slot and replaceable AssetSlot.
- A production placeholder registry covers P0/P1/P2 families, required sockets/anchors and mobile/Desktop quality intent.
- AssetVisualLibrary annotates installed visuals with replacement readiness, production priority, LOD profile and VFX quality profile.
- Canonical V3.7 harbors Sovereign's Rest and Dominion Gate replace provisional display ports while old names remain migration aliases.
- Final asset replacement remains visual-only: collision/gameplay/sockets stay in wrappers.
- Effects/status/rarity/event colors should reuse meshes and be composed through materials/shaders/VFX instead of requiring duplicate GLBs.

Still pending: true LOD mesh switching, native import QA, final P0 GLBs, and removal of the large legacy SECTORS constant after migration coverage.
