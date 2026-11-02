# M298 Production Report

M298 adds model-local placeholder heave, pitch, roll, turn heel and verified staged sinking to the three starter ships and five early NPC ships. The complete ship GLB moves subtly as one visual object beneath the visual wrapper; neither ShipMotor nor collision shape is animated. M287 supplies guarded motion-presentation ratios, M285 supplies confirmed impact-reaction strength, and M286 supplies verified sinking phases. There are no newly assembled modular ship parts, no new gameplay control and no fabricated impact confirmation or defeat.

The M285 shield-state snapshot previously restarted the shield flash on `BROKEN`, even without a fresh impact. This was removed: only a verified `SHIELD_HIT` event or an actual guarded LOCAL_DEVELOPMENT shield decrease starts a flash. Animations stop ambient bob while the M285 ship is defeated; reduced-motion disables ambient sway and damps impact motion. Mobile/web use smaller amplitude without new meshes. Replacement GLBs and inventory/UI previews are untouched. Parameters are data-backed placeholder values, not final tuning; no native Godot renderer is available for visual or device QA.

Seafight and Battle of Sea remain clean-room genre/UX references only; no proprietary animation, timing or asset is used. Open QA: waterline alignment, simultaneous ships/GPU, authored GLB animation coexistence, mobile safe-area readability, impact strength and visual accessibility.

Validation: 450/450 static regression/contract functions and 17/17 unittest cases passed (467/467 total); 572/572 JSON files parsed. No Godot executable was present: native scene import, on-device animation and gameplay feel remain NOT_EVALUATED.
