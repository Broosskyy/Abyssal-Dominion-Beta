# Complete SeeFight 3D reconstruction map

## Verified supplied-build facts

- Unity 2021.3.45f1, product version 2.6, IL2CPP x86_64
- GameAssembly and global metadata available for structural analysis
- 51,618 GameObjects
- 749 game-specific C# script types
- 660 meshes, 1,559 textures, 871 sprites and 740 materials
- 35 animation clips, 8 audio clips and 7,691 particle systems
- Photon Fusion/Realtime, PlayFab, Firebase Auth/Firestore and Cinemachine observed

## Godot subsystem mapping

| Original domain | Godot reconstruction | Status |
| --- | --- | --- |
| Ship movement | `CharacterBody3D` on X/Z plane | M0 implemented |
| Player input | Input Map + dynamic touch joystick | M0 implemented |
| Camera | controlled oblique `Camera3D` | M0 implemented |
| Cannons/projectiles | weapon Node + `Area3D` cannonballs | M0 implemented |
| Health/repair/destruction | state Node + sinking tween/respawn | M0 partial |
| NPC ships | state-driven broadside AI | M0 partial |
| HUD/nameplates | safe-area `Control` drawing | M0 partial |
| Water/wakes/VFX | animated water shader, wakes, muzzle/trail/impact effects | M1 implemented procedurally; GLB/VFX refinement remains |
| Ship prefab catalog | modular Visual/Sockets/Anchors/Collision contract | M1 implemented; licensed GLB replacement remains |
| Islands/ports | tropical/desert/snow Coast/Ground/Underside families | M1 islands implemented; ports remain M2 |
| Map grid/transitions | twelve data-driven sectors with boundary wrapping | M2 implemented |
| Minimap/global map | local entity map and 4×3 global sea map | M2 implemented |
| Ports/safe zones/spawns | modular docks, protected areas and checkpoints | M2 implemented |
| Target selection/action bar | target service + responsive HUD | M3 |
| Cannons/ammunition | resource catalogs and equipment rules | M3 |
| Abilities/consumables | Resources + cooldown/effect pipeline | M3 |
| NPC spawn/drop tables | server-ready deterministic catalogs | M3 |
| Inventory/equipment | authoritative item models | M4 |
| Shipyard/designs/decks | catalog, stats and visuals | M4 |
| Quests/achievements/ranks | configuration + progress services | M4 |
| Shops/currencies | secure ledger and catalog service | M5 |
| Auction | authoritative listing/settlement service | M5 |
| Accounts/cloud saves | new authentication/backend tenant | M6 |
| Multiplayer | new authoritative session backend | M6 |
| Chat/server regions | moderated chat and region service | M6 |
| Guilds/diplomacy/donations | social domain services | M7 |
| Guild islands/conquest/towers | synchronized world ownership | M7 |
| Arena/battleground/raids | matchmaking and match scenes | M7 |
| Release/performance | tiered graphics and device QA | M8 |

## Non-negotiable technical rules

- Real 3D presentation; movement and combat remain on horizontal X/Z water plane.
- No player-controlled height axis, free-orbit camera or third-person conversion.
- +Z bow/forward, -Z stern, +X starboard, -X port, +Y up.
- Ship pivots sit at the waterline center.
- GLB stores physical geometry/animation; Godot owns foam, wake, smoke, fire, trails, impacts and magic VFX.
- One gameplay codebase drives Web, Android, iOS and desktop.
- Reference-only extracted content is excluded from exports.
- Original client credentials and live service endpoints are never reused.
