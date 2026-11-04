# M133 — World/Encounter Content Publishing Foundation

M133 connects the no-code Content Studio further into the actual world runtime.

- Stable world sectors can be added from verified content records instead of requiring a new WorldMapSystem constant.
- Spawn pools merge regional content, sector-specific content and active Event overrides.
- Event records can add NPC, Monster and Admiral content IDs by region/schedule.
- Dynamic quests now have a persistent local runtime with generic objective progress and RewardBundleService reward routing.
- ContentRuntimeService exposes effective content version/source and accepts only validated server-verified snapshots.
- Publishing has an explicit Draft -> Validation -> Approval -> Schedule/Publish -> Version -> Server Activation -> Client Sync -> Audit contract.
- Web Admin and Ingame Admin remain two clients of the same eventual service/RBAC boundary.

Important limitation: newly authored sectors still need a layout coordinate for the current 2D global-map renderer. The graph is authoritative for connectivity, but a fully free-form graph visualizer is not yet implemented.

No production backend, staff authentication, database or payment authority is faked here.
