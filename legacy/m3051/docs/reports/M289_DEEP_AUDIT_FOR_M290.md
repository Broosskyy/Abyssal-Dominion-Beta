# M289 Deep Audit for M290

## Verified baseline
- M289 contains 2,600 project files: 592 GDScript, 559 JSON, 112 GLB, 422 SVG and 13 scenes.
- The main gameplay scene is intentionally thin and bootstraps a procedural/runtime-composed sea map.
- Existing foundations cover Tap-to-Sail, camera-only touch control, target selection, cannon/harpoon/support combat, separate Hull/Shield, repair, loot, missions, sinking/respawn, harbor services, world sectors, encounters and extensive data/admin/readiness contracts.
- M285–M288 already provide server-confirmed presentation boundaries for damage, defeat, motion and contact readability.
- M289 adds a correct 12-stage readiness model and honest native QA matrix.

## Confirmed gaps before M290
1. No production code called `observe_local_slice_event`; the 12-stage observer could not accumulate a real local-development run.
2. Core gameplay nodes exposed too few presentation-safe event hooks for navigation intent, target changes, successful salvo presentation, repair intent, loot collection and dock/undock state.
3. M289 showed readiness in Command Deck/GameHud state but not as a restrained in-world first-sortie guidance layer.
4. M289's content manifest used several descriptive slot names that did not match the older stable runtime IDs.
5. The project has many GLB placeholders, but final authored ship art remains pending. Existing placeholders must not be counted as final assets.
6. Native Godot 4.7.2/device/GPU/audio/haptic QA remains unavailable and therefore `NOT_EVALUATED`.

## M290 decision
M290 closes the integration gap with passive event hooks, trusted-receipt guards, one compact HUD progress read and one replaceable world beacon. It does not create a second tutorial authority, auto-navigation, automatic target selection, combat truth, reward truth or modular ship construction.

