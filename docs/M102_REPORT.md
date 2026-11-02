# M102 — Account/Auth Boundary + Repository Boundary + P0 Visual Acceptance

M102 implements the next architectural step without pretending a live service exists.

- AuthGateway defines Guest/E-Mail/Google/Apple provider boundaries.
- LocalAccountAdapter bridges current offline LocalSession but can never become server-verified.
- Account-ID, Captain-ID and Captainname are separated by contract.
- RepositoryGateway isolates persistence; LocalGameStateRepository keeps the current save system functional.
- Future Inventory/Wallet/Entitlement/Progression writes are specified as idempotent server transactions.
- CompatibilityGate separates client build, API compatibility, content config and environment identity.
- P0 first-13 matrix now includes waterline, +Z forward, wrapper-owned collision and mobile silhouette acceptance.
- `monster_early_01` receives semantic idle/attack/hit/death rig/animation acceptance; gameplay remains independent of clip names.
- Asset Preview reports monster final-Hero animation readiness.

No live authentication, backend, server persistence, payment entitlement, production Staff authority or GLOBAL server is claimed.
