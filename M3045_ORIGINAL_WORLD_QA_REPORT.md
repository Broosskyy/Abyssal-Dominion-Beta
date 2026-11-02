# ABYSSAL DOMINION M304.5 — Original World & Visual QA

**Validated source:** `958cd168d28786c9e2e52303137ecb0761fadfbd`.
**GitHub Actions:** https://github.com/Broosskyy/SOH-2/actions/runs/41333170661 — PASS (Godot 4.7.2, all inherited regression tests, M304.5 world test, desktop screenshot pass, APK export).
**Branch:** `rebuild/m3045-original-world-visual-qa` (separate from M302 main).

## Implemented in the playable scene

- **Six original low-poly islands**, represented as Godot runtime meshes (not stock/third-party art): varying stone cliffs, snow, temperate rock, tropical vegetation, fortress, volcano, palm trees, pines, wooden piers, lighthouse and a glowing beacon.
  - Source: `scripts/classic/m3045_original_island.gd`.
  - Collision circles and pathfinding use existing island data; art meshes are visual only.
- **Original monster / Kraken** with a modeled head, luminous eyes, seven waving tentacles and a damage-linked animation response; continues to be a real targetable NPC with inherited HP, targeting and loot.
  - Source: `scripts/classic/m3045_original_kraken.gd`.
- **Wave shader** now includes GPU vertex displacement, multiple overlapping color ripples and surface sheen; shoreline foam is placed around every existing island while first-party 3D is active.
  - Source: `scripts/classic/m3045_original_world_pass.gd`.
- **Fleet detail expansion:** deck plank seams, hull bands, side windows, material tones, and extra first-party mesh details. The old true-HP-only damage visibility remains intact.
  - Updated: `scripts/classic/m3043_original_vessel.gd`.
- Visual style switching preserves the player's ship identity, HP, current ammo and the game economy, and restores islands and monster meshes when returning to original mode.
- Existing M304.4 interactive munition menu, shipyard, animated ships, all controls remain in the current playable scene.

## Verified tests

- **PASS:** Godot scene import; regression tests M303.7–M304.4, and new `tests/m3045_original_world_smoke.gd`.
- **PASS:** rendered **desktop** 1280x720 screenshots using Xvfb/GL compatibility: `visual/m3045_ocean_fleet.png`, `visual/m3045_ammunition_menu.png`, `visual/m3045_shipyard.png` (inside Actions artifact). These are actual in-engine captures, **not** edited conceptual screenshots and **not** Android device captures.
- **PASS:** Android ARM64 build + ZIP integrity, signature verification and 16 KB alignment.
- APK: `ABYSSAL_DOMINION_M3045_WORLD_ART.apk`, size 76,854,120 bytes, SHA256 `ea02c7a9c33ae2231b70223499b5789b0652c41d35b302f432bfca9fbc9d7127`.
- Actions artifact ID `13093809819`: https://github.com/Broosskyy/SOH-2/actions/runs/41333170661/artifacts/13093809819
- Artifact expires **2026-11-08 17:47:55 UTC**. Keep a copy of the APK and screenshots outside GitHub Actions.
- Actual installation, gameplay touch, frame pacing, battery/thermals on Android: **NOT TESTED**.

## Real rendered visual review / issues for M304.6

1. The ships are still relatively small at 1280x720; test ~15–25% closer camera view and maintain enough space for ship-target interactions.
2. Snow islands are visually too bright; tune material albedo/exposure, rock layering and silhouette quality.
3. Coastal foam bands are thick and hazy; narrow them and introduce subtle wake texture rather than large diffuse white rings.
4. Islands are distinct but low-poly / angular. Next pass should add natural coast shaping, shoreline textures and higher fidelity vegetation details.
5. HUD is functional in captured screenshots; further align captain gold/kill text, label wrapping and card distances on real Android devices.
6. Current original 3D ships use generated geometry and details, but still lack production PBR texture atlases and sculpted hull variants.
7. Replace third-party test textures in the APK before sharing any publicly. CI stages reference graphics into the local test APK only. All M304.5 island/monster/ship-detail changes are first-party code.
8. Debug keystore is ephemeral; a reinstall may be needed rather than an update. Back up local app data before uninstalling.

## Next gates

- Confirm the 3D ship and island visual scale on an actual Samsung Android device, capture short screen video and touch interactions.
- Improve original ship detail / material fidelity, shorelines, monster attacks and visual hierarchy using the screenshots as ground truth, not generated mockups.
- Finalize first-party/licensed-only release asset list and stable signing before any public APK.
