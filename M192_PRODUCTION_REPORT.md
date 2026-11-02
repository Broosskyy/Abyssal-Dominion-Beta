# M192 — Chart Navigation, Unit Overlap & World Scale

- Named charts remain the player-facing map identity; SeaFight-style `1-1 / 2-1` prefixes were removed from display names. Stable `SECTOR-xxx` IDs and legacy coordinates remain internal compatibility data only.
- Runtime chart size increased from prototype 72×72 to 360×360 world units, with islands/harbors/encounters distributed over the usable chart extent.
- Player HUD coordinates are positive chart X/Y, hiding Godot X/Z implementation coordinates.
- Islands are hard movement obstacles on a dedicated land collision layer. Tap-to-Sail dynamically selects a short detour around blocking land while retaining the original final target.
- Ships, NPC ships, monsters, bosses and players share non-blocking unit movement: they may overlap and never force route avoidance. Combat targeting remains separate.
- Loot remains non-blocking.
