# Abyssal Dominion M304.6 — DIRECT TAP + REFERENCE ASSET RESTORATION

Built and verified on 2026-11-01 UTC. Tested source SHA: `d5e873a2fd7269b674004c637f8d3afcd6bca450`.
Run: https://github.com/Broosskyy/SOH-2/actions/runs/41353499700
APK artifact: https://github.com/Broosskyy/SOH-2/actions/runs/41353499700/artifacts/13102755594
Artifact expires: **2026-11-08 21:45 UTC**.

## Changes actually integrated

- `scripts/classic/m3046_direct_course_reference_default.gd` is the live scene script; no turn-before-travel behavior. Water tap calls existing obstacle-safe planner, sets direction immediately, assigns full cruise speed, and moves on the **very first Godot simulation step**. Tap to an opposite waypoint changes heading/velocity immediately. Movement is never gated on visual heading. Frame-time-based movement and swept shoreline collision probes remain.
- The native Android `InputEventScreenTouch` is handled directly; duplicate emulated mouse clicks are debounced. Touch input over real controls is intercepted by Godot GUI as before.
- The camera opens at orthographic 59.0 rather than 72.0; the active course is readable on-screen.
- If integrated PNG references are present in private test builds, the game now defaults to **SeaBattles 1.24.0 sprites**, rather than first-party low-poly models. **Sea of Bones 1.3.68** remains available through the existing graphics mode switch. Reference sources are staged by CI from `rebuild/classic-seafight-m303` and are not stored in this public integration branch.
- Captain of Sea 1.0 currently has a Unity resource inventory, not a verified exported PNG sprite pack. Bridge code accepts an optional `private_captainofsea/pack.json` or `user://captainofsea/pack.json` with referenced textures, and conditionally adds it to the graphics cycle **only after the actual files exist**. It is NOT available in this build; do not claim its artwork is already in the game.
- The M304.5 original 3D prototype, environment meshes, shipyard, chains, camera, quests, projectile combat and loot remain accessible, but original low-poly is no longer default when private art is available.

## Verified tests and limits

- Godot 4.7.2 import and smoke regressions M303.7 through M304.5: **PASS** after replacing obsolete tests that assumed turning in place was desirable.
- New `tests/m3046_immediate_course_smoke.gd`: **PASS** — verifies first-frame movement, reverse direction on new tap, full cruise speed, closer camera, real SeaBattles sprite display, Sea of Bones toggle, hull/gold identity continuity.
- Three actual 1280×720 Godot desktop GL screenshots in artifact: `visual/m3046_reference_ocean_fleet.png`, `visual/m3046_reference_ammunition_menu.png`, `visual/m3046_reference_shipyard.png`.
- Android ARM64 `ABYSSAL_DOMINION_M3046_DIRECT_TAP.apk` built; test APK is ~77 MB. SHA256: `fc4f75ca0e119e6b907837a57a909fb8445df1561cf7ce01343110cbe1f72b32`. Signature, ZIP integrity and 16 KB alignment: **PASS**.
- Physical Android installation, native device touch tracking, gameplay fluidity and frame rate: **NOT TESTED**. Headless tests and desktop screenshots do not prove mobile feel.
- First-hand screenshot review: existing SeaBattles ship sprites and island textures appear in the actual game. Ships are still relatively small, and some captain stats approach the lower frame edge. Visual asset quality requires ongoing balancing.
- No new third-party PNGs, meshes or APKs were checked into the public GitHub integration branch. This APK includes existing external reference art for *local/private evaluation only*. Redistribution requires rights review.
- Android CI uses a new ephemeral debug certificate per run; a previous test APK may require uninstall after backing up local progress.

## Next practical step

Run M304.6 on the target Android phone and capture 15 seconds of tapping to distant, close, reverse and coast-adjacent water points. Use that recording to tune motion/collision feel and sprite size. Independently export, inspect, and legally clear suitable Captain of Sea Unity sprites before adding the third pack to an installable build.
