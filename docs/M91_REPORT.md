# M91 — Guild Island Selection, Range Presentation & Visual-State Contracts

M91 deepens the map-level-2 Guild Island experience while keeping all future multiplayer authority explicit.

- Relation presentation now has distinct neutral-preview / own / ally / enemy / war colors. Only neutral-preview is local truth today.
- Selecting Defense exposes a focused tower row and a presentation-only world range ring for that tower. Range rings do not acquire targets or deal damage.
- Facilities expose visual tier and damage-state contracts. Current local state is Tier 1 / intact; future server data must own actual upgrade and siege damage state.
- Compact-phone proximity layout is height-aware and attempts to move above reserved HUD rectangles.
- Touch hit testing remains ahead of Tap-to-Sail; desktop/gamepad can cycle detail focus through existing previous/next actions.
- A shared material cache reduces repeated relation-banner material allocation.
- Stable GLB slots are prepared for tier-2/damaged tower and facility visuals without changing gameplay code.
- The Master P0 first-13 asset order remains higher priority than these parallel guild visuals.

No ownership, alliance, war, treasury, vault, upgrade, tower damage, siege score or persistence is fabricated. Native Godot 4.7.2/device QA is still required.
