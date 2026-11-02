# M135 — Weighted Monsters + Playable POIs + Trusted Time Boundary + Free-form Map Presentation

## Weighted monsters
Ordinary Spawn Tables can now select both NPC and Monster entries. A weighted Monster receives monster/hunter semantics,
its stable content ID/tags, dynamic definition and normal quest activity. Monster content is no longer limited to hard-coded
capstone hunter substitutions.

## POI gameplay
Generated POIs are no longer visual-only. The normal Interact action finds the nearest POI inside the interaction radius,
fires precise `poi` quest activity using content ID/tags, writes a local intent and shows HUD feedback.
Non-repeatable POIs are consumed until the sector is rebuilt.

## Trusted time
`TrustedTimeService` separates device time from verified server time.
Local development may use device time as an explicit fallback.
Non-local environments do not activate schedules requiring trusted time until a server-verified timestamp has been synchronized.
No fake time authority is claimed.

## World-map presentation
World sectors now have `map_position`, separate from legacy runtime coordinates.
The Global Sea Map uses these free-form presentation positions, so the visual map no longer depends on a rectangular grid layout.
Legacy coordinates are still required by the current physical sector-instancing implementation; removing that final dependency is future work.
