# M108 — Reward Receipts + Teaching Runtime + Guild Objective Marker

- RewardBundleService now keeps a bounded 64-entry memory-only local QA receipt history.
- Same-session duplicate reward IDs return the first local receipt instead of applying the reward twice.
- Empty reward IDs are rejected; local premium entitlement grants remain blocked.
- This is not a persistent or server ledger.
- BeginnerTeachingRuntime enforces one primary teaching surface: an active Beginner objective strip suppresses the overlapping first-session guide.
- Guild shield core/nodes now reuse the existing `world_poi_markers` pipeline and marker budget. Their node metadata can override fallback catalog priority for readability.
- P0 first-13 now exports a machine-readable replacement batch with expected final paths and acceptance checks.
- MobileLodController uses the M101 mobile graphics profile as primary nameplate-distance source; whole NPC hull visibility is still never driven by shadow-distance hints.
- No new world-marker renderer or world-node budget was added.
- V3.7 was searched again in the Library for M108 but was still not available, so no V3.7-only clauses were invented.
