# M187 Production Report

Status: `M187_HARBOR_LOCAL_SERVICE_BOUNDARY_STATIC_VERIFIED`

M187 corrects the harbor boundary against Masterkonzept V3.8 and the locked HUD/world references. Harbor is a physical world POI for explicitly local content, not a gate in front of the global game. Ships/shipyard, equipment/loadouts, ordinary quests, events, guild, rankings, progression and itemshop remain global. Docking no longer auto-opens the global shop. Owned ships can be equipped through the global shipyard without harbor proximity, and standard ship upgrades are no longer harbor-gated.

Local harbor scope remains opt-in: repair, local supply/market, regional vendor/crafting, harbor NPCs, explicitly tagged harbor quests and harbor event hooks. Ordinary quests are never converted into harbor quests. No fake quest, offer, entitlement, price, route or ownership state is introduced.

Native Godot/device testing remains open because the required runtime is not installed in this environment.
