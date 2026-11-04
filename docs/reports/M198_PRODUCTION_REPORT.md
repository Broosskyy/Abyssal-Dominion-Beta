# M198 — Visual Master Convergence

M198 changes production priority from feature accumulation to convergence against the V3.8 visual-master gameplay references plus the explicit user correction lock.

## Implemented
- Full 360×360 chart water coverage: render plane 390×390 so the playable chart no longer outruns the primary sea surface.
- HUD lock in runtime layout: world-first edge HUD, large lower-right primary attack, no persistent bottom command/map-selection bar, no centered primary attack.
- Mobile/Desktop keep the same HUD hierarchy and gameplay world; only size, spacing, touch comfort and safe-area presentation may adapt.
- Existing M190 camera framing is preserved as the controlled angled top-down/isometric baseline.
- Existing target/health/reload/loot/combat feedback remains the baseline for later visual polish.

## Visual acceptance boundary
References target water, island/ship readability, camera, target/combat presentation and edge-anchored Navy/Gold HUD. The one reference's persistent lower bar / map-selection composition and centered attack placement are explicitly excluded.

## QA
Static source/contract regression verification only. Native Godot, Android and desktop visual QA is still required.
