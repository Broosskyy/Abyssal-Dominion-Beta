# M85 — HUD Customization Safety + Cross-platform Affordances + Pirate Visual Polish

M85 hardens the M83–M84 customizable HUD and continues visible PL1–5 polish.

- HUD layout schema 3 adds per-group lock/unlock. Locked groups cannot be dragged, scaled or hidden until unlocked.
- Added Reset Profile and Reset All Local Layouts.
- Existing schema-1/2 local layouts migrate forward without discarding positions.
- Compact touch layouts now include runtime safety: if custom movement/camera and combat groups overlap, safe defaults are restored for the conflicting critical group. Critical touch actions retain the 56+ logical-unit floor.
- Hidden optional panels now receive explicit draw guards, avoiding invalid/zero-area panel rendering.
- Desktop gets replaceable keyboard/gamepad action affordance icons; touch HUDs do not show desktop hints.
- The PL3 first-monster teaching metadata is now rendered as a mobile-safe single card, with no auto-target, auto-weapon or balance changes.
- P0 procedural NPC fallbacks get stronger pirate identity through visual-only pennants/stern lantern accents; user replacement GLBs remain untouched.
- Repeated P0 NPC primitive fallback meshes now reuse `FallbackPrimitiveLibrary` where safe.
- Added eight more stable secondary model slots while preserving the master P0 first-13 final-asset priority.

Crossplay remains an architecture boundary only: presentation/input hints vary per device, while gameplay intents and future server authority remain platform-neutral.

Native Godot 4.7.2 parser/runtime, Android/iOS touch QA, desktop mouse/gamepad QA and device screenshots remain required.
