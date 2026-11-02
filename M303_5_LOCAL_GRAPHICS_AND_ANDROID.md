# M303.5 private graphics adapters and Android test build

**M303.6 update:** the main player flow now exposes only SeaBattles and SeaOfBones,
under MENU. Both use one HUD, water and coastline, and switching keeps live game
state. See [M303_6_UNIFIED_PRESENTATION.md](M303_6_UNIFIED_PRESENTATION.md).

The local test supports SeaBattles, SeaOfBones, existing 3D models and the own 2D
fallbacks. Artwork is optional and independent of movement, combat and rewards.
The public repository contains code and configuration only for the new packs.
Original PNGs, source APKs, private captures, signing keys and built APKs stay local.

## Local packs

Place decoded PNGs and `pack.json` under the ignored directories
`assets/classic/private_seabattles/` and `assets/classic/private_seaofbones/`.
The manifest specifies actor paths, atlas dimensions, heading offsets, sail-state
frame maps and animation rows. Missing artwork uses the existing own fallbacks.

SeaBattles ship sheets use four headings and two sail states, rather than eight
different headings. The native adapter switches sail rows when sailing and can
animate the monster sheet separately. Switching graphics reloads the local scene.

`tools/import_seabattles_local.py INPUT.apks --all --output OUTPUT` exports all
Texture2D/Sprite images, preserving alpha and writing per-resource failures.
It supports Addressables, hashed serialized files and numerically ordered Unity
split files. `verify_private_etc2.py` compares source ETC2 pixels against Godot's
native decoder. Both tools are offline and do not execute APK code.

## Android

Use Godot 4.7.2 and its matching Android debug export template, JDK 17, Android
platform-tools and build-tools. The `Android M303.5 Local Test` preset creates
an ARM64 debug-signed APK with package `com.abyssaldominion.m3035test`, version
`0.303.6-test.1` / code `303601`. It updates the M303.5 test package using the same key.

```bash
python3 tools/build_m3035_android.py --godot /path/to/godot \
  --android-sdk /path/to/android-sdk --java-home /path/to/jdk17
```

The script defaults to requiring both local packs and verifies the selected
SeaBattles PNG hashes. `--allow-placeholders` is an explicit option for a public
checkout without private artwork. Optional SDK/JDK arguments update the local
Godot editor settings without committing machine-specific paths or credentials.
The default output is under ignored `builds/android/`.

The preset includes both private JSON manifests and their imported runtime PNGs.
Offline mesh-rasterization sources, tools, tests and private QA captures are
excluded from the APK. Debug builds use the locally configured Godot debug key;
keep that key to sign compatible future updates of this separate test package.

Native smoke tests cover source loading, heading/sail/monster animation, course,
damage, ammunition and all four graphics modes. APK signing, package metadata
and archive checks do not replace an installation and playtest on a device.
