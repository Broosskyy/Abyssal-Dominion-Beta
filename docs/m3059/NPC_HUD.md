# Neutral entry regions and sea HUD

Karibische See (1-1, level 1) and Nordmeer (2-1, level 2) use neutral NPC patrols, including the monster. Proximity and target selection do not provoke attacks. Launching a valid player attack still enables retaliation. Escaping the engagement range clears retaliation. Schattengewässer retains hostile proximity behavior. This means lower progression regions, not the southern half of each chart.

Patrols now cover longer diamond circuits with coastline-checked alternative destinations. Four-view sprites use longer diagonal legs, initially matching the existing lateral heading where safe. Moving bodies reach their waypoints exactly instead of dropping the final two units and drifting off their authored diagonal. Pursuit replans less often. These are navigation corrections; they do not create missing sprite views.

The sea HUD has compact ship/target portrait cards, a narrower top strip, a unified lower action dock, persistent selected-ammunition state, actual cannon/harpoon tier, projectile damage and reload status. The weapons window uses live stock and upgrade data, selects real ammunition and links to harbor equipment. Target information distinguishes neutral, hostile and active combat. The minimap and quest tracker retain their existing gameplay functions. Shipyard text no longer displays production details.

Validation covers neutral proximity/selection, retaliation and disengagement across all three regions, actual diagonal travel, patrol extent, the existing simulation/progression/save checks and UI interactions at 1280x720, 844x390 and 720x405. Renderer evidence adds compact HUD and weapons-window captures. Distribution is a signed data release for native shell 305901, without a new APK. Physical NPC/HUD acceptance remains for the user's device.

Layout references inspected: Seafight sea chart and Battle of Sea official forum screenshots (https://forum.battleofsea.com/en/thread-43?page=5&scroll=ok). They guide compact edge displays and grouped actions; this change does not claim a finished replica of every interface.
