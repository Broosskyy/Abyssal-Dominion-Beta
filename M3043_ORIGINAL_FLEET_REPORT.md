# Abyssal Dominion — M304.3 Original Fleet & Ocean

Date: 2026-10-30. Separate integration branch: `rebuild/m3043-original-fleet-ocean`.
Base: last verified M304.2 code commit `5d9f9b6`, documentation-only head `43a01e3`. M302 `main` remains unchanged.

## Implemented (source code committed)

- **New original 3D vessel system:** `scripts/classic/m3043_original_vessel.gd`.
  - Independent lightweight procedural mesh silhouettes for brig, frigate, ghost, raider, and sloop.
  - Tapered hull, side rails, decks, cabin, cannon barrels, yardarms, cloth sails, rigging, bowsprit, pennant.
  - Gentle visual heave and roll. Parent ship node still owns movement and collisions.
  - `set_hull_ratio()` controls damage-only meshes. 100% HP cannot select an unverified wreck atlas row.
  - No third-party ship meshes/textures are included in this original 3D subsystem.
- **Game integration:** `scripts/classic/m3043_original_fleet_ocean.gd`; entry scene now runs this script. Fresh sessions default to original 3D mode; existing explicit test mode meta stays respected. The original 3D switch is separate from the previously established SeaBattles/SeaOfBones two-pack toggle.
- **Visual world:** original time-animated water shader, original captain ship emblem `assets/classic/original_ui/captain_ship.svg`. This is actual Godot shader and scene source, not a mockup.
- **State continuity:** 3D ship class changes use the same gameplay ship node and maintain active combat state, ammo, gold and course. NPC health and player hull ratio update visible damage state.
- **Old gameplay systems:** M304.2 HUD, active 3-way ammo and chainshot, quests, ports, NPCs and loot remain in the same scene.
- **QA:** `tests/m3043_original_fleet_smoke.gd` verifies actual game creation, original mesh groups, damage ratio transitions, class buy, original/reference toggles and ongoing ammo/UI state. GitHub CI runs existing M303.7–M304.2 regressions before new test and APK export.

## Unverified / outstanding

- Engine-level headless checks do not prove final on-device appearance, battery consumption, FPS, GPU/thermal performance, touch quality or ship-scale aesthetics.
- The 3D ship meshes are code-generated original game art, **not** a final high-poly ship production asset pack. More modeling, texture work and animation will be needed.
- Local game only; newer M304 gameplay systems are not server authoritative and are not yet integrated with the older M302 transactional backend.
- Reference sprites from SeaBattles and SeaOfBones remain test-only; do not publish or distribute third-party art without adequate rights.
- GitHub Actions creates a new temporary Android debug signing key for each build. Updating over an older test app can fail; back up local data first and consider permanent keystore handling.
- APK CI artifact is temporary, not a permanent release.

## Next acceptance tests after CI

1. Real Samsung installation, 844x390 and native landscape orientation, 60-second sailing and tight turns.
2. Original ship remains visibly intact at 100 HP while navigating, and enters actual damage state only when HP falls below 33%.
3. Buy frigate and ghost ship; verify actual changing hull/sail silhouettes without teleport.
4. Fire iron, harpoon and chainshot; collect gold; shipyard open/close; original/reference switching.
5. Review frame rate, camera distance, ocean, wake and ship details from a real device capture.


## Verified Godot and Android CI result (2026-10-30)

- Validated source commit: `5f293f5e8b6ee414f76e039bc15a4b9db22cb264`.
- GitHub Actions: `https://github.com/Broosskyy/SOH-2/actions/runs/41022623175` — **SUCCESS**.
- **PASS**: Godot 4.7.2 GDScript import and all M303.7–M304.2 regression tests.
- **PASS**: New M304.3 integration test (model silhouette families, true-HP damage visibility, live graphics toggles and shipyard).
- **PASS**: Android ARM64 APK export, signature verification, ZIP integrity and 16K alignment.
- APK: `ABYSSAL_DOMINION_M3043_ORIGINAL_FLEET.apk`, SHA256 `42fe7bdabc17166a355590243a05b7ab548a636dc4326aa07d23337db3df13c7`.
- GitHub artifact ID: `12962516297`, `https://github.com/Broosskyy/SOH-2/actions/runs/41022623175/artifacts/12962516297`.
- Archive size: 74,785,397 bytes. Expires 2026-11-06 07:52 UTC; back up locally before expiration.
- APK contains legacy reference sprites because this is a *private/local test build*. Do not redistribute the proprietary source art without authorization.
- **NOT_TESTED**: real Android device installation, actual in-game rendered look and frame rate. These require on-device testing.
- The build is signed with an ephemeral debug key; replacing a previous test APK may require removing the old package after backing up local data.
- The source branch and original graphics scripts and SVG are permanently versioned on GitHub. The APK is an Actions artifact, not yet a permanent Release.
