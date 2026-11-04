# M256 — Telemetry, Analytics & Observability

M256 advances the V3.8 telemetry/observability domain from FOUNDATION to PARTIAL without pretending that a production analytics backend exists.

The client now has a versioned telemetry contract and a privacy-safe diagnostics boundary. LOCAL may buffer a small sanitized diagnostic ring for development, but that buffer cannot grant rewards, mutate balance, confirm payments, prove cheating, define retention, define alert thresholds or mark production services healthy. Production KPI/alert truth remains server/operations owned.

The contract separates product, gameplay, economy, PvP, guild/social, LiveOps, commerce, network, performance, crash diagnostics and staff/admin observability. GLOBAL and TEST are analytically isolated. Sensitive classes such as passwords, auth tokens, raw store receipts and full payment data are forbidden from telemetry payloads.

The existing Command Deck Systems page now exposes telemetry readiness and privacy/authority status using the established responsive cards and restrained reveal motion. No permanent gameplay HUD panel was added and no world/camera/gameplay balance rule changed.

Still required for production: real event ingestion, aggregation/warehouse, dashboards and alert routing, retention/consent enforcement, crash provider integration, and native/load/soak/chaos QA.
