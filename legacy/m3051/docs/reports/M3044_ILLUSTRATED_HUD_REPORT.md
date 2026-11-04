# ABYSSAL DOMINION M304.4 — Illustrated Naval HUD & Ammo Depot

**Status: PASS — Android test APK built** on 30 October 2026.

- Development branch: `rebuild/m3044-hud-ammo-shipyard-art`
- Code commit verified by GitHub Actions: `b330f87cf4af88e73be8a6cce1d6b40896991d0b`
- CI run: https://github.com/Broosskyy/SOH-2/actions/runs/41050330514
- Download artifact: https://github.com/Broosskyy/SOH-2/actions/runs/41050330514/artifacts/12974118135
- Artifact name: `Abyssal-Dominion-M3044-ILLUSTRATED-NAVAL-HUD-TEST`
- Artifact archive size: 74,817,882 bytes; expires 2026-11-06 11:46 UTC
- Contained APK: `ABYSSAL_DOMINION_M3044_NAVAL_HUD.apk`
- APK size: 76,193,406 bytes
- APK SHA256: `5fc9a4bc033a396309093e8d9c0bf4d0bfa0b11721d1ab8ac3bef537dee041c0`
- Android version: `0.304.4-test.1`, ARM64, Godot 4.7.2
- ZIP integrity / APK signature / 16k alignment: **PASS**
- Physical Android installation, actual visual screenshot comparison, performance/thermal testing: **NOT TESTED**

## Integrated changes

1. `scripts/classic/m3044_naval_hud_ammo_shop.gd`: the **actual game scene** now extends M304.3 with an integrated navy/brass/turquoise HUD, legible role-specific frames, improved panels and touch controls.
2. Functional ammunition inventory opens from a visible touch button and closes from close button or backdrop. It blocks taps on the map. Opening shipyard or settings closes ammunition inventory. Three real ammunition choices remain wired to active combat.
3. Local earned gold purchases actual ammunition: cannonballs (+50 for 15 gold), harpoons (+25 for 18), chainshots (+15 for 20 using inherited restock logic). Purchases cannot overdraft and are reflected in live counters. It is **in-game test gold**, not real currency.
4. Three new vector ship class images are applied to the real shipyard purchase/equip buttons, with distinct purchased/selected states.
5. New original vector art committed at `assets/classic/original_ui/`: `ship-brig.svg`, `ship-frigate.svg`, `ship-ghost.svg`, `ammo-chest.svg`, `coin.svg`, `shipyard.svg`. Existing original helm, repair, fire and three ammo icons are preserved.
6. Secondary quick dock launch; position, speed, hp-state coloring and current gold remain responsive to game data. HUD status moved to free area between player and minimap panels, while bottom navigation/combat/ammo remain grouped.
7. Headless tests verify no overlaps of new actionable controls at 690×330, 844×390 and 1280×720, modal enclosure/exclusivity, shipyard, original 3D fleet, ship graphic pack switches, combat, pickups and ammo restock.

## Known limits / next M304.5

- Ship meshes are original procedural low-poly game geometry. Their visual quality is still a step toward final professionally textured 3D assets.
- Legacy SeaBattles/Sea of Bones test graphics are staged into the **private/local-test APK only**. Avoid public distribution without verified asset rights. The UI artwork authored in M304.4 is original and committed permanently.
- The APK exists as a **7-day GitHub Actions artifact**, not a permanent downloadable GitHub Release. All authored UI/ship source and artwork are versioned on the branch.
- Debug keystore is ephemeral per CI execution. Installing over previous debug APK versions may fail due to different signing certificates; back up local data before uninstalling.
- Need native Android **visual** video QA of touch scale, labels, ship turn feel, game map, menu open/close and ocean surface; headless pass is not visual QA.
- Next step: produce first-party island/monster/ship texture atlas and remove borrowed reference art; implement screenshot-regression and 60fps budget gates; set up consistent non-ephemeral signing and a licensed-assets-only permanent APK release pipeline.
