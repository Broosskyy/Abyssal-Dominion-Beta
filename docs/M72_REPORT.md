# M72 — Early Quest / POI Content + World Interaction Polish

M72 adds visible early-game content without turning decorative models into gameplay authority.

- Six PL1–5 visual POI families: salvage, wreck, shrine/signal, monster nest, navigation marker and supply cache.
- Two additional nature slots: reef cluster and driftwood cluster.
- Semantic GLB fallbacks reuse existing chest/wreck/buoy/repair assets where appropriate; other POIs use low-cost procedural fallbacks.
- PL1–5 sectors now receive deterministic visual POI dressing with distance-faded mobile markers.
- M71 island composition profiles are now wired into actual tropical PL1–5 island creation, adding small/medium/long/thin/rocky/cove variety.
- Mission HUD now uses replaceable icon slots for sink, loot and dock mission categories.
- Added an instancing/batching contract for repeated palm/rock/reef/driftwood/buoy dressing. Interactive gameplay objects are explicitly excluded from decorative batching.
- Added a concrete next-asset production wave so final GLBs can be created in parallel and dropped into stable slots.

No POI model grants rewards, completes quests or changes combat. Native Godot 4.7.2/device QA remains pending.
