# M92 — General Sea-Map Quality + Mobile Performance + Guild Island Continuation

M92 deliberately broadens the work again instead of turning the project into a guild-only sprint.

- Haven's Reach now applies its landmark/secondary/dressing hierarchy at runtime. On smaller/mobile layouts and lower graphics quality, low-priority dressing is suppressed first while lighthouse/dock/warehouse identity survives. Visual suppression never changes service availability.
- P0 NPC fallback sails and pirate pennants reuse cached QuadMesh resources, and Scout/Raider/Gunship/Heavy receive stronger role-specific pirate silhouettes.
- Wrecks keep the existing three-object context cap but now read more clearly through stern-gallery, spar-cluster and torn-flag identity.
- The PL3 monster-warning area keeps a two-object cap and now uses hunter buoy + hunter banner. Both remain teaching/landmark presentation with no target or reward authority.
- Selecting the harpoon on PL3 records only a session presentation flag so the first-monster teaching can stop nagging without changing progression.
- Guild tower/facility focus now uses visible world rings. Tower range rings remain visible only for the selected tower and remain presentation-only.
- The guild proximity panel now chooses the lower-overlap top/bottom candidate against reserved HUD rectangles on compact screens.
- Guild marker priority is taken from metadata without raising the global marker budget.
- Ten additional stable model slots were prepared across harbor, islands, wrecks, monster areas and guild facilities.

No backend/server authority is fabricated. Native Godot 4.7.2 parser/runtime, Android/iOS, gamepad and GPU profiling remain pending.
