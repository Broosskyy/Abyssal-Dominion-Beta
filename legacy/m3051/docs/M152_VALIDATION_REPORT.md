# M152 Validation Report

Validated on 2026-09-01. The project target remains Godot 4.7.2 Compatibility; the executable available for this supplemental headless run was Godot 4.5.1, so final native 4.7.2 and device acceptance remains required.

- Static JSON and integration checker: `M152_CHECK_PASS`
- Godot project parser/import: pass with the available 4.5.1 supplemental runtime
- Main-scene headless smoke: pass
- M152 runtime contract test: `M152_V38_META_SYSTEMS_PASS`
- M144–M151 regression suite: all eight pass; M148 was rerun alone after one post-pass headless teardown crash and then exited cleanly
- M152 contract counts: 6 companions, 6 artifacts, 4 AFK profiles, 30 Admin content types
- Preserved ship direction: 3 starters, 100 regular classes, Prestige P1–P5
- Source archive integrity: checked after packaging with `unzip -t`

No production backend, real database claim transaction, authenticated account ownership, crossplay session or cloud persistence is claimed by this validation.
