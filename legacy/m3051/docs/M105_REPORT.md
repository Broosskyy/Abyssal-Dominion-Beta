# M105 — Service Facades + Adapter Switch + P0 Replacement Dashboard

M105 makes the M101–M104 architecture usable without replacing working gameplay.

- Profile, Inventory, Wallet, Progression and Entitlement service facades now sit at the migration boundary.
- LOCAL_DEVELOPMENT resolves to OfflineTransportAdapter; every other environment fails closed until a real server adapter exists.
- Current PlayerInventory/PlayerProgression/GameState remain functional behind local facades.
- Wallet/Progression facade writes produce local transaction envelopes and refuse non-local writes.
- The P0 dashboard reports all 13 canonical first-wave assets: source-ready, final override, fallback and native-mobile acceptance.
- Asset Preview now displays the P0 dashboard and per-model GLB diagnostics for bounds, +Z forward, Y=0 waterline and wrapper-owned collision.
- Command Deck exposes transport/service status and P0 readiness.
- Two additional pirate/cove visual slots are prepared as replacement-only slots without increasing world object budgets.

M105 still has no live backend, server repository, auth, payment entitlement or production authority.
