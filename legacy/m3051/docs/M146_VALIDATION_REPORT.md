# M146 Validation Report

Validation date: 2026-09-01

## Passed gates

- 375 JSON documents parsed successfully.
- Fourteen unique P0 master slots, runtime IDs, filenames and catalog paths verified.
- All fourteen dedicated GLBs passed binary magic, Godot import, PackedScene instantiation and visual-only validation.
- Master-to-runtime mapping passed for starter, early NPC, island, harbor and monster families.
- Mobile visual budget metadata and gameplay-geometry isolation passed.
- M145 secure admin transport regression: pass.
- M144 admin adapter regression: pass.
- Godot editor/import scan: no script, parser or resource errors.
- Headless project startup: no script or runtime errors.
- Preserved coverage: 27 content types, 18 admin modules and 59 RBAC permissions.
- Android code 146 and desktop/mobile version 0.146.0 verified.

## Engine note

Target engine remains Godot 4.7.2 Compatibility. Supplemental automated runtime validation used the locally available Godot 4.5.1 stable binary. Official platform exports must be repeated with Godot 4.7.2 export templates.

## Asset truth

The fourteen files are dedicated swap placeholders, not final production art. P1 PL6-15 production remains gated behind P0 visual acceptance on desktop, Android and iOS; Web remains preview-only.
