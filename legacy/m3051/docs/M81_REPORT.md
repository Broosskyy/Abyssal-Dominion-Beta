# M81 — PL1–5 Visual Closure + Migration / Reward Integrity

M81 closes another important correctness gap while continuing visible world polish.

- Fixed a migration edge case introduced during M77 reconciliation: only explicit `beginner_version == 1` saves receive the old stage-1/stage-5 starter grandfathering. Pre-version M31 `trial_passed` saves still map to one completed assignment but no longer fabricate a legacy Clipper entitlement.
- Legacy migration now emits `roster_changed` only when it actually adds an entitlement.
- Shipyard preview/status now uses the same `acquisition_message()` path as equip attempts, keeping reward-only messaging consistent and ensuring eligibility is never presented as ownership.
- Mobile decorative visibility is centralized through `MobilePresentationBudget`; island dressing, wreck context and monster-area context use the same compact-phone / phone / tablet-desktop distance budget.
- Haven's Reach now includes mooring posts and a bell as stable visual-only slots.
- Wreck landmarks now use hull-section and rudder slots while staying capped at three context objects.
- Monster warning zones use warning-flag and reef-line slots without increasing the existing context-object cap.
- Added six more P0 replacement slots.

No backend/server authority, balance changes, quest rewards or auto-navigation were introduced. Native Godot 4.7.2 parser/runtime and representative Android device QA are still required.
