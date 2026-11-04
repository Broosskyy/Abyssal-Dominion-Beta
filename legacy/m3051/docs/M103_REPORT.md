# M103 — Transaction Boundaries + Guest Upgrade + P0 Import Readiness

M103 continues the real-online migration path without pretending that a backend exists.

## Online/account architecture
- Versioned Account, Captain Profile, Linked Provider and Session DTO contracts.
- Immutable Account-ID/Captain-ID separated from mutable Captainname.
- Transaction envelopes for Inventory, Wallet, Reward, Entitlement and Progression.
- Idempotent client-request IDs and optimistic revision guards are mandatory.
- Guest -> account upgrade and provider-linking conflicts are explicitly modeled.
- Automatic destructive merging is forbidden; both profiles must be reviewed before future server commit.
- Premium currency and unique entitlements may never be blindly duplicated.

## Asset production
- Generated import-readiness covers the complete P0 first-13.
- Final overrides and fallbacks are visibly distinct.
- Waterline, +Z forward, wrapper-owned collision and mobile silhouette rules remain binding.
- `monster_early_01` keeps semantic rig/animation acceptance and is the P0 rigged Hero target.

## Truth
No live auth, database, server transaction, provider linking, payment entitlement or GLOBAL authority is implemented in M103.
