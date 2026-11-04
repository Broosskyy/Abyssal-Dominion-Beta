# M97 — Core World/Combat Polish + Halloween UX

M97 deliberately returns part of the milestone to the permanent game world while keeping Halloween/admin useful.

CORE WORLD
- Two prepared irregular island slots are now active inside the existing one-accent island hero cap: cliff bridge for cliff/cove and sharp reef for long shoal.
- Haven's Reach replaces two existing dressing positions with a pirate sign and rope gantry. The inherited composition remains 30 modules; no object-count inflation.
- Normal wrecks replace one existing slot with a half-mast silhouette while preserving the three-object cap.
- Hostile P0 NPC fallbacks receive a replaceable pirate sail-patch visual slot; friendly coastal sloop remains clean/non-hostile.
- All additions remain visual-only and replacement-safe.

HALLOWEEN
- Active event now gets a compact quest strip: one quest on compact HUD, up to two on larger layouts.
- Completed quests are explicitly excluded from the active list and the existing claimed guard prevents repeated local currency reward.
- Event portal/wreck/boss labels render only at close range and consume no additional marker count.
- The boss joins the canonical world POI marker group.
- Event replacement visuals no longer intentionally stack a procedural monster body on top of a successful replacement.
- No live event reward authority is claimed.

ADMIN
- Asset browser now has category filtering plus text search.
- Spawned admin previews can be cleared as a group.
- Admin remains local development tooling only.

PERFORMANCE
- MobileLodController's global mesh LOD threshold is now applied during bootstrap.
- Event ships receive the quality-profile visibility pass.
- Existing harbor, wreck, island and marker caps remain intact.
