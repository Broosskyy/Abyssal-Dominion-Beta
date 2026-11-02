# M103 — Transaction Boundaries + Guest Upgrade + P0 Import Readiness
1. Audit newest Masterkonzept first; if V3.7 is accessible, treat it as overriding source.
2. Add versioned Account/Profile DTO contracts.
3. Add transaction envelopes for Inventory/Wallet/Rewards/Entitlements with idempotency and revision fields.
4. Add Guest -> linked account merge/conflict policy and provider-linking conflict states.
5. Add local fake transport only behind explicit test interfaces; never label it live backend.
6. Expand P0 QA to generated import-readiness report for all first-13 slots.
7. Continue mobile/world/guild/HUD polish and performance budgets.
