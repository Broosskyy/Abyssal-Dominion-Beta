# START HERE — Abyssal Dominion M301

Continue from M301 / V3.8. All five active early NPCs have separate complete ship GLBs in stable asset slots, not modular assemblies (Raider M295; coastal/gunship M296; Scout/Heavy M297). M298 animates only the complete placeholder model locally using M287/M285/M286 presentation inputs. M299 adds isolated responsive visual-QA scene with scene-tagged local preview. M300 closes guild-island enemy tower *preview* and Halloween world-decoration lifecycle. M301 adds a SQLite server-side domain for towers/Halloween, separate replaceable pumpkin previews and pending event reward intents. No connected gateway or deployed event exists; do not treat source checks as online gameplay or native QA PASS. Preserve all prior camera/world/navigation/combat/HUD/mobile-desktop parity, clean-room genre-reference and server-authority locks.

## M285
Use `M285ShipDamageDefeatPresentationRuntime` only as a replicated presentation layer over M269/M270 truth and confirmed M282–M284 context. `M285ShipDamageVisualRig` is a replaceable placeholder/final-asset bridge; local ShipHealth fallback is LOCAL_DEVELOPMENT-only. Reactions, damage visuals, critical state and sinking never apply damage, confirm defeat, despawn, grant kill credit or create loot/rewards.

Dependency chain: M269 outcome → M270 combat/projectile truth → M281 HUD → M282 confirmed feedback → M283 projectile/salvo presentation → M284 family/material/audio identity → M285 ship damage/defeat presentation. M267 owns world replication, M268 movement, and M274–M278 reward truth.

Open native-QA tuning: hit-stop/flash/tilt, fire/smoke density, critical pulse, sinking timing/curve, debris, shake, haptics and simultaneous damaged-ship LOD budgets.

## M286
`M286ShipDamageEscalationRuntime` is a replica-only extension over confirmed M285 defeat state. It renders seven presentation segments and a staged NONE → STAGGER → FLOODING → BREAKUP → SUBMERGED → CLEANUP_PENDING sequence. The legacy-named source file now exposes `M286ShipDamageOverlayRig`: deck, mast, sail, bow/stern, flooding, bubble and wreck cues are external overlays around one complete ship model. They never hide, detach or replace parts of the canonical ship GLB.

Dependency chain: M269/M270 combat truth → M282 confirmed feedback → M285 damage/defeat confirmation → M286 damage-overlay presentation. M267 alone owns replicated world entities; M274–M278 own kill credit, loot and rewards.

Open native-QA tuning: transition durations, mast/sail motion, flooding/bubble density, sinking/roll/breakup curves, wreck visibility, debris, smoke, audio mix, shake, haptics and simultaneous-destruction LOD budgets.

## M287
`M287ShipMotionIdentityRuntime` consumes only server-confirmed M268 motion-presentation snapshots/events. `M287ShipMotionVisualRig` adds external bow displacement, stern wake, directional turn-water, hull waterline, anchor/idle ripple and a socketed sail-flow cue. It does not require direct access to a separate sail mesh or bone. The legacy `ShipWake` stays available for compatibility but is hidden when the M287 rig is active.

## Binding single-model lock
During initial production, every ship is one complete individual 3D/GLB model containing hull, bow, stern, deck, masts, sails and characteristic design parts. Most ships are not modular. Separate runtime sockets exist only for cannons/harpoons, muzzle/impact/audio, wake/water, targeting/nameplates and optional damage/motion overlays. True modular ship construction is deferred to a later explicitly approved phase.

Tap-to-Sail remains the only mobile ship movement input. A water tap may route directly behind the ship without forcing a forward arc. The lower-left steering circle remains camera-only. Islands remain hard navigation obstacles; ships, NPCs, monsters, bosses and loot remain non-blocking.

Dependency chain: M267 world replica → M268 authoritative movement/prediction/reconciliation → M287 motion presentation. M287 never commits position, velocity, heading, speed, route or collision and cannot promote wake length or sail motion to gameplay truth.

Open native-QA tuning: wake length/opacity, bow width, turn curl, waterline, anchor ripple, sail response, correction feedback, motion audio/haptics and simultaneous motion-VFX budgets.

## M288
`M288NavalContactReadabilityRuntime` consumes only server-confirmed contact snapshots/events over M271 targeting/relationship/protection and M272 aggro/threat truth. `M288NavalContactVisualRig` provides external target-focus, relation, threat, range and priority placeholders around complete individual ship models. The HUD contract adds safe-edge offscreen guidance for selected and immediate-threat contacts while keeping the sea-chart center clear.

Dependency chain: M267 world replica → M269/M270 combat truth → M271 target/relationship/protection legality → M272 AI aggro/threat truth → M281 combat HUD → M288 contact presentation. M288 cannot select or clear targets, decide range or attack legality, set relationships/aggro, remove protection or create world entities.

Selected targets survive visual-budget reduction. Mobile/Web may reduce only secondary rings, chevrons and low-priority markers. The lower-left camera-only control, lower-right attack cluster, bottom-center ammo/weapon controls, round minimap and rectangular full map remain unobstructed.

