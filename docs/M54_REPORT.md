# M54 — Native-Risk Repair + Mobile Consolidation

- Removed all four known `albedo_color:a` Tween property paths and now tween full Color values.
- Fixed quickbar cannon-ammo icons from the invalid `m42_ammo_<id>` composition to the stable `m42_<id>` slots.
- Hardened combat-picker vertical clamping when content is taller than the mobile safe area.
- Quickslot bind buttons inside combat detail now calculate width from available space instead of assuming four fixed 88px buttons.
- Renamed the nested bind-flow player local to avoid a duplicate-local parser risk.
- Replaced 30 gameplay placeholder SVGs that contained `<text>` with pure-vector geometric placeholders; docs-only SVGs were not touched.
- Made the local defense stack explicit: vulnerability → temporary barrier → shield → hull armor/armor break/pierce → plate mitigation → hull.
- Added VisualSlotReferenceValidator plus a generated explicit-literal reference report.
- Explicit unknown visual references found by the build-time targeted scan: 0.
- TorusMesh primitives were retained; they are intended Godot primitives, but native Godot 4.7.2 runtime QA remains required.
