# M199 Production Report — Visual Master Sea & Combat Readability

M199 continues visual-master convergence instead of adding unrelated meta features. The milestone keeps the M198 390×390 rendered sea over the 360×360 gameplay chart and improves layered water response, shoreline separation, target-ring prominence and selected-target nameplate/health readability.

## Cross-platform parity correction
The user's lock is interpreted strictly: Mobile, Web and Desktop use the same world presentation and gameplay presentation. Historical quality-tier world budgets are now canonicalized so water subdivisions, shoreline segments, transient combat VFX caps, water impacts, wake emitters and shoreline-foam budgets no longer vary by platform/quality tier. Floating combat feedback also uses the same density, merge windows and lifetime; only UI scale may differ.

## Visual-master convergence
Water now combines broad wave/color bands with smaller highlight structure while preserving the established Compatibility-safe shader contract (`NORMAL_MAP_DEPTH = 0.22`, non-metallic water). Coastlines receive a second shallow-water break ring that is presentation-only and never participates in collision/navigation. Selection rings are thicker/brighter, and selected targets receive priority sizing in nameplates and health bars.

## Authority / gameplay safety
No damage, loot, reward, movement, collision, spawn, progression or economy rule is changed by M199. Islands still block navigation; dynamic actors still do not. Tap-to-Sail and lower-right primary combat hierarchy remain locked.

## QA state
Static source tests and JSON validation can be executed in this environment. Native Godot, Android and Desktop visual QA remains pending and must be performed before calling the visual result final.
