# M15 — Combat presentation reconstruction and resource reuse

M15 continues the actual M14 Godot project. It is implemented source code, not a
work order for another editor. The recovered assets, offline game systems and
existing saves remain the foundation.

## Reconstructed features

- Damage feedback is driven by the real `ShipHealth` result: after armor and
  limited to health actually lost. Protected, sunk and zero-damage hits produce
  no fabricated damage numbers. Display values are rounded; calculations are not.
- Closely timed hits from the same attacker against the same target are combined
  into a short-window total. Critical and normal hits remain separate.
- Critical and slowing labels follow actual hit flags. Turning off effect text
  removes the words, not damage numbers, critical damage or the slowing effect.
- Optional own-damage filtering. Here “own” explicitly means damage caused by the
  player's ship; it is not an incoming-damage-only filter.
- Optional one visible cannonball per broadside. Every original logical projectile
  still exists with the same collision shape, trajectory, damage, critical roll,
  lifetime and ammunition cost. Only extra meshes/trails/flashes/impact visuals
  are skipped; audio still plays once per broadside.
- The three new options are available in the existing settings screen and share
  its validated persistent storage. Old M14 files acquire defaults in memory;
  loading alone never rewrites them. Defaults keep all visual balls and damage
  sources enabled. `user://client_settings_m14.json` remains the stable filename.

## Source evidence, not a claim of recovered method bodies

All references are in `docs/il2cpp/Assembly-CSharp.metadata-skeleton.cs`:

| Original metadata | M15 equivalent | Limit |
| --- | --- | --- |
| Type #3881, `Code.Core.Common.Settings.ClientGameSettings.ShowOnlyOwnDamageTexts` | Own-damage preference | Exact original filtering behaviour not available |
| Same type, `ShowOnlyOneVisualBall` | One visual projectile per broadside | Logical collision model remains this reconstruction's model |
| Same type, `ShowEffectTexts` | Optional critical/slow words | Not all original effects reconstructed |
| Type #3900, `LocalDamageEventData.TargetUnit` / `Damage` | Health-loss event passed to combat feedback | New Godot event implementation |
| Demo types #2608 `UIDamageText`, #2609 `UIDisplayDamage` | Damage/critical feedback concept | Demo metadata does not prove exact production UI, colors or animations |

Lifetimes, merge window, colors, collision-free label placement and event limits
are new implementation choices. Original compiled methods, server behaviour and
exact visual fidelity are not claimed recovered.

## Optimizations

- A bounded buffer holds damage records (32 desktop, 16 mobile); entries expire
  after 1.25 seconds and are cleared on a sector change or scene teardown.
  Records store positions/IDs, not strong references to destroyed ship nodes.
- A single HUD drawing pass displays feedback. There is no new Label3D/Label node
  or tween per hit. Layout tries free positions above the impact anchor and skips
  labels when blocked or offscreen. Names/health bars, primary HUD areas, minimap,
  banners and lower controls reserve space. Map/arsenal/shipyard overlays hide it.
- Recovered ship, island and harbor materials are reused through a cache bounded
  to 96 profiles. Texture, normal map, tint, roughness and culling remain part of
  the key. Double-sided sails cannot accidentally receive single-sided hull settings.
- The existing reconstructed coast shader was moved unchanged to one shared
  shader/material. Per-instance animated wakes are intentionally not shared.
- Long in-game milestone header shortened to fit its existing HUD panel.

## Measured behaviour and object counts

The deterministic engine fixture produced:

| Fixture | Full graphics | Reduced salvo graphics |
| --- | ---: | ---: |
| Logical cannonballs | 3 | 3 |
| Visible cannonballs | 3 | 1 |
| Ammunition spent | 3 | 3 |
| Actual target health lost | 194.4 | 194.4 |

Seeded trajectories, spawn positions, damage values and critical flags also
matched exactly. Collision callbacks still applied damage for hidden balls.

A 20-Clipper fixture contained **120 mesh instances referencing 3 unique
material resources**. This verifies resource reuse, not frame-rate improvement.
No mobile FPS benchmark or GPU memory measurement was performed.

## Verification

- Godot 4.5.1 headless: **373 / 373 assertions passed**.
  - M10–M14 regression suites: 326.
  - New M15 suite: 47.
- Python preview safety tests: **10 / 10 passed**.
- JavaScript syntax checks and Python compile checks passed.
- `m15_engine_validation.json` and stage logs contain current results.
- `m15_presentation_metrics.json` contains the measured fixture counts.

- Fresh, non-threaded Web export succeeded with Godot 4.5.1 and matching official
  templates. `builds/web/preview-build.json` identifies the current source fingerprint.
- Real loopback HTTP preview check passed: M15 HTML, matching build status and
  correct WebAssembly MIME type (`m15_http_validation.json`). The test server was
  stopped after verification; this is not an externally hosted live URL.
- The browser-capture command was attempted after export and failed at launch
  because the Chromium executable is absent. `qa_m15/capture_report.json` records
  `passed: false`. Neither headless checks nor HTTP responses are visual acceptance.

## Remaining boundaries

No additional Unity mesh or texture was extracted in M15. This milestone improves
system reconstruction and the use of existing assets. The missing Clipper sail
bitmap, further original UI art, remaining islands/ships and server systems stay
open. Offline play and the existing transport probe are not shared-world Crossplay.

Current graphical verification remains blocked by the unavailable local browser
renderer. No M15 gameplay screenshot is claimed. Earlier M12 images are historical.
Label readability while moving, crowded battles, real notched phones, virtual
keyboards and native Android/iOS builds still need graphical/device validation.

## Start

Unzip the whole project and run `npm start` (Node wrapper) or
`python3 tools/preview.py` (Python 3.10+). The bundled, unchanged Web build can run
without Godot; editing game sources requires Godot and matching export templates.
LAN is opt-in; no public hosting, firewall changes or signing credentials are added.

Repeat checks:

```sh
python3 tools/run_engine_checks.py --engine /path/to/godot --milestone m15
python3 -m unittest discover -s tests -p 'test_*.py' -v
python3 tools/verify_bundled_preview.py
```
