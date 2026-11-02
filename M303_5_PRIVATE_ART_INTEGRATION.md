# Abyssal Dominion M303.5 – local artwork integration

**Current player entry: M303.6.** See [M303_6_UNIFIED_PRESENTATION.md](M303_6_UNIFIED_PRESENTATION.md).
Only SeaBattles and SeaOfBones are selectable in the current app. The four-mode
comparison described below is historical; the main HUD/world is unified and
graphics changes no longer reload the scene.

Updated 2026-10-29. Current build instructions are in
[M303_5_LOCAL_GRAPHICS_AND_ANDROID.md](M303_5_LOCAL_GRAPHICS_AND_ANDROID.md).

The native Godot 4.7.2 test supports two independent, optional local artwork
packages. The repository includes adapters, import/audit tools and fallbacks;
the original artwork and built private APK are not committed or publicly hosted.

## Source packages

- SeaBattles 1.24.0: `com.RoyaleGames.SeaBattles`.
- SeaOfBones 1.3.68: `com.seaofbones.game`.

Local graphics and `pack.json` belong under ignored
`assets/classic/private_seabattles/` or `assets/classic/private_seaofbones/`.
Source labels, actor mappings and animation layouts are read from the manifests.
The code-only checkout continues to run using the existing own fallback art.

## Atlas handling

SeaBattles ship atlases contain four diagonal views with two sail states.
The upper and lower rows must not be treated as eight different directions.
The adapter separates heading from sail state and animates monster rows.
The earlier diagnostic atlas with known color errors is never used implicitly.

SeaOfBones contains 3D source meshes. Its previous local PNG test uses explicitly
derived Godot renderings; those images are not represented as original sprite
sheets from the APK. The supplied renderer remains an optional offline tool.

## Validation performed

- 1,409 SeaBattles Texture2D/Sprite PNGs exported; 18 empty 0x0 font textures
  recorded as non-exportable.
- All 268 SeaBattles ETC2_RGBA8 textures compared pixel-for-pixel with native
  Godot decompression: maximum RGB and alpha difference zero.
- Native heading, sail-state, monster-animation, course, damage, ammunition and
  graphic-fallback smoke checks passed.
- Native captures checked at 844x390, 1280x720 and 1920x1080.
- The actual scene started successfully with both private directories absent.
- Separate ARM64 Android test APK built using Godot 4.7.2; signature, ZIP
  integrity, embedded pack manifests and 16-KB zip alignment checked.

No physical Android device installation, touch playtest, browser export or live
multiplayer validation was performed in this pass. Earlier reports document
earlier prototype states and do not supersede this update.

## Existing prototype limitations

The graphics switch cycles SeaBattles, SeaOfBones, 3D and 2D and reloads the local
scene. Existing collision radii remain independent of the new coastline images.
Water noise feeds the Godot shader; this does not reconstruct the full original
Unity water rendering. Gameplay remains the isolated local M303 prototype.
