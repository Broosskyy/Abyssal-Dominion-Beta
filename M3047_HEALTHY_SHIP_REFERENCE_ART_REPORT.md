# M304.7 – Gesundheitsfehler der Schiffsgrafiken behoben / Reference Art import

**Tested source commit:** `bb1cd0cbf4affb5cd13c12c6d2a93aa6d2c5087e`.
**CI:** https://github.com/Broosskyy/SOH-2/actions/runs/41356540444 — **SUCCESS**.
**APK:** `ABYSSAL_DOMINION_M3047_HEALTHY_SHIP.apk`, 79,404,269 bytes, SHA256 `ccde984af29fb88be11710c6139662675f6647b1bbab1232c0ab6ec662a445cd`. Signature, integrity and 16KB checks PASS. Physical Android install NOT TESTED.
**GitHub Actions artifact:** https://github.com/Broosskyy/SOH-2/actions/runs/41356540444/artifacts/13103516213 (expires 2026-11-08 ~22:20 UTC).

## Reproduced, evidenced cause of “wrecked” ships at full health

The earlier M303.5 rendering adapter forced **SeaBattles 1.24.0 atlas row 0** under the assumption that every other row could be an unverified damage state. A visual audit of actual decoded engine atlas art confirmed the opposite interpretation:
- **Row 0 (col 0-3): furled / retracted sails** (the ship looks bare and broken when sailing, despite 100% HP).
- **Row 1 (col 0-3): fully deployed healthy sails**, the proper in-game sailing appearance.

Both rows are **sail states**, not hull-health states. This was confirmed for elite8, warship, pinnace, flyingdutchman. Sea of Bones ship rows encode orientation/detail and were left unchanged.

**Actual fix:** `scripts/classic/m3035_render_adapter.gd` now identifies SeaBattles ship sources and pins all 4 cardinal headings to their visually verified row-1 frames (indices 4–7). It applies at 100 HP, while stopped, while sailing, after turning and after repair. HP changes cannot choose row-0 appearance.

**Regression test:** `tests/m3047_health_safe_art_smoke.gd` verifies the live player and 3 NPC models for 64 heading+motion transitions and multiple hull levels. All tests from M303.7 to M304.6 remain PASS, as well as the new M304.7 test.

## User-supplied visual references processed into private test assets

- Two **transparent actual ship top-view textures** extracted from the supplied four-view sheets, preserving original painted detail: `Kraken’s Fury` and `Shadow Reaper`.
- Five **nine-slice style UI graphics** extracted from the supplied black/bronze panel reference: standard panel, item slot, primary button, secondary button and navigation tab.
- Separate user-delivered archive `Abyssal_Dominion_M3047_Referenz_Assets.zip` includes PNGs, `pack.json` and usage notes.
- `scripts/classic/m3047_topdown_ship_reference.gd` provides a **real Godot Sprite3D top-view texture renderer**, rotates intact ship as a 3D-plane image with gameplay ship yaw and always uses the same single healthy sprite frame, irrespective of HP or sailing state.
- `scripts/classic/m3047_user_reference_art_mode.gd` discovers privately staged files at `res://assets/classic/private_user_art/` or `user://abyssal_user_art/`. It applies custom art to explicitly mapped actors, with SeaBattles/SeaOfBones fallback, and can apply the supplied navy/bronze panel as nine-sliced `StyleBoxTexture` to real Godot panels.
- CI uses a **synthetic generated image** to test the loader without publishing user-supplied reference images. The custom user art files are not inside the GitHub Actions APK and not in the public repository; the APK's visible art is the corrected SeaBattles reference graphics. **Do not claim Kraken's Fury or Shadow Reaper are visibly included in that APK.**
- The supplied design sheets show multiple views and many ships; these 2 transparent top sprites are an **initial extraction**, not production-ready complete 8/16/32-direction animation sheets.
- Verify rights/provenance before public redistribution. Original commercial APK test graphics remain private-testing only.

## User reference direction for subsequent production passes

- 2.5D top-down/isometric, richly textured wood, metal and sail cloth; NO simplistic untextured procedural low-poly hulls as the visual target.
- Authentic silhouettes per role: small sloop/pinnace, trading brig, multi-deck frigate, deep-sea armored flagship, spectral/kraken/ice/fire themed NPCs, merchant ships, seasonal event ships.
- Four key visual viewpoints from user-provided orthographic sheets: front, broadside, top, stern. They are references to generate/import a consistent 8–16 heading sprite sheet, not literal frame sequence for a continuously rotating 3D model.
- Damage is a separate independent, health-driven overlay layer: intact 100%, moderate visible damage below thresholds, critical smoke/burning when low, sinking only on zero HP.
- UI style: black textured navy and dark bronze panels, small metallic corners, luminous gold trim, crisp item slots, distinct primary/secondary buttons; textured StyleBoxTexture nine-slicing retains corner ornaments.
- Ammo styling should match real iron cannonballs, chainshots, harpoons, special fire and spectral effects. Each ammo type must map to a distinct actual projectile, muzzle/impact effect and consumed inventory quantity, not a static icon.
- Most urgent future delivery after this bug: enable private user art in actual Android test APK through a permission-safe import or private build pipeline; then tune gameplay sprite scales using an on-device video.

## Limitations

Rendered desktop GL QA screenshot is not Android QA. Original Atlas row mapping is now correct, but a visually stylized damaged-looking *source texture* can still look dark even when structurally intact; source art quality and scale need further improvements. There is no claim of on-device smoothness testing. GitHub Actions artifact expires in 7 days.
