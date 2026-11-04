# M141 — P0 Vertical Slice Production Polish

This milestone moves P0 placeholders closer to useful production stand-ins without pretending they are final art.

- The three beginner ships now have separate small/medium/large silhouette profiles in runtime.
- PL1–5 NPCs use five different placeholder silhouettes while preserving the neutral-until-attacked beginner behavior.
- The first teaching monster uses canonical slot `MON-KRAKEN-001` and receives an additional Kraken-readable radial tentacle/mantle fallback.
- Haven's Reach receives five visual-only modular production sockets: dock, warehouse, market, shipyard and beacon. Gameplay safe-zone/shop/quest/dock logic remains wrapper-owned.
- Core HUD families have canonical P0 production slots and a 48 px minimum mobile touch-target contract.
- P0 asset publish validation can reject supported ship records with missing declared anchors.
- The P0 replacement readiness manifest now carries explicit production checkpoints and continues to mark native QA as pending.

Master V3.7 and the production concept remain binding: mobile oblique top-down readability, stable AssetSlots, no gameplay breakage from missing Hero assets, and runtime composition for effects instead of duplicate GLBs.
