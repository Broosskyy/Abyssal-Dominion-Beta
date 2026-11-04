# M84 — HUD Editor Polish + Cross-platform UI Optimization

M84 expands the M83 player-customizable HUD while preserving mobile/desktop responsiveness and the crossplay boundary.

- HUD groups now support normalized position, per-group scale (80–135%) and visibility for noncritical information groups.
- Critical movement/combat/status groups cannot be hidden.
- Added Standard, Combat and Minimal presets per HUD profile.
- Added snap guides around quarter/center screen lines for touch/mouse dragging.
- Added overlap detection/warnings instead of silently allowing unreadable layouts.
- Fixed the M83 editor toolbar interaction so Reset/Done/preset/scale controls are handled by the fullscreen GUI control itself rather than relying on unhandled input.
- Existing M83 schema-1 layouts migrate locally to schema 2 with scale=1 and visible=true.
- Mobile portrait/landscape and desktop profiles remain separate; positions stay normalized to safe area.
- Added replaceable editor + desktop/gamepad affordance icon slots.
- Added PL3 first-monster teaching metadata with one-at-a-time mobile guidance; no forced targeting/weapon selection/balance changes.
- Added eight more stable world/model placeholder slots while preserving the master first-13 final-asset priority.

No networking, accounts, cloud layout sync or server authority is claimed. Native Godot 4.7.2 parser/runtime and device interaction QA remain required.
