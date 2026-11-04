# M165 — Runtime Effect Depth, Crafting, Guild Specializations & No-Code Polish

M165 converts more of the previously prepared breadth into reusable runtime contracts while preserving server authority for sensitive operations.

## Combat / equipment
- Harpoon selection now consumes merged runtime content profiles instead of the older fixed three-effect conversion. Damage, range, reload, armor pierce, crit, status effect, duration and VFX color are data fields.
- M163/M164 harpoon families are normalized into one runtime authoring layer. New variants can use existing behavior primitives without client-code edits.
- Cannon mastery presentation remains four tracks with authorable visible stages at 1/3/5/7/10.

## Crafting / items
- Added a generic local crafting primitive and six original example recipes for ammunition and harpoons. Inputs, outputs, station, gold cost and availability are data-defined.
- Four crafting stations are modeled as content. New recipes using existing item/economy primitives do not require dedicated UI code.

## Guild island
- Five tower families now have authorable specialization branches with Lv.4/Lv.8 breakpoints.
- Treasury spend, island upgrades, tower specialization and siege declaration remain explicit server-authoritative/audited operations.

## Interface / Admin
- Progression center moves to M165 and gains a Crafting tab.
- Added content registry contracts for crafting recipes/stations, combat effect primitives, cannon visual stages and guild tower specializations.
- Draft → validate → review → publish → rollback remains the production model.

## Legacy audit
- Removed another hardcoded content island: harpoon runtime behavior now comes from merged content rows.
- Existing M159–M164 systems and save keys are retained.
