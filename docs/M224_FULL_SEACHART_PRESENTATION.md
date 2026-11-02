# M224 — Full sea-chart presentation polish

M224 polishes the rectangular/full-screen sea chart without changing the locked round gameplay minimap. Current-world targets now use distinct marker silhouettes before relying on color: mission diamonds, harbor squares, boss rings, and compact event/loot/enemy markers. The selected target card exposes type, presentation status and player-relative distance.

The full chart also gains bounded presentation-only zoom/pan and a compact legend. These transforms never alter world coordinates, pathfinding, target authority, spawn state, combat values or progression. Existing runtime authorities remain unchanged: PlayerShipInput for navigation, TargetingSystem for hostile selection and TrackedQuestRuntime for mission tracking.
