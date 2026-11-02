# M11 — Arsenal, ammunition and original interface assets

## Delivered

- Native Godot arsenal panel, opened with **I**, controller left-stick click, or the on-screen **ARSENAL** button. Scrollable controls, 48-pixel minimum button height, keyboard/controller focus, safe-area layout and input blocking while open. The world is not paused: opening inventory at sea is not combat protection.
- Persistent stocks for iron, explosive and chain ammunition, emergency repairs and speed stones. Ammo selection is shared between the arsenal, X key and weapon module.
- Each successful player broadside spends one round per projectile. No partial volleys. Cooldown, safe-zone, sunk, shop, map, modal and insufficient-stock rejection happen before spending ammunition or starting reload/audio.
- Three starting cannons, up to six owned. Three base firing slots, plus up to three deck upgrades **per owned hull**. Active volley size is the smaller of owned cannon count and hull capacity. The six-projectile ceiling is deliberate mobile/Web test tuning; NPCs retain their previous three-shot implementation without player inventory.
- Harbor purchases validate actual nearby-port ownership and living state, not just whether a menu was once opened. Unaffordable/full-stock purchases do not spend coins. New inventory is part of the existing checksummed save/backup and marks autosave dirty.
- Old repair-charge saves migrate; new inventory stock takes precedence. Inventory imports reject incorrect types and clamp quantities/capacity. This validation does not imply every legacy save field is now fuzz-hardened.
- Repair stock is spent only when healing succeeds. Speed stones require stock and a ready cooldown. Temporary boost and chain slow now modify effective speed without rewriting the progression-owned base speed. Repeated chain hits refresh one modifier rather than stacking indefinitely. Respawn clears modifiers.
- Existing free harbor repair/restock behavior is retained as a test convenience: at least 120 iron rounds and three repair kits, without deleting purchased surplus. There is no original-economy fidelity claim.

## Original evidence and interpretation

Source: supplied IL2CPP metadata, `docs/il2cpp/relevant_game_types.csv` and the accompanying metadata skeleton. These records contain signatures and names, not original method implementations.

| Original evidence | M11 implementation | Not recovered |
| --- | --- | --- |
| `ShipWeapons.SetItemProviders`, `SetCurrentAmmo`, `_ammoProvider` | Player ammunition store and selection | Original consumption math and ammo IDs/stats |
| `ShipWeapons.SetMaxProjectileCount`, `_maxProjectileCountByDecks` | Deck-limited projectile count | Original capacities and volleys |
| `ShipEquipment.ShipMaxCannons`, `CurrentDeckData`, `SetWeaponsEquipped` | Owned cannon count and per-hull deck levels | Full typed cannon inventory, castles and equipment rules |
| `UIDeckShop.TryBuy`, `GetGoldDeckPrice`, `GetDiamondDeckPrice` | Local coin deck purchase | Production price lists and diamond economy |
| `PlayerAbilitiesController.CanUseAbility`, `SetConsumableProvider` | Stock-backed repair/boost and cooldown | Original effects, durations and server validation |
| `ConsumableItemIds.SpeedStone01`, `EmergencyRepair` | Speed-stone and repair test items | Authoritative ID-to-art/stat assignment |

All quantities, prices, effects and durations below are **inferred local test balancing**, not recovered production settings:

| Item | Initial stock | Purchase | Effect |
| --- | ---: | --- | --- |
| Iron Shot | 120 | 60 for 30 coins | Existing M10 iron damage profile |
| Explosive Shot | 30 | 30 for 60 coins | Existing M10 explosive damage profile |
| Chain Shot | 30 | 30 for 45 coins | Existing M10 chain damage/slow profile; no verified original icon |
| Emergency Repair | 3 | 1 for 40 coins | Up to 240 hull restored |
| Speed Stone | 3 | 1 for 35 coins | ×1.45 speed for 3.5 seconds; 12-second cooldown |
| Cannon | 3 | 1 for 150 coins | Additional owned firing unit, up to six |
| Deck | 0 per hull | 180 / 300 / 420 coins | One extra slot per level, up to three |

