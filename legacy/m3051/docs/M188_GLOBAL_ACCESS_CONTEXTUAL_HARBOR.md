# M188 · Global Access & Contextual Harbor Entry

M188 closes the remaining UI/routing contradictions after M187. The physical harbor is still a local world POI, while Shipyard, Equipment, ordinary Quests and the other locked meta systems remain globally reachable.

## Runtime changes

- The global **Shipyard** action now opens the real `ShipyardPanel`; it no longer redirects to the harbor journal.
- The combat-side **Target** utility is contextual only when the player is inside a real `PortInteraction` range: it activates that port and then opens the local harbor page. At sea it continues to cycle targets normally.
- The legacy full-HUD shipyard overlay no longer calls itself `HARBOR SHIPYARD`.
- Equipment presentation no longer visually implies that ordinary loadout access depends on port state.
- The mixed legacy `HarborEquipmentPanel` remains for compatibility, but its player-facing title now explicitly distinguishes global equipment from local services.

## Boundary

Only explicit local harbor services and opt-in harbor quests require proximity. No normal quest, owned-ship selection, global equipment/loadout access, event, guild, ranking, progression or itemshop route is converted into harbor-only content.

## QA boundary

Static regression and JSON validation are performed in this package. Native Godot/device acceptance remains a separate runtime gate.
