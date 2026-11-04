# M19 — World Composition & Ocean Calibration

M19 continues directly from M18 on the Godot 4.7.2 / Compatibility-renderer baseline. No gameplay systems from M18 were reset.

## World composition

The sector generator now uses a deterministic macro-first island composition instead of 3–4 similarly sized round islands. Each sector attempts to place one clear large landmark, two medium islands and two or three smaller navigation accents. Footprints vary from compact to long/thin; yaw, size and vegetation density vary deterministically per sector. Placement keeps a central navigation pocket, respects harbor clearance and rejects island-to-island overlap.

`ProceduralFactory.create_island()` now accepts an X/Z aspect ratio, yaw and prop-density profile. Coast, ground, underside, collider, shoreline foam and recovered reference mesh scaling all follow the same footprint. This keeps visual and physical bounds materially closer than stretching visuals alone.

Vegetation is deliberately less repetitive: small/thin islands receive fewer props, larger islands more, with six authored local placement anchors rather than the previous fixed three-prop pattern.

## Ocean calibration

The Compatibility water shader now uses calmer displacement, layered normal sampling, a deep/mid/shallow palette and lower metallic/specular response. The goal is a broader readable sea surface behind ships and islands rather than a uniformly bright blue material. It remains WebGL/Compatibility-safe and does not add screen-space refraction or Forward+-only effects.

## Preserved M18 behavior

Captain journal, harbor actions, targeting/occlusion, missions, inventory, shipyard, encounter logic, input restrictions and save format are unchanged. Sector generation remains deterministic for a given coordinate.

## Validation in this environment

Python preview tests and M19 static contract checks pass. This environment does not contain a Godot 4.7.2 executable, so an engine parse/run and a fresh Web export could not be produced here. The bundled Web build therefore remains the prior M18 build and must be rebuilt with Godot 4.7.2 before claiming an M19 browser preview. No screenshot is presented as M19 visual acceptance.
