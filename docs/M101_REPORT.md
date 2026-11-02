# M101 — P0 Replacement QA + Online/Release Architecture Alignment

M101 follows the newest accessible Masterkonzept material in the project library. V3.2–V3.6 were read directly. A V3.7 document was requested by the project owner but was not available in the connected file sources at implementation time, so no V3.7-specific clauses were invented.

## P0 production
- Canonical first-13 replacement matrix added.
- Asset Preview gains a dedicated P0 FIRST 13 filter.
- Each P0 row exposes stable slot, fallback/override state and required acceptance checks.
- Missing final art remains a valid fallback state, never a gameplay failure.

## Online/server architecture
- LOCAL_DEVELOPMENT / INTERNAL_STAGING / TESTSERVER / GLOBAL_PRODUCTION environment contract added.
- BuildIdentity includes client version, build number, ContentConfig version, API compatibility and environment.
- Explicit server-authority boundary covers account, movement validation, combat, ownership/economy, guild state, events, premium entitlements and staff.
- Local telemetry only builds privacy-filtered envelopes; there is no network analytics transport yet.
- Local AdminModeRuntime explicitly does not verify Staff identity and is not production authority.

## Mobile/release
- Data-driven low/balanced/high presentation profiles define render scale, FPS target, shadows, water/VFX/world-dressing policy, marker cap and nameplate distance.
- Profiles cannot alter gameplay/hit/economy authority.
- Command Deck displays local build/environment identity and exposes guild tower-state/range QA controls.

No real backend, auth, persistence, payment verification, staff entitlement, GLOBAL server or release pipeline is claimed by M101.
