# M14 — implemented locally, visual acceptance still blocked

## Delivered implementation

- Home screen uses the saved, owned ship selection (Clipper, Swift Barco or Iron
  Chalupa) and actual saved sector name. Unknown/unowned IDs fall back to Clipper.
  This is read-only and does not rewrite save files.
- The 3D showroom mounts the corresponding recovered mesh family, fits its bounds
  and refits after resize. The missing Clipper sail bitmap is still clearly labeled.
- Device-local audio volume/mute, Auto/Low/Balanced/High quality and map-change
  display settings. Options are reachable from home; Back returns to home.
- Volume and mute drive the actual Master audio bus. Manual quality choices take
  precedence over adaptive FPS reduction; returning to Auto resets sampling.
  Existing resolution/shadow/shoreline quality controls are reused.
- Hiding map-change banners does not stop world transitions, encounters, save
  updates or world-edge warnings. This option affects presentation only.
- Settings are stored separately from captain profiles. Atomic file replacement,
  value validation, corrupt-file protection, defaults and write-error feedback.
  Reset only resets preferences, never captain progression or inventory.
- Responsive menu re-layout preserves a typed captain name across portrait /
  landscape changes. Main home actions stay 50 pixels tall.
- Version 0.14.0 in package/export configuration and M14 in menu/Web/window title.
  The legacy `config/name` remains `SeeFight 3D Reconstruction Lab M13` deliberately:
  Godot derives the native user-data directory from it. Changing that identifier
  would make existing M13 profiles appear to disappear. This is not stale M13 code.
- Engine feature baseline aligned to the actually used Godot 4.5.1. No claim of
  testing newer editor versions. All six export presets remain present.

## Reconstruction evidence and limits

`docs/il2cpp/Assembly-CSharp.metadata-skeleton.cs`, type #3881:
`Code.Core.Common.Settings.ClientGameSettings` contains the
`ShowMapChangeTransition` field/getter/setter and `EnableMapChangeTransition`.
M14 uses this as structural evidence for an equivalent setting. The metadata does
not contain its original implementation, defaults, animation timing or visuals.
The toggle implementation, volume controls and quality UI are new Godot code.

No new Unity assets were extracted in this milestone. Existing recovered ships,
islands, textures, audio and gameplay systems are retained. Missing sail texture,
unrecovered UI art, original server logic and remaining original behaviour are
not claimed recovered. This is still a private-test reconstruction, not a proven
1:1 original game or a finished Crossplay product.

## Executed verification

Godot `4.5.1.stable.official.f62fdbde1`, headless/dummy renderer:

| Suite | Checks passed |
| --- | ---: |
| Existing M10–M13 regression suites | 213 / 213 |
| M14 settings, save projection, layout and lifecycle suite | 113 / 113 |
| Total engine assertions | 326 / 326 |
| Python preview/server tests | 10 / 10 |

- Fresh editor import and non-threaded Web debug export succeeded.
- Preview build fingerprint matches current source (see `builds/web/preview-build.json`).
- `npm start` actually started the local preview; HTTP returned the M14 shell,
  current build status and `application/wasm` for the WebAssembly binary. That
  temporary verification server was stopped after checking it.
- JavaScript syntax checks and Python compile checks passed.
- M14 tests include an isolated real settings-file round trip, corruption
  protection, actual audio bus values, all three recovered showroom families,
  five menu/game/menu cycles, one player and one settings service per cycle,
  quality preference priority and world traversal with hidden banners.
- Real Godot Control geometry was checked at 1600×900, 844×390, 915×412 and 390×844.
  Play is inside the viewport at each size. This checks geometry, not rendering.
- Tests set reconstruction test mode and use a randomly named temporary file;
  they do not alter real player saves. Only that created fixture was removed.

Machine-readable evidence: `m14_engine_validation.json`, individual engine logs,
`m14_layout_validation.json`. Repeat with:

```sh
python3 tools/run_engine_checks.py --engine /absolute/path/to/godot --milestone m14
python3 -m unittest discover -s tests -p 'test_*.py' -v
```

## Visual verification: NOT PASSED / environment blocker

The actual browser-capture command was attempted after rebuilding Web. It stopped
at Chromium launch: the Playwright browser executable is absent. No graphical
Godot display server is installed either. No browser was downloaded to bypass
the existing environment restriction.

`docs/qa_m14/capture_report.json` records the failure with `passed: false`.
There are **no new M14 screenshots**. The M12 screenshots shipped in the project
are historical and must not be presented as current M14 evidence. No AI images
or UI mockups have been substituted for actual game screenshots.

Pending: real WebGL rendering, clipping/contrast/occlusion inspection, real touch
and virtual keyboard handling, notches/safe areas, device FPS, Android/iOS/native
installation and cross-platform gameplay. Engine checks do not certify these.
The updated capture harness includes the settings screen for the next browser run.

## Start the delivered build

Unzip the complete project and run `npm start` or `python3 tools/preview.py`.
Python 3.10+ is required; Node only wraps that launcher. The bundled current Web
build does not require a local Godot installation. Default URL: localhost:8077.
LAN preview is opt-in with `npm run preview:lan`. No public URL, remote hosting,
online account system, cloud save, game server, signed APK/IPA or multiplayer
session is created by this milestone.
