# M9 – Harbor ship selector and persistent roster

## Outcome

M9 reconstructs the offline portion of SeeFight's harbor ship-selection loop. The recovered Clipper, Barco and Chalupa families are no longer fixed debug visuals: each is now a selectable player vessel with its own hull, armor, speed, acceleration, turning and damage profile.

## Supplied-build evidence used

The supplied IL2CPP metadata exposes these contracts without original method bodies:

- `Code.Demo.ShipSelection.UIShipSelector`: `ShowNextShip`, `TryBuyShipOrSkin`, `AddShipToPlayerShipList`, `SelectShipForPlayer`, `AutoEquipWeapons` and `TryLeftPort`.
- `ShipData`: `Nameship`, `Id_Visual`, `MovementSpeed`, `Life`, `AttackPower`, `FireRate`, `WeaponsRange`, `Capabilitymax` and `Description`.
- `Code.Core.Ship.Player.PlayerShipSpawner`: `SpawnShip`, `ConfigureBaseShip` and `GetShipSkinSailCount`.
- `Code.Core.PlayerInventory.PlayerInventory` and `ShipEquipment`: owned weapons, current equipment, ship class and maximum cannon contracts.

M9 maps only the locally testable ship-selection, purchase, equip and persistence subset. It does not recreate PlayFab purchases, server RPCs or original balancing data.

## Implemented

- `ShipCatalog` with three recovered visual families and explicit local test statistics.
- `PlayerShipRoster` with owned ships, harbor preview, coin purchase, equip and save/load state.
- Live visual replacement through `ReferenceVisualAdapter.apply_profile()`.
- Live hull, armor, speed, acceleration, turn-rate and base-damage changes while retaining purchased upgrades.
- Expanded shipyard HUD with ship identity, role, statistics, price/equip state and owned count.
- Desktop keyboard/controller and Mobile/Web touch paths for previous, buy/equip, next and close.
- Existing upgrade shop remains available below the new ship selector.

## Controls

- Desktop: `[` / `]` browse ships, `Enter` buys or equips, `1`/`2`/`3` buy upgrades, `G` closes the shipyard.
- Controller: left/right stick buttons browse, right shoulder buys/equips; existing shop actions remain mapped.
- Touch: a dedicated ship row provides previous, buy/equip, next and close; the lower row retains hull/cannon/sail upgrades.

## Validation boundary

Static contracts, persistence wiring, asset profiles and all six platform presets are validated here. A Godot 4.7.2 executable is still unavailable in this environment, so model orientation, waterline and UI hit areas require a genuine runtime pass on the Godot-capable machine.

## Legal boundary

Recovered files remain private test references. Replace or license them before public or commercial distribution.
