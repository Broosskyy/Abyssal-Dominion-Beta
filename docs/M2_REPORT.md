# M2 — World navigation

## Result

M2 reconstructs the supplied build's room-based sea-map structure as a Godot-native data-driven world. The implementation preserves X/Z-plane gameplay and controlled camera behavior while allowing the player to sail through connected map boundaries.

## Global sea grid

| Coordinate | Map | Biome | Harbor |
| --- | --- | --- | --- |
| 1-1 | Novice Tide | Tropical | Haven's Reach |
| 2-1 | Green Frontier | Tropical | — |
| 3-1 | Port Royale | Tropical | Port Royale |
| 4-1 | Drake Passage | Desert | — |
| 1-2 | Ember Coast | Desert | Ember Anchorage |
| 2-2 | Amazigh Sahil | Desert | — |
| 3-2 | Dominus Regina | Tropical | Regina Harbor |
| 4-2 | Corsair Expanse | Tropical | — |
| 5-1 | Frozen Reach | Snow | Frosthaven |
| 5-2 | Icebreaker Sea | Snow | — |
| 6-1 | El Refugio | Snow | Refugio |
| 6-2 | Leviathan Gate | Snow | — |

The visual grid is 4×3; the displayed map IDs preserve the supplied build's two-part naming style.

## Implemented navigation systems

- Data-driven map definitions with name, biome, harbor and recommended level
- Bidirectional north/south/east/west boundary transitions
- Player position wrapping at valid transitions
- Hard world-edge protection where no neighboring sector exists
- Transition cooldown and map-name banner
- Deterministic island layout per sector
- Enemy repositioning and respawn when entering a new map
- Tropical, desert and snow sector styling

## Ports and safe zones

- Modular pier and twin harbor lights
- Visible safe-zone ring
- Area-based player/ship detection
- Cannon firing blocked inside safe zones
- Incoming damage ignored inside safe zones
- NPC attacks suspended against protected players
- Harbor checkpoint updates the player's respawn position

## Map UI

- Current map name and local X/Z coordinates in the HUD
- Local minimap showing islands, ports, enemies and player
- Full 4×3 global sea map with current-sector highlight
- Harbor names and recommended levels
- Desktop toggle with M
- Dedicated top-right mobile MAP touch region
- Safe-area-aware placement

## Remaining world work

Later milestones can replace procedural sector composition with authored map manifests, add port menus, raid entrances, guild islands, event maps, weather, loot and monsters without changing the navigation contract.
