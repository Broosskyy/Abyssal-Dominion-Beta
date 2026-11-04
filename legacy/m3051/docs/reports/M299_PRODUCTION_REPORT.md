# M299 Production Report

M299 adds `scenes/qa/m299_ship_animation_visual_qa.tscn`, a standalone oblique sea-view visual lab for the three starter and five early NPC complete-model placeholders. Its 4×2 desktop and 2×4 portrait layouts let all eight be inspected. A small labelled dropdown selects Idle, Cruise, port/starboard turn, hull/shield presentation flashes and each sinking phase; it displays missing slots without pretending native QA passed. The QA scene does not change the gameplay HUD, player controls, ship motor, combat or reward state. It deliberately supplies local scene-tagged demo inputs instead of fake `SERVER` events. Outside LOCAL_DEVELOPMENT, after server authority becomes verified, or after the scene exits, QA inputs are rejected/reset.

M287 motion-presentation events now retain server mode instead of being overwritten by LOCAL_DEVELOPMENT speed preview. M285 local health/respawn preview no longer overwrites an active verified presentation state. Invalid server event kinds do not activate server mode. M285/M286 QA overrides refuse active server presentation mode. These are presentation-readiness fixes, not server implementation.

All eight ships remain complete individual GLBs; VFX are external. Seafight and Battle of Sea remain clean-room UX/genre references only. Native Godot parsing, mobile/desktop renders, stage timing, waterline, reduced-motion experience, GPU budget and accessibility remain NOT_EVALUATED; see `data/m299_ship_animation_visual_qa_matrix.json`.

Validation: 454/454 static regression/contract functions plus 17/17 unittest cases passed (471/471 total); 574/574 JSON files parsed. No native Godot executable was available, so the QA scene itself has not been launched or visually accepted.
