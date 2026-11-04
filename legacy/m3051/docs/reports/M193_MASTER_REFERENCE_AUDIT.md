# M193 — Master Concept / Reference Audit

## Audit rule
This is a **static source audit**, not a claim that every feature has passed native Godot/Android playtesting. `FOUNDATION` means the code/data path exists and milestone regression coverage is present; `PARTIAL` means the system exists but still needs depth, content, visual replacement, networking or device QA; `PLACEHOLDER` means the runtime intentionally uses replaceable/procedural/production-placeholder visuals; `MISSING/DEFERRED` means the master feature is not yet production-complete.

The binding direction remains: the sea chart is the heart of play; mobile ship movement is Tap-to-Sail; the camera control never steers the ship; combat is target + correct weapon + range + reload; player-facing maps use region/chart names rather than 1/1 numbering.

## A. Core sea gameplay
| Area | M193 source status | Production assessment |
|---|---|---|
| Tap-to-Sail | FOUNDATION | Implemented; native touch feel still needs device QA. |
| Camera pan / pinch / recenter | FOUNDATION | Separate from ship steering; device QA still required. |
| Named charts + transitions | FOUNDATION | Stable internal sector IDs remain hidden compatibility data. |
| Chart size / coordinates | FOUNDATION | 360×360 world units; positive player X/Y display. Final travel-time tuning remains balance work. |
| Island collision | FOUNDATION | Land blocks movement; M192 detour steering preserves final tap target. Needs stress QA on complex island clusters. |
| Ship/NPC/monster/player overlap | FOUNDATION | Unit movement does not block other units. Combat collision/targeting remains separate. |
| Water | PARTIAL / PLACEHOLDER | Shader/runtime work exists and has been polished, but final master-reference water quality is not signed off. |
| Islands/coasts | PARTIAL / PLACEHOLDER | Procedural silhouettes, coast layer and dressing exist; final authored island GLBs are still replacement work. |
| World density | PARTIAL → IMPROVED M193 | 8 identical island composition slots on every platform; M195 adds deterministic macro anchors and full-chart POI distribution. Native visual-density QA still required. |
| Harbors | PARTIAL / PLACEHOLDER | Physical world POI + local interaction exists. Final harbor art/content variety is not complete. |
| Minimap / coordinates | FOUNDATION | Named map identity and coordinates exist; final readability/device tuning remains. |

## B. Combat, enemies and loot
| Area | Status | Assessment |
|---|---|---|
| Target selection / cycling | FOUNDATION | Exists for universal target-combat flow. |
| Manual cannon attack / reload / range | FOUNDATION | Core path exists. Final combat feel/balance pending playtests. |
| Harpoon-vs-monster rule | FOUNDATION/PARTIAL | Architecture/content path exists; full monster roster and bespoke mechanics are not final. |
| Projectiles / hit feedback / VFX | PARTIAL | Functional visual paths exist; final production VFX library and polish remain. |
| NPC AI | FOUNDATION/PARTIAL | Patrol/pursue/engage/return family exists; advanced archetype differentiation remains incomplete. |
| Admirals / bosses | PARTIAL | Spawn/progression/mechanics foundations exist; final boss roster/phases/content incomplete. |
| Monsters | PARTIAL / PLACEHOLDER | Runtime monster paths exist, but final rigs/models/animations and broad regional roster are production work. |
| Loot drops / pickup | FOUNDATION/PARTIAL | Loot runtime exists; final loot models are largely production placeholders and pickup UX still needs device QA. |
| Sink/respawn feedback | FOUNDATION/PARTIAL | Explicit sink/respawn/protection logic exists after prior fixes; must be retested natively. |
| Auto attack | PARTIAL | System direction exists; unlock/economy/live authority needs final product integration. |

## C. HUD / UX against visual references
| Area | Status | Assessment |
|---|---|---|
| Large primary attack button | FOUNDATION | Preserved as primary lower-right combat action. |
| Quick actions | FOUNDATION/PARTIAL | Present; final iconography, spacing and device-specific ergonomics still require visual QA. |
| Camera joystick lower-left | FOUNDATION | Camera-only design lock retained. |
| Target header / health presentation | PARTIAL | Runtime UI exists; final visual fidelity to master mockups not yet signed off. |
| Quest tracking + world/rim marker | FOUNDATION/PARTIAL | Track/untrack/navigation and prioritized marker paths exist; needs live visual QA across aspect ratios. |
| Menu/Command Deck | FOUNDATION/PARTIAL | Routing and global/local access policy exist; many panels remain prototype/functional UI rather than final premium UI. |
| Navy/gold Abyssal UI | PARTIAL / PLACEHOLDER | Theme foundation exists; final production icons, frames, typography and panel art remain incomplete. |
| Responsive mobile safe areas | FOUNDATION/PARTIAL | Safety/layout systems exist; broad physical-device matrix still pending. |

