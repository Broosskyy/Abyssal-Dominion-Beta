# M180 — Evidence-led Mobile Visual Repair

M180 responds directly to the supplied M177 Android screenshot and 144-second recording, checked against the embedded gameplay master reference in Masterkonzept V3.8.

## Verified causes and repairs

- High-DPI Android width was interpreted like desktop width, exposing six secondary navigation buttons. Mobile navigation now follows the master hierarchy: Karte, Werft, Log, Arsenal and Menü; very narrow layouts retain Werft, Arsenal and Menü.
- A separate Admin toggle occupied the same top-right area as Menü. Standalone Admin and Meta toggles are removed on touch and routed through the full menu.
- Compact fixed coordinates placed Repair over Ammunition and the quickbar over combat selectors. The full bottom-right cluster now uses one relative geometry model plus a runtime overlap guard.
- Event summary, event quests and minimap competed for the same rail. Touch mode keeps one concise event chip; full event quests remain in Menü > Events.
- Admin used raw 390×620 desktop pixels, no shared mobile theme and no modal input lock. It now uses density-scaled controls, a centered large panel, dark modal shade, Back handling and sailing suppression. Meta receives the same modal behavior.
- The ocean combined low roughness, high specular strength, strong normals and a 1.25 sun, producing the large white area visible in the recording. Water is now non-metallic, substantially rougher, less specular, calmer and paired with darker environment profiles.

## Preserved locks

The ship models and existing gameplay camera are retained. Ship movement remains Tap-to-Sail, the bottom-left wheel moves only the camera, the primary attack remains bottom-right, the sea-map center stays gameplay-first and all online-critical values remain server-authoritative.

## Validation boundary

Static regression tests cover prior M175-M179 systems, M180 data contracts, the supplied 2340×1080 combat geometry and package integrity. A new Android build and real-device screenshots are still required to visually approve the shader and physical sizes.
