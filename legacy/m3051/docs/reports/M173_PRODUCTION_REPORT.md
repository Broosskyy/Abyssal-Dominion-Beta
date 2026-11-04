# M173 Production Report

## Status
`M173_MENU_SELECTION_REQUIREMENT_GUILD_DETAIL_PASS`

Master concept: **V3.8**. Existing seekarte/gameplay camera and world presentation remain unchanged.

## Implemented
- Progression hub now visibly marks the active tab and keeps compact mobile tab behavior.
- Special-deck, talent, citadel and cannon-mastery actions expose runtime requirement state before mutation instead of failing generically.
- Mutation paths reuse the same status helpers, reducing UI/runtime rule drift.
- Talent spending now respects actual point_cost before mutation and cannot drive unspent points negative when a future node costs more than one point.
- Cannon mastery requirement feedback exposes missing gold or cannon oil explicitly.
- Progression labels read definition max levels/ranks instead of duplicating `/10` where avoidable.
- Guild-island detail panels now keep the focused tower/facility inside the four-row visible mobile window; tap hit testing maps visible rows back to absolute list indices.
- Added M173 no-code contracts and admin content types for progression panels, requirement feedback, guild detail navigation and selection presentation.
- Treasury, guild construction/war/ownership, payment, entitlement and production publishing authority remain server-side.

## QA
Run `python tests/m173_menu_progression_interaction_test.py`. JSON and ZIP integrity are validated during packaging. Full Godot/Android playtesting still requires an engine/device environment.
