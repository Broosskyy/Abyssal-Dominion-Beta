# M77 — Beginner Progression Reconciliation + Reward-Only Ship Integrity

M77 closes the starter-stage discrepancy and hardens reward-only ship acquisition.

- Canonical beginner rewards are now: Small at start, Medium/Clipper after beginner assignment 2, Large/Chalupa after assignment 3.
- Beginner save schema advances to v2.
- Existing v1 saves are grandfathered: a v1 profile entitled to the old stage-1 Clipper or stage-5 Chalupa keeps that entitlement. Already-owned ships are never removed.
- Pre-version M31 `trial_passed` still maps to one completed assignment and does not fabricate the new PL2 reward.
- `buy_or_equip_preview()` is explicitly reward-only for unowned starters and `ship_main_*` designs. Eligibility is not ownership and Gold cannot bypass acquisition.
- Added acquisition-class/message helpers so the shipyard no longer describes unowned main designs with beginner unlock copy.
- Haven's Reach gets a first-dock service presentation card using the existing service icon slots; harbor systems remain service authority.
- Added six more stable P0 world/harbor/salvage slots.

This is a local source/save migration only. No server authority is claimed. Native Godot 4.7.2 and Android device QA are still pending.
