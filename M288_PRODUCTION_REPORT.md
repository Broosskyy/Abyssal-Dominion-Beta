# M288 Production Report

## Scope
Naval Contact Readability / Target Focus / Relationship Identity / Threat & Range State / Priority Contacts / Offscreen Guidance / Replaceable Placeholder Rig.

## Implemented
- `M288NavalContactReadabilityRuntime` as a fail-closed presentation replica over M271 targeting, relationship and protection truth.
- Revision-, tick-, sequence-, event-ID- and presentation-seed guards for contact snapshots and events.
- Nine contact classes: player, fleet ally, friendly, neutral, hostile, elite, admiral, monster and boss.
- Eight engagement states and eight confirmed presentation-event kinds.
- Selected-target-first priority sorting with explicit elite/admiral/monster/boss and immediate-threat budgets.
- `M288NavalContactVisualRig` attached around every generated complete ship model.
- Runtime-composed focus ring, relation ring, threat chevrons, range bracket and priority beacon placeholders.
- Safe-edge offscreen marker contract for selected and immediate-threat contacts without filling the sea-chart center.
- Mobile/Web reduction of secondary contact layers while preserving the selected target and identical gameplay truth.
- GameHud/NauticalHud read-only contact strip and Command Deck readiness section without a new main-menu page.
- Four Admin/No-Code presentation definitions plus replaceable slot/profile manifests.

## Authority
M269/M270 own combat truth, M271 owns target selection, relationship, protection and attack legality, M272 owns AI aggro/threat, and M267 owns world entities. M288 cannot select or clear a target, authorize an attack, calculate authoritative range, set relationship/aggro, remove protection, invent a contact or change world state.

## Single-model ship lock
Every initial-production ship remains one complete individual GLB containing hull, bow, stern, deck, masts, sails and characteristic design parts. M288 indicators live on external presentation sockets; no modular hull, mast, sail or detachable part is required, hidden or replaced. A true modular ship system remains deferred.

## HUD and clean-room lock
The sea-chart center, lower-left camera-only control, lower-right primary attack cluster, bottom-center weapon/ammo controls, round gameplay minimap and rectangular full sea chart remain unchanged. Seafight and Battle of Sea inform only immediate contact distinction and genre usability; no proprietary icon, layout, art, effect, sound, formula or timing is copied.

## Intentionally open
Final authored markers, ring widths/opacities, pulse rate, beacon scale, edge padding/count, transition timing, audio/haptics and simultaneous-contact budgets remain open until native gameplay QA.

## Validation
- 457/457 static regression and integration tests passed (440 function tests + 17 unittest tests).
- 556/556 JSON files parsed successfully.
- Release identity aligned to M288 / 0.288.0 / build 288.
- ZIP integrity is verified during the final packaging pass.
- Native Godot render/audio/device QA remains NOT_EVALUATED when no Godot binary or export templates are available.
