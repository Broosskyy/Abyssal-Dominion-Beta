# M12 — Cross-platform preview, actual Web rendering and material correction

## Ready for Cursor

- `npm start`, `python3 tools/preview.py`, Windows batch and shell launchers.
- Current prebuilt Godot Web export included under `builds/web`. Unchanged source
  can be previewed without a local Godot install; Python 3.10+ is still required.
- Source fingerprint detects stale builds. `--godot` / `GODOT_BIN` / PATH selects
  an installed editor; matching templates remain an external prerequisite for rebuilding.
- `--watch` rebuilds on source changes and the browser polls the build stamp to
  reload. A failed export keeps the previous build and reports the error.
- Default listener is localhost:8077; `--lan` deliberately exposes only exported
  game files to a trusted network. Directory listing, dot paths and symlink escape
  are blocked. There is no command-execution endpoint, external publishing,
  firewall modification or router forwarding.
- Custom Web shell supplies start/audio gesture, progress, errors, fullscreen
  request and build identification. No PWA caching during development.
- Single-thread Web export and desktop/mobile texture support are enabled.
  Existing Android/iOS/Windows/macOS/Linux presets retain one GDScript codebase.
  Android Internet permission is prepared for future networking.
- Cursor rules and `START_HERE_CURSOR.md` explain how to start/rebuild and what
  localhost, LAN and a remote HTTPS URL mean. The local server is not public hosting.

## Crossplay preparation — deliberately limited

A separate WebSocket probe implements bounded packets, a version/build handshake,
locally assigned session numbers, a client limit and handshake timeout. The
native Godot clients and a real Chromium WebSocket client were tested against it.

**No shared gameplay is implemented.** It does not replicate movement, combat,
inventory, NPCs, accounts or saves. The offline game never automatically connects.
The probe server listens only on loopback and is not production-authenticated.
See `M12_CROSSPLAY_PLAN.md` for the authority/snapshot/account work required next.

## Graphics findings from the first actual render

The screenshot request exposed issues not visible in previous dummy-renderer tests:

1. Thin Clipper sails were culled from the current camera side. Sails and flags
   now use double-sided Godot materials.
2. The Clipper hull and sails had unrelated frigate texture atlases. Original
   MeshFilter/Renderer/Material references were inspected again. Hull mesh 945
   uses material 345 `Clipper_main`, whose diffuse texture is 653 `Clipper_diff`.
   Cannon/detail material 344 uses texture 524 `Ships_Detail_diff`.
3. Clipper detail mesh 944 and flag mesh 1181 were extracted and attached in the
   existing model coordinate space. This improves the existing Clipper assembly;
   it is not a newly recovered separate ship family.
4. The original sail material 347 `Clipper_sails_purple` references texture 847
   `Sails_main_diff`, but that serialized texture has **no image data**. It could
   not be recovered. The wrong atlas is removed; the original material's color
   tint is used as a visibly simplified fallback. No original sail bitmap is claimed.
5. Coast meshes in level2 reference sharedassets2 material 53 `coast_new01`, with
   texture 270 `Foam`, UV scale 0.1/0.083, tint alpha 0.391 and speed 0.05.
   The previous opaque rock-atlas treatment was wrong. Coast surfaces now use
   a transparent, animated Godot foam material with the recovered texture and
   these parameters. The shader's precise original math is **not recovered**.
6. The mobile canvas previously shrank a desktop-size UI into the phone viewport.
   Touch profiles now use the actual viewport size, preserving usable control sizes.

Provenance is stored in `m12_original_material_links.json` (six prefab renderer
records), `m12_scene_material_links.json` (129 scene renderer records), and
`m12_recovered_visual_assets.json` (five decoded resources, original material
properties, and the explicit unavailable sail texture). Reproduction scripts are
included. Original bitmaps are decoded, not repainted or AI-generated.

## Screenshot interpretation

`docs/qa_m12/` contains real screenshots from the exported Godot game, running in
Chromium 134 / WebGL2 with SwiftShader software rendering. No concept renderer or
image generator was used. Wide, ship detail, harbor, snow and arsenal desktop
views plus mobile gameplay/arsenal views are captured from the same exported project.

`?qa=1` is an explicit debug-only fixture mode: fixed seed, no save writes, stopped
AI/movement, selected camera zoom/position/sector. This makes screenshots
reproducible; it is not a recording of a live battle. The arsenal is opened by
keyboard input on desktop and a real browser touchscreen tap in mobile emulation.

This environment cannot enumerate physical gamepads. Chromium's hardware-device
enumeration crashed, so the capture harness restricts **only its own QA pages**
to keyboard/touch. The shipped Web game retains normal controller support.
Therefore these images do not verify gamepads, Android hardware or iOS Safari.

## Verification boundary

- Real Godot 4.5.1 import and **176/176 passing** headless behavior checks,
  including prior M10/M11 regressions and M12 transport/resource assertions. Details in
  `m12_engine_validation.json`.
- **10/10 passing** Python HTTP/launcher safety tests cover MIME, index, status, traversal,
  dot files, symlink escape, disabled listing/POST, source isolation and stamps.
- Browser-side WebSocket handshake with the local Godot probe:
  `m12_browser_transport.json`.
- Actual Godot Web export plus browser screenshots/errors:
  `qa_m12/capture_report.json` and browser logs.
- Existing 19 platform configuration checks and GDScript lint are also run;
  they are not substitutes for native-device tests.

**Still not verified:** target Godot 4.7.2, signed APK/IPA installation, native
Windows/macOS/Linux packages, physical mobile devices, Safari, audio output on
real hardware, gamepad input, sustained performance or match to the original game.
Shader/light differences, missing sail pixels, some harbor/island material/scale
issues, and incomplete original scene composition remain reconstruction work.

Source and rebuilt preview are packaged together. No official runtime/editor,
SDK, signing keys or source Unity archives are included. Distribution of recovered
original content still requires appropriate rights; nothing is published publicly.