Open native-QA tuning: focus/relation/range ring dimensions, threat pulse, priority beacon, safe-edge padding and marker count, transitions, audio/haptics and simultaneous-contact budgets.

## M289
`M289PlayableVerticalSliceRuntime` audits and observes the first complete 12-stage sea-map journey: harbor start, undock, Tap-to-Sail, target, cannon combat, harpoon monster combat, repair/shield, loot, quest completion, defeat, respawn and harbor return. It never drives those systems or turns local observations into server truth.

The fixed intake manifest binds one small sea map, Haven's Reach, three complete starter-ship GLB placeholders, three normal NPC roles, one elite, one admiral, one monster and one loot archetype to stable replacement paths. Placeholder presence is not final-art acceptance.

`m289_playable_vertical_slice_qa.tscn` is the native test adapter. All Godot 4.7.2, desktop, Android, touch, HUD overlap, GPU, memory/VFX, audio, haptic, sinking/respawn and harbor-return gates remain `NOT_EVALUATED` until trusted evidence exists. Static tests cannot mark them PASS and M289 cannot approve a release.

The initial-production model lock remains one complete individual GLB per ship. No modular hull, mast, sail or detachable-part requirement is introduced.

## M290
`M290FirstSortieIntegrationRuntime` passively binds the M289 journey to existing local-development gameplay events: Tap-to-Sail intent, target selection, successful cannon/harpoon presentation, repair intent, loot collection, mission completion, sinking, respawn and docking. It accepts global observations only through trusted M289 server receipts with monotonic revision/tick guards.

`M290FirstSortieVisualRig` provides a single replaceable world-guidance beacon. The existing mission panel shows compact sortie progress. Neither layer auto-navigates, selects targets, fires weapons, confirms hits/damage/defeat, respawns entities or grants loot/progression/rewards.

The M289 deep audit is preserved in `M289_DEEP_AUDIT_FOR_M290.md`. It records that the former 12-stage observer had no production event callers and that M290 closes this integration gap without inventing native QA evidence.

Initial ships remain complete individual GLBs. Hull, bow, stern, deck, masts, sails and characteristic design parts are not runtime construction modules. External weapons, VFX, audio, wake, damage overlays and target/guidance markers remain allowed.

## M291
`M290FirstSortieIntegrationRuntime` now applies the M291 causality contract: a water-tap records only navigation intent, while departure requires explicit Haven's Reach undocking or actually exiting its port proximity after a water tap. Returning requires a later real Haven's Reach docking event. The ordinary ten-stage outing does not require sinking; defeat and respawn remain optional native-QA observations. Rejected M289 local observations do not count as M290/M291 progress.

The HUD and Command Deck report observed progress and optional QA separately, not server-certified kills, actual travel, native PASS or release approval. No new modular ship requirements or authoritative gameplay actions are introduced. See `M291_PRODUCTION_REPORT.md` and `data/m291_sortie_causality_contract.json`.

## M292
Without a tracked quest, the existing mission panel becomes the first-sortie next-step card; with a tracked quest, the quest retains the full panel and a small progress count only appears on sufficiently wide layouts. No second world marker or new center-chart UI is added. The Command Deck distinguishes local observations from server-confirmed receipts, while defeat/respawn remain separate optional QA. Native Godot/mobile/desktop results remain NOT_EVALUATED. See `M292_PRODUCTION_REPORT.md` and `data/m292_sortie_hud_guidance_contract.json`.

## M293
`PortInteraction` sends proximity entry/exit only for the player ship. `M290FirstSortieIntegrationRuntime` observes home start only when the actual Haven's Reach port exists. Its existing replaceable one-beacon rig hides when a player-tracked objective or selected combat target has priority, the menu/full chart is open, or the player is sunk. Enemy guidance ignores invalid, queued and sunk candidates. No ship, target, route, combat, reward or progression authority changed; single complete ship GLBs remain the initial asset rule. See `M293_PRODUCTION_REPORT.md` and `data/m293_world_guidance_priority_contract.json`.

## M294
`M294SailingObservationRuntime` passively follows existing water-tap navigation intents. In LOCAL_DEVELOPMENT it observes position change toward an unchanged target, locally completed arrival inside the already-existing 1.35 stopping radius, or interruption; it cannot move the ship or certify M268 server movement. The first-sortie `TAP_TO_SAIL` stage still means intent only. The Command Deck shows separate local route evidence, while native QA remains NOT_EVALUATED and initial ships remain complete individual GLB placeholders. See `M294_PRODUCTION_REPORT.md` and `data/m294_sailing_observation_contract.json`.

## M295
Audit exposed byte-identical active Scout and Raider GLB placeholders. The stable `npc_raider_01` slot now references a distinct one-node/one-mesh complete Raider GLB, produced by `tools/m295_build_raider_glb.py` with documented source/hash. The legacy Raider hull/sail decorator is skipped only for this M295 model. Its replacement needs no combat/AI/collision rewrite. All starter and NPC ships remain individually complete, nonmodular models; final authored art and native render/device QA remain open. See `M295_PRODUCTION_REPORT.md` and `data/m295_raider_single_model_placeholder_contract.json`.
