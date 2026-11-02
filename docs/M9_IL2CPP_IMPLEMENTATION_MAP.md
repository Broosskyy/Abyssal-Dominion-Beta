# M9 IL2CPP-to-Godot ship-selection map

| Recovered contract | Godot reconstruction | M9 status |
| --- | --- | --- |
| `UIShipSelector.ShowNextShip` | `PlayerShipRoster.preview_previous/preview_next` | active |
| `UIShipSelector.TryBuyShipOrSkin` | `PlayerShipRoster.buy_or_equip_preview` | active for ships; skins pending |
| `UIShipSelector.AddShipToPlayerShipList` | `owned_ship_ids` | active and persistent |
| `UIShipSelector.SelectShipForPlayer` | `_apply_selected_ship` | active |
| `UIShipSelector.AutoEquipWeapons` | existing cannon loadout retained across ship changes | local subset active |
| `PlayerShipSpawner.ConfigureBaseShip` | `ShipCatalog` plus `set_ship_base_stats` | active |
| `ShipData` movement/life/attack fields | Clipper, Barco and Chalupa profiles | local test balancing active |
| `PlayerInventory.CurrentShipEquipment` | `ShipWeapons`, upgrades and `PlayerShipRoster` save state | local subset active |
| PlayFab purchase and server selection RPCs | none | deliberately excluded |

The values in `ShipCatalog` are reconstruction test values inferred from ship roles and existing M8 balance. They are not claimed to be recovered original production values.
