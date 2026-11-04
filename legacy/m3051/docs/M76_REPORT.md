# M76 — First-Session Gameplay Closure + Early Content Expansion

M76 closes presentation gaps in the actual first-session path without replacing existing progression mechanics.

- The active beginner objective now drives one contextual guide cue at a time.
- Loot and harbor return can show a single safe-area-clamped positional cue. Combat remains textual and never auto-selects/auto-attacks.
- Haven's Reach is marked as the PL1 home harbor for presentation priority; PortInteraction remains docking authority.
- Salvage pickups receive lightweight floating-debris dressing using stable replacement slots.
- Added a PL1–5 encounter-variety presentation contract without changing HP/damage/speed/AI tuning.
- Added six model slots and six polished text-free guidance/encounter UI assets.
- Fixed the M75 objective strip carry-forward so it actually uses NauticalLayout.objective_strip.
- Added an explicit beginner-ship reward reconciliation audit instead of silently changing the current stage-1/stage-5 executable rules. The newer master direction indicating medium PL2 / large PL3 needs a dedicated save/test migration pass.
- Added a first-session QA matrix: spawn -> sail -> target -> fight -> salvage -> return -> dock -> claim.

No online/backend authority, auto-navigation, balance changes or fabricated quest completion were introduced. Native Godot 4.7.2/device QA remains required.
