# M104 — Transport Boundary + Persistence Schema + Authority Migration

M104 adds the server-facing seam without claiming a server exists.

- `ApiEnvelope`, `TransportGateway` and `OfflineTransportAdapter` separate domain requests from future HTTP/realtime transport.
- The offline adapter hard-blocks GLOBAL usage.
- A PostgreSQL-compatible relational draft covers Accounts, Captains, Providers, Sessions, Inventory, Wallet, Entitlements, Transaction Ledger and Progression.
- No plaintext password or session token is modeled; only token hashes belong in future persistence.
- Inventory/Wallet/Entitlement writes are designed to share atomic server transactions with the idempotency ledger.
- `m104_authority_routing_map.json` documents which current local mutation surfaces later move behind server repositories while HUD/graphics/input/accessibility stay local.
- P0 first-13 gains class-specific visual targets: pirate ship identity, irregular island silhouette, waterline/anchors and monster semantic animation.
- HUD semantic marker cap now consumes the existing mobile graphics profile rather than a fixed cap when the matching legacy cap is present.

The SQL file is a draft artifact only. It has not been executed and no live database/API/auth/backend is claimed.
