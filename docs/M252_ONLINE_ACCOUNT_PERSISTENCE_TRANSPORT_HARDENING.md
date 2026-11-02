# M252 — Online Account / Persistence / Transport Hardening

## Master alignment
V3.8 requires persistent accounts, environment isolation, server-authoritative ownership/economy/world state, separated service domains, request/transaction IDs, content compatibility and reconnect/resume readiness. Local simulation is explicitly not a live trust source.

## Source changes
- Added `m252_online_readiness_contract.json`.
- Added `M252OnlineReadinessRuntime`: monotonic verified server session replica plus local diagnostics only.
- `ServiceLocator` now exposes explicit Auth, Repository and Transport capabilities.
- LOCAL uses local-preview adapters; non-local environments fail closed to unavailable base gateways until real implementations exist.
- Gateway capability reports now include verification/authority/environment-isolation semantics.
- Added responsive Command Deck `Online & Systemstatus` page.
- No permanent network panel was added to the sea HUD.

## Authority lock
The client cannot assert connection, verify an account, promote a local save to production persistence, generate server revisions, override environment isolation, synthesize trusted time or finalize reconnect/resume.

## Remaining production work
Real provider authentication, persistent backend repository, verified remote transport, authoritative world/session server, reconnect/resume, load/security/network/device QA.
