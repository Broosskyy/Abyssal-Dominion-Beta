# M223 — Full sea-chart interaction

M223 turns the already locked rectangular/full-screen sea chart into a concise current-sector planning surface while keeping the normal gameplay minimap circular. The chart defaults to the active named sea map and shows only targets that actually exist in that world.

The current-sector detail view supports compact filters for mission, harbor, boss, event and loot. Selecting a marker opens one context card rather than a second menu tree. Actions delegate to the existing authorities: `TrackedQuestRuntime` for objective tracking, `TargetingSystem` for hostile selection, and `PlayerShipInput.set_navigation_world_target` for sailing. M223 does not implement pathfinding, teleportation, combat values or spawn logic.

The previous region/map overview remains a secondary chart view. Mobile, web and desktop receive the same world targets and actions; only available dimensions/touch spacing are responsive.
