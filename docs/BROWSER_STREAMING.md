# Godot browser delivery with the complete catalog

The browser runs the shared Godot game, `simulation.gd`, `network_client.gd` and protocol 1. Account/session handling, map rooms and existing crossplay preparation are unchanged. Public shared combat remains a separate unfinished feature.

All approved ship designs, event finishes and shipyard previews are now included directly in the initial core ZIP. The scene loads all 23 ship atlases and all 14 previews immediately. Opening the shipyard and equipping a design require no further art download. `web/content_manifest.json` declares the catalog embedded and has no external ship pack.

Web CI still excludes native 3D meshes and their source textures, and bounds browser texture imports in its disposable checkout. The committed Android project and export presets are unchanged. The smaller Godot browser build keeps the same gameplay rather than introducing another engine.

The stock engine and the complete core use content-addressed filenames. A bounded service-worker cache verifies file hashes and retains unchanged runtime/art files across visits and releases. It caches no account requests, HTML or WebSockets. Browser updates remain separate from Android data packages.

Bundling the approximately 1.9 MB catalog into startup increases a cold visit from approximately 17 MB to approximately 19 MB; measured values belong to each build's browser checks. CI enforces the existing 23 MB compressed-transfer budget and checks warm reuse of both engine and complete core. No 3–5 MB cold-start claim is made.

`browser_delivery_test.gd` runs against the exported core with no network URL, loads every Elite/event atlas and preview, verifies all 23 runtime atlases, opens the shipyard immediately and equips a design. The WebGL test sails into the actual shared game and verifies cache reuse on reopening.
