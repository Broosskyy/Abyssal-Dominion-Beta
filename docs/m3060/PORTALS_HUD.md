# Portal crossing and reference-based nautical HUD

The supplied UI references show a dark gold icon toolbar, framed coordinate minimap, a large round fire control on the right, circular item/weapon slots and contextual ammunition lists. This update implements those structures as live Godot controls. It retains the existing 2D gameplay and installed Android shell.

## Portal defect and resulting flow

Previously, tapping a portal only set a normal sailing destination. Entering the gate required an unrelated interaction button after arrival; map-menu navigation likewise set only a course. The new request binds the route to the intended destination. Reaching the gate completes the transition, clears transient combat references, updates the camera and saves the new region. Touching the world portal, selecting its map action and choosing its minimap marker share this flow.

Level requirements are checked before queuing the crossing and displayed in the status/system area. A valid queued crossing waits for six seconds without damage. A new water course, explicit cancel, docking, repair or sinking clears the transient order. Arrival remains at the existing safe map start and cannot bounce immediately through a return gate. NPC navigation and the neutral entry-region policy remain unchanged.

The simulation regression sails actual routes out and back through all three regions, rather than teleporting onto a trigger. UI checks send a touch press/release to the rendered portal and verify arrival, camera synchronization and save restoration. HUD touches are excluded from world movement handling.

## Functional UI

- Six gold symbol navigation cells: Ship, Harbor/Shipyard, Quests, Maps, Supplies and Menu. Each opens an existing or live-data-backed panel.
- Ship and target portraits/health, actual gold/captain progress, a framed minimap with coordinates and moving markers.
- Round fire, repair and ammunition-selection controls; selected-ammunition quick slots with actual stock; lower HP/XP bars.
- Contextual ammunition list with real damage, purpose, stock, current selection and working load actions. No invented infinite stock or unimplemented powers.
- System and Quest tabs using real local messages and progression. This does not add online chat, guilds or a public server.
- Consistent framed lists, scrollable content and compact/wide layout coverage. Ten authored SVG symbols are stored and checksum-verified alongside the existing artwork provenance.

Runtime evidence captures 1280x720, 844x390, 720x405 and the phone-like 1560x720 aspect. Separate before/after gate images and a receipt record a touch-queued crossing. These are actual renderer fixtures, not mockup composites or a claim of physical-device acceptance for this new revision. The reference mockups remain direction for further world art; this update does not recreate their 3D ships, water or islands.

Distribution is a signed data package for native version 305901. Protected engine/native/updater files have not changed, so no new APK is required.
