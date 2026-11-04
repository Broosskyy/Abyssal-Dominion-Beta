# M75 — PL1–5 Visual Closure + Mobile Performance / Integrity Pass

M75 intentionally slows feature breadth and audits the M70–M74 presentation stack.

- Fixed a fragile dynamic Dictionary access in beginner quest presentation.
- Added a dedicated objective-strip rectangle to NauticalLayout. It is now part of HUD reservation and world-input blocking rather than being positioned ad hoc.
- Added viewport/DPI-aware budgets for world POIs, minimap POIs and transient feedback.
- Decorative island dressing now receives GeometryInstance3D visibility ranges for low-cost distance culling. This is visual-only.
- MultiMesh remains a prepared optimization, not blindly enabled: repeated geometry should be profiled first because batching trades draw-call reduction against coarser spatial culling.
- Improved the first-monster procedural fallback with stronger fins, crest/head read and emissive eyes.
- Added six more stable visual replacement slots and a concrete P0 final-art priority list.
- Added representative mobile layout QA viewports and a source-integrity audit.

Godot documentation confirms visibility ranges can be used on GeometryInstance3D-derived nodes and can coexist with mesh LOD. MultiMesh can reduce draw-call/API overhead for many repeated instances, but its instances share coarse spatial indexing, so native profiling remains necessary.

This milestone is source/static validated only. It is not a native Godot 4.7.2, Android-device or GPU-profiler acceptance pass.
