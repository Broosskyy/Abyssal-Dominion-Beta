# M86 — HUD Device QA + Safe Areas + Cross-platform Affordances + World Polish

M86 continues the mobile/desktop optimization path without changing gameplay authority.

- Added a non-invasive HUD device preview catalogue for compact phone, wide phone, notched phone, desktop 1080p/1440p and desktop gamepad.
- HUD editor now visualizes the live safe area and can cycle a miniature device preview. This does not change the running game's viewport, controls, progression or combat state.
- Notch/unsafe screen regions are visible around the preview safe rectangle.
- Extended hidden-HUD guards to ammo selector, item selector and log rendering.
- Desktop/gamepad affordances now include separate target and sail/navigation icons; touch mode remains clean.
- P0 NPC procedural fallbacks gained stronger pirate silhouette accents while final/user replacement GLBs are untouched.
- Early-world visual depth continues under existing caps: wreck keel/lantern, irregular coast cliff/tidepool and monster warning harpoon-post/chain slots are now wired.
- Added eight more stable model slots for later direct GLB replacement.
- Asset Preview receives an M86 HUD/WORLD QA filter.

The master P0 first-13 final asset order remains unchanged. Crossplay remains presentation/input architecture readiness only; no multiplayer server/backend is claimed.

Native Godot 4.7.2 parser/runtime, Android/iOS safe-area screenshots, mouse/gamepad QA and real-device touch testing remain pending.
