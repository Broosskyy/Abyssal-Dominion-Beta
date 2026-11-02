# M286 Production Report

## Scope
Single-model Ship Damage Overlays / Deck, Mast & Sail Cues / Hull Breaches / Flooding / Staged Sinking / Wreck Presentation.

## Implemented
- `M286ShipDamageEscalationRuntime` as a fail-closed replica/presentation layer over server-confirmed M285 ship damage and defeat state.
- Revision-, tick-, sequence-, event-ID- and presentation-seed guards for escalation snapshots and transition events.
- Seven presentation segments: bow, port hull, starboard hull, deck, mast, sails and stern.
- Four segment states: INTACT, DAMAGED, BREACHED and DESTROYED.
- Confirmed staged defeat phases: NONE, STAGGER, FLOODING, BREAKUP, SUBMERGED and CLEANUP_PENDING.
- Data-driven sinking presentation candidates for light, heavy, player, admiral and abyssal ship families.
- `M286ShipDamageOverlayRig` attached to every procedurally generated complete ship model.
- Nine stable VFX/model sockets and eight replaceable asset slots.
- Runtime-composed deck, mast, sail, hull, flooding, bubble and wreck-silhouette overlay proxies that never replace source-model parts.
- Mobile/Web reduction of secondary hull segments and bubble count while gameplay truth remains identical.
- GameHud/NauticalHud read-only segment/escalation strip and Command Deck readiness section without a new main-menu page.
- Four new Admin/No-Code presentation definitions for segments, destruction kits, sinking profiles and wreck visuals.

## Authority
M269/M270 own combat truth. M285 owns confirmed ship damage/defeat presentation input. M267 owns world entities and cleanup; M274–M278 own kill credit, loot and rewards. M286 cannot derive damage from visuals, break equipment, change movement or canonical ship transforms, choose or advance a defeat sequence, spawn a wreck world entity, despawn a ship, create loot or grant rewards.

## Visual and asset lock
The high/wide angled sea-chart camera, Tap-to-Sail, lower-left camera control, lower-right attack cluster, round gameplay minimap and rectangular full map remain unchanged. Each initial-production ship remains one complete GLB containing hull, bow, stern, deck, masts, sails and design parts. Damage proxies live outside that model on stable VFX anchors; they never require modular meshes or detach/replace ship parts. `assets/production` and `assets/reference_only` remain strictly separated.

## Clean-room reference
Seafight and Battle of Sea remain genre, naval readability and game-feel references only. No proprietary model, texture, effect, sound, UI layout, formula or timing is copied.

## Intentionally open
Final authored damage/wreck kits, transition durations, mast/sail motion, flooding and bubble density, sinking/roll/breakup curves, wreck visibility, debris, smoke, audio mix, screen shake, haptics and simultaneous-destruction budgets remain open until native gameplay QA.

## Validation
- 449/449 static regression and integration tests passed (432 function tests + 17 unittest tests).
- 550/550 JSON files parsed successfully.
- Release identity aligned to M286 / 0.286.0 / build 286.
- ZIP integrity is verified during the final packaging pass.
- Native Godot render/audio/device QA remains NOT_EVALUATED because this execution environment contains no Godot binary or export templates.