## D. Meta / progression / MMO systems
| System family | Status | Notes |
|---|---|---|
| Pirate / World / per-ship progression | FOUNDATION/PARTIAL | Data/runtime foundations exist; final balance and content curve not final. |
| Fleet / ship roster / shipyard | FOUNDATION/PARTIAL | Global access corrected in M188. Final 3 starter + 20 main-series production ship assets are not complete. |
| Equipment / loadouts / ammo / items | FOUNDATION/PARTIAL | Functional foundations and catalogs exist; final breadth/balance/art incomplete. |
| Talents / mastery / deeper builds | PARTIAL | Framework/panels/data exist; production-depth and tuning remain. |
| Quests | FOUNDATION/PARTIAL | Global quest/tracking runtime exists; local harbor-only special quests remain content-driven special cases. Full story/content volume missing. |
| Bonus maps | FOUNDATION/PARTIAL | Instance/wave foundations exist; full tiers/modifiers/reward/content library incomplete. |
| Events / LiveOps | FOUNDATION/PARTIAL | Data-driven event foundations exist; production event catalog and server operations remain. |
| Gilds / guild islands / wars | PARTIAL | Substantial foundations exist; real multiplayer ownership/war authority and full UX remain. |
| PvP / honor / ranked | PARTIAL | Systems/data foundations exist; real online matchmaking/authority/anti-abuse remain. |
| Rankings / achievements / collections | PARTIAL | Meta foundations exist; production backend/live datasets and complete UX remain. |
| Economy / bazaar / crafting | PARTIAL | Foundations exist; live authoritative economy, full item market and balancing remain. |
| Payment / season systems | PARTIAL/DEFERRED LIVE | Architecture/config concepts exist; no claim of live payment integration. |
| Admin / no-code content | FOUNDATION/PARTIAL | Broad data-driven/admin architecture exists; production backend/security/deployment remains outside local prototype completeness. |
| Online MMO authority / crossplay | DEFERRED | Master requires server-authoritative movement/combat/economy. Local source is not a finished production MMO backend. |

## E. Asset reality check
- `assets/production_placeholders/` is intentionally extensive and must **not** be mistaken for final art.
- Runtime code marks many ships, monsters, islands, harbors, loot and world assets `placeholder_replacement_ready` / `production_slot` so final GLBs can replace them without rewriting gameplay.
- Final authored 3D production coverage is therefore still one of the largest remaining gaps: ships, NPC families, monsters, islands, harbors, loot, structures, props and many VFX/UI elements.
- Existing procedural/fallback visuals are useful for mechanics and composition testing, not final visual acceptance.

## F. Highest-priority gaps after M193
1. Native Android/Godot regression pass for M177–M193: steering, island detours, overlap, sink/respawn, loot pickup, quest navigation, menu touch safety.
2. Final visual replacement pipeline: starter ships first, then main ship series, NPCs/monsters/islands/harbors/loot using the existing production slots.
3. World composition depth: authored route grammar, regional POI sets, encounter territories, hidden/exploration spaces, chart-specific identity rather than only seeded distribution.
4. Combat feedback polish: final muzzle/projectile/impact/water VFX, damage readability, monster attack telegraphs and boss phase presentation.
5. HUD finalization against the master mockups on real phone aspect ratios; remove remaining prototype-looking panels/icons.
6. Content depth: real quest chains, harbor-special quests, trials, bonusmap tiers/modifiers, event packs, regional NPC/monster rosters and reward tables.
7. Multiplayer authority/backend: server-authoritative movement/combat/loot/economy/PvP/guild/ranking/payment before any production-online claim.

## M195 audit refresh
Cross-platform world parity is now locked: gameplay geometry/content must not vary by device. M195 also removes the old central POI clustering and introduces deterministic macro chart anchors. Placeholder/final-art and native QA conclusions below remain unchanged.

## M193 conclusion
The project is **well beyond a blank prototype in system breadth**, but it is **not visually or online-production complete**. The strongest current layer is the broad gameplay/meta foundation and data-driven architecture. The largest deficits are final assets, native-device QA, content volume/depth, visual-reference fidelity and true server-authoritative MMO operation. Future milestones should therefore keep improving visible sea gameplay while replacing placeholders and closing real playtest failures, rather than adding menus for their own sake.
