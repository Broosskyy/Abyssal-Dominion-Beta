# M106 — Caller Migration + ServiceLocator + P0/World Polish

- Added a real ServiceLocator node configured at gameplay bootstrap.
- Loot coin rewards and salvage-material writes now use Wallet/Inventory services when available, with legacy local fallback.
- Encounter XP now uses ProgressionService when available, preserving legacy fallback.
- TEST/GLOBAL remain fail-closed because no server adapter exists.
- Haven's Reach replaces existing dressing with pirate lantern/rope-post variants without increasing its 30-module budget.
- Cliff/Cove secondary detail now uses the irregular rock-spur replacement under the unchanged one-detail cap.
- P0 final-art checklist covers all 13 first-wave assets and keeps native status explicit.
- Existing mobile HUD customization, guild-island presentation and local Halloween/Admin QA are preserved.

No live backend/server authority is claimed.
