# M8 IL2CPP-to-Godot implementation map

The mapping below is based on the supplied IL2CPP metadata analysis. It describes functional reconstruction, not recovered original C# method bodies.

| Recovered SeeFight type | Reconstructed Godot implementation | M8 status |
| --- | --- | --- |
| `Code.Core.Ship.MovementComponent` | `ship_motor.gd` | acceleration, turning, speed and movement lock foundation active |
| `Code.Core.Common.Input.PlayerInputManager` | `player_input.gd` | keyboard, controller, touch joystick, pinch zoom and target-position sailing active |
| `Code.Core.Ship.Player.ShipInputNetworked` | `player_input.gd` | local input contract active; network replication intentionally absent |
| `Code.Core.Ship.Weapons.ShipWeapons` | `ship_weapons.gd` | target-aware port/starboard broadside, reload and loadout active |
| `Code.Core.Ship.Ship_Fx.ShipWeaponsEffects` | `muzzle_flash.gd`, `impact_fx.gd`, recovered cannon audio | active |
| `Code.Core.Ship.Weapons.NetworkDamageInfo` | `cannon_projectile.gd` | damage, critical multiplier, armor pierce and slow active |
| `Code.Core.Ship.Health.ShipHealth` | `ship_health.gd` | hull, armor, attacker damage, sinking and respawn active |
| `Code.Core.Ship.Health.ShipRepairModule` | `player_input.gd`, `ship_health.gd` | limited repair charges active |
| `Code.Core.Ship.NPC.NpcShip` | `enemy_ship_ai.gd` | detection, chase, broadside alignment and archetypes active |
| `Code.Core.Ship.ShipMapMover` | `world_map_system.gd` | map borders, sector changes and port state active |
| `Code.Core.Map.MapLimits` | `world_map_system.gd` | 4×3 deterministic map grid active |
| `Code.Core.Ship.ShipVisuals` | `reference_visual_adapter.gd` | recovered Clipper, Barco and Chalupa runtime visuals active |
| `Code.Demo.UI.UIShipInGame` | `game_hud.gd` | names, health bars, target status, map and safe-zone feedback active |
| `Code.Core.PlayerInventory.PlayerInventory` | `combat_catalog.gd`, `player_progression.gd` | local cannon/ammo/upgrades subset active |
| `Code.Core.PlayerInventory.ShipEquipment` | `combat_catalog.gd`, harbor shipyard | hull/cannon/sail equipment subset active |
| `Code.Core.Ship.Player.PlayerAbilitiesController` | `player_input.gd` | timed speed ability and cooldown active |
| `Code.Networking.ServerStuff.MapServer.WorldRewardsGiver` | `loot_pickup.gd`, `player_progression.gd` | XP, coins and repair loot active |
| `Code.Core.Quests.PlayerQuestsHandler` | `mission_system.gd` | rotating sink/loot/harbor mission subset active |
| `Code.Demo.ShipSelection.UIShipSelector` | `player_ship_roster.gd`, shipyard HUD and recovered visual profiles | M9 adds persistent selection, purchase and equip for three ship families |
| `Code.Core.Ship.NPC.GuildIslandController` | recovered islands and harbor/safe-zone foundation | visuals active; guild ownership/towers pending |
| PlayFab, Firestore, Fusion and server types | none | deliberately not connected; local/offline reconstruction only |

## Highest-priority remaining systems

1. Full ship catalog and selectable ship/skin loadouts.
2. NPC/admiral spawn tables and map-specific rewards.
3. Deck-dependent projectile count, ammunition quantities and consumables.
4. Island towers, conquest and guild ownership as an offline simulation.
5. Expanded quest definitions, achievements, ranks and inventory screens.
6. Arena/Battleground modes after the normal sea loop is visually stable.
