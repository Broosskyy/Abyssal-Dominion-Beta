# M37 — Equipment, Combat Supply & World Hook Foundation

## Scope
M37 implements the roadmap foundations for Craft/Upgrade Basics + Equipment Economy, Black Powder/Armor Plates, Shield Foundation, Support Weapon contracts, and Guild ID/contribution/world hooks.

## Runtime prototype
- Black Powder can be enabled and consumes exactly one unit only after a valid cannon salvo passes ammo/target/reload gates. Local prototype multiplier is data-driven.
- Armor Plates can be enabled and consume one unit only when positive incoming damage reaches the player. Local prototype reduction is data-driven.
- Player shield is now a separate resource in ShipHealth; incoming damage is routed shield -> armor/hull. Hull repair does not restore shield.
- Shield state is saved locally for the offline prototype.
- Arsenal exposes supply toggles and three cheap harbor crafting recipes using common prototype materials.
- Normal salvage now also yields a small common material unit; admiral salvage yields two. Exact amounts are local prototype tuning.

## Contracts
- `combat_support_contracts.json`: ShipSupply, Shield, Healing Weapon/Ammo, Repair/Shield Item, Support Contribution, Defense Stack, Supply Loadout definitions.
- `equipment_economy.json`: cannon/harpoon/deck/module/consumable/event/legendary crafting families and safe upgrade rules.
- `guild_world_hooks.json`: nullable Guild/Member/Alliance IDs and contribution/world-event envelopes only. No guild persistence/rewards.

## Authority boundary
All values are local prototype tuning. Live item ownership, rewards, guild membership/contribution and competitive state remain server-authoritative targets. No fake MMO backend was added.

## Validation
Static source/data checks were run in this environment. Godot 4.7.2 native parser/device execution was not available here, so Android/native acceptance remains required.
