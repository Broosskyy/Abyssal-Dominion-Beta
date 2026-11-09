# Small Godot browser delivery

The browser still runs the shared Godot game, `simulation.gd`, `network_client.gd` and protocol 1. No alternate rules engine or account system is introduced. Public multiplayer remains the existing presence preview until the common server simulation is implemented and deployed.

Web CI bakes the original GLB fleet, then excludes the complete native mesh/texture directories and native-only paints. Browser UI/background import sizes and compression are bounded in that disposable build checkout. Signed Android presets and the committed project configuration remain unchanged.

`tools/web_delivery.py` exports an initial ZIP containing the real shared game plus startup art, and a separate content-addressed ZIP for 12 additional ship atlases and their previews. `BrowserContent` fetches that art only when opening the shipyard/events or needing a saved elite ship. Packs are size/hash checked, restricted to art resources, cached by hash and mounted without overriding existing core files. A failed download leaves the previous equipped ship intact and can be retried.

The browser starts at the existing account/welcome scene without the Android updater. Its guest button sails directly onto the sea. Registration, login, room selection, WebSocket snapshots and account/session handling keep the shared implementation.

The stock Godot WebAssembly binary remains a first-visit cost. Its URL is hashed by content so an unchanged engine survives future game releases in the HTTP cache. Core and optional packs also have immutable content hashes. `delivery-report.json` records raw sizes and a conservative gzip transfer estimate; only a browser network test establishes actual transferred bytes.

Local first implementation: initial core approximately 6.8 MB (previous game pack 89 MB), optional designs approximately 1.9 MB, stock engine approximately 10.1 MB with gzip. The roughly 17 MB cold-start estimate is not a 3–5 MB first-play claim. CI enforces a 23 MB cold transfer budget and checks that the optional pack is absent during guest startup and that repeat visits reuse the core/engine cache.

Tests include an isolated exported core boot with real HTTP optional download, imported atlas/preview resolution, cached remount and design equip. The browser check starts the actual WebGL game and sails using real canvas input. Existing native UI and HTTP/WebSocket preparation regressions remain in the signed-content pipeline.
