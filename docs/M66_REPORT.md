# M66 — P0 NPC Visual Differentiation + Starter Fleet Polish

M66 improves the interim visual quality/readability of the complete P0 ship set without changing gameplay.

Small, Medium and Large starters now have separate presentation profiles. Friendly Coastal Sloop, Scout I, Raider I, Gunship I and Heavy I also have distinct scale/silhouette intentions, palette IDs, LOD bias and shadow-distance guidance.

The current Friendly/Scout/Raider/Gunship placeholders still share the older Corsair geometry. M66 deliberately does not pretend otherwise: their presentation is differentiated for the interim build, while dedicated final GLBs remain the production target.

`ShipVisualProfileCatalog` applies fallback-only scale differentiation and mesh LOD bias. User replacement GLBs are never distorted by these fallback scale profiles.

A low/balanced/high ship LOD contract defines viewport mesh-LOD thresholds plus visual distance budgets for shadows, minor VFX and nameplates. Gameplay/collision is independent from visual LOD.

The approach follows Godot's mesh-LOD and visibility-range model: automatic imported Mesh LOD for geometry, visibility ranges for labels/VFX/manual HLOD, and simpler distant presentation on mobile.

No native Godot 4.7.2 parser/runtime/device profiler QA was available in this environment.
