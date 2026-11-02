# M80 — Native-Readiness Audit + Fallback Consolidation + Wreck Visual Pass

M80 deliberately consolidates the PL1–5 presentation stack before adding broader systems.

- Added `FallbackPrimitiveLibrary`, a shared primitive-mesh cache for visual-only procedural fallbacks. Identical Box/Sphere/Cylinder/Torus resources are reused while each world node remains independently transformable and replaceable.
- Harbor, island dressing, salvage, monster-area and POI fallbacks now use the shared mesh cache where safe, while continuing to reuse `EnvironmentMaterialCatalog`.
- Haven's Reach now wires the prepared signpost and canvas-awning slots into its composition.
- Added `WreckLandmarkComposer`: wreck/wreck-beacon POIs receive cannon, torn-sail, anchor-chain and drift-cargo silhouette dressing. It never grants loot or quest credit.
- Added a source-level native-readiness audit covering project class references and explicit `res://` paths.
- MultiMesh remains deferred. The current PL1–5 repeated fallback counts are small, and stable per-slot replacement plus spatial culling are still more valuable until native profiling says otherwise.
- Added six more P0 replacement slots.

Static/source validation is clean, but this is still not a Godot 4.7.2 parser/runtime acceptance, Android-device playthrough, or GPU profiler pass.