The existing three cannon *profiles* remain freely switchable from M10. M11 adds total cannon ownership, not a production-faithful inventory of independently owned cannon types. Ships/islands remain the M8–M10 recovered families; **no new ship geometry was added in M11**.

## Newly decoded assets

These are original Texture2D pixels decoded to PNG, not generated approximations. They were read again from the supplied Unity files. `docs/m11_recovered_icons.json` records dimensions, output hashes and identity. `tools/recover_m11_icons.py` reproduces extraction with UnityPy 1.25.3.

| Source | Unity Path ID | Original name | Use |
| --- | ---: | --- | --- |
| sharedassets2.assets | 237 | IronBalls | Iron ammunition row |
| sharedassets2.assets | 261 | Explosive_Ammunition | Explosive ammunition row |
| sharedassets2.assets | 392 | Swiftstone | Speed-stone row; semantic mapping inferred |
| sharedassets2.assets | 723 | Emergency_Repairs | Repair row |
| sharedassets2.assets | 732 | smallPremumCannon | Cannon purchase button |
| sharedassets2.assets | 346 | woodDeck | Deck purchase button |
| sharedassets2.assets | 660 | Shield2 | Recovered, not yet an implemented ability |
| resources.assets | 399 | Gunpowder | Recovered, not yet an implemented ability |

`sharedassets2.assets:841` (`Black_Gunpowder`) has no usable image data. The separately identified `resources.assets:399` image is not represented as that missing texture. Chain Shot stays text-only rather than receiving an unverified icon. The six in-use images are test-export assets, not production-licensed replacements. The other two are included for further reconstruction.

## Verification

- Godot **4.5.1.stable.official.f62fdbde1**, real engine execution with a headless/dummy renderer.
- **152/152 assertions passed:** 86 M10 regression checks plus 66 M11 checks. Import and both behavior logs contain no engine errors.
- M11 checks include atomic ammo consumption, actual projectile creation/counts, purchase rejection, ship-specific decks, supply caps, sunk/modal guards, repair/boost behavior, overlapping effects, malformed inventory data, save migration, all eight asset imports and panel containment at 1280×720, 844×390 and 390×844 viewport sizes.
- GDScript lint passes. Existing platform configuration checks (19/19) and M10 data/source checks (16/16) pass separately; these are not device tests.
- `tools/run_engine_checks.py` defaults to M11, also runs M10 regression tests and rejects logged errors even when exit code is zero. Tests never read/write the user's gameplay save.

Reproduce:

```sh
python3 tools/run_engine_checks.py --engine /absolute/path/to/godot
python3 tools/validate_platform_contract.py
python3 tools/validate_m10_encounters.py
python3 tools/recover_m11_icons.py '/path/to/extracted/SeeFight 3D_Data'
```

**Not verified:** rendered game appearance, target Godot 4.7.2, physical touch/gamepad behavior, Android/iOS/Web/Desktop exports, device performance, and match to an original-running client. UI bounds tests are not visual screenshot approval. No new gameplay screenshot is claimed.

## Remaining reconstruction work

1. Recover more ship families and resolve original renderer/material/texture links, attachments, scales and pivots. Compare actual rendered views against an original client.
2. Recover usable serialized item/config values where present; do not substitute metadata names for method bodies or missing backend data.
3. Extend consumables, cannon-type ownership, assistants, castles, islands/towers and quests using source evidence, not a presumed full server reconstruction.
4. Validate water/shaders, touch-safe HUD, collisions, navigation and memory/performance on real Web and mobile targets; build and test signed platform packages separately.
5. Original multiplayer, accounts, premium economy, guild systems and complete NPC catalog remain absent. No original credentials or services are used.

This remains a functional offline reconstruction prototype, **not a nearly finished 1:1 copy**. Recovered original assets must be licensed or replaced before distribution.
