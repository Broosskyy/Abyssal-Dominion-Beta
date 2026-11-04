# M107 — Reward Bundle Migration + PL1–5 Visual Hierarchy

- Added RewardBundleService as one seam for coins, XP, items and future entitlements.
- Mission completion, Daily, Weekly and local event milestone rewards now use reward bundles with legacy fallback.
- Beginner/Pirate-Trial coin+XP rewards use the same boundary.
- LOCAL applies bundles through existing service facades. Future TEST/GLOBAL requires one server-atomic transaction; M107 does not fake it.
- PL1–5 visual hierarchy is now explicit: one primary teaching card, contextual hints, safe-area/custom-HUD respect.
- Guild shield core/nodes gain mobile readability priorities while remaining visual-only and non-authoritative.
- P0 Asset Preview now exposes final-art checklist state per first-13 asset.
- Haven's Reach keeps its 30-module budget and now records hero/pirate/navigation hierarchy rather than adding objects.

No live backend, persistent guild capture or server reward authority is claimed.
