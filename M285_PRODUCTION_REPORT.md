# M285 Production Report

## Scope
Ship Hit Reactions / Hull & Shield Impact Readability / Persistent Damage States / Critical State / Sinking & Defeat Presentation / Replaceable Placeholder VFX Rig.

## Implemented
- `M285ShipDamageDefeatPresentationRuntime` as fail-closed replica/presentation layer over M269/M270 and confirmed M282–M284 context.
- Revision-, tick-, sequence- and event-ID-guarded ship-state snapshots and reaction events with deterministic presentation seeds.
- Distinct shield, hull and armor hit hooks plus persistent INTACT/LIGHT/MODERATE/HEAVY/CRITICAL/DEFEATED states.
- Segment-aware hull/shield payloads with persistent hull damage, broken-shield, fire, smoke and critical hooks.
- Server-confirmed, replay-safe defeat/sinking lifecycle for player ships, NPC ships and admiral/boss vessels.
- `CLEANUP_CONFIRMED` boundary that clears stale M285 HUD/replica state before requesting visual cleanup.
- `M285ShipDamageVisualRig` attached to every generated ship as an explicitly labelled presentation-only placeholder layer.
- New `VFX_Damage_01`, `VFX_Damage_02`, `VFX_Shield` and `VFX_Sink` sockets without changing the underlying ship mesh.
- Mobile/Web-safe placeholder shield shell, charred hull marks, fire, smoke, critical ring and modular sinking debris.
- Stable replacement slot manifest so final authored effects can replace every placeholder without rewriting combat or ship code.
- Local-development fallback may visualize local `ShipHealth`; the online path accepts only server-confirmed M285 states/events.
- GameHud/NauticalHud and Command Deck integration without a new main-menu page.
- Admin/No-Code definitions and master-convergence evidence.

## Authority
M269/M270 own damage, state and defeat truth. M267 owns world entities; M274–M278 own kill credit, loot and rewards. M285 renders only confirmed events/states online and never treats hit reactions, fire, smoke, critical visuals or sinking animation as combat confirmation. Local `ShipHealth` visualization is isolated to `LOCAL_DEVELOPMENT` with `server_authority_verified=false`.

## Visual and asset lock
MID zoom and angled top-down sea-chart gameplay remain the master. Persistent damage stays readable at gameplay scale while hit motion remains brief and restrained. Tap-to-Sail, the lower-left camera control, lower-right combat cluster, round minimap and rectangular full map remain unchanged. Ship GLBs do not bake wake, foam, smoke, fire, glow, rings, trails or hit flashes. `assets/production` and `assets/reference_only` remain separated.

## Clean-room reference
Seafight and Battle of Sea inform only the desired immediacy, distinction and satisfaction of naval hits. No proprietary sound, VFX, model, UI, formula or timing is copied.

## Remaining
Final authored hull/shield/fire/smoke/sinking assets, native Godot visual/audio/haptic QA, measured motion/VFX/LOD budgets, final sinking curves and multiplayer latency/jitter/reconnect/load validation.

## Validation
- 445/445 static regression and integration tests passed (428 function tests + 17 unittest tests).
- 547/547 JSON files parsed successfully.
- Release identity aligned to M285 / 0.285.0 / build 285.
- Native Godot render/audio/device validation remains explicitly not evaluated because this execution environment contains no Godot binary or export templates.
