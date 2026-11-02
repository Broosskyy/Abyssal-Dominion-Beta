# M202 — Gameplay, HUD & Menu Interaction Pass

M202 treats the sea screen and menu system as one interaction hierarchy instead of independent feature panels. V3.8 and the approved visual masters remain the target; the rejected persistent lower command/map bar is not reintroduced.

## Command Deck interaction shell

The Command Deck now exposes a fixed quick-access set for Overview, Charts/Progress, Quests, Ship/Equipment, Market and Harbor before the complete destination picker. Back and Close remain visible in the header. The same destinations and information hierarchy are used on Mobile/Web/Desktop; only the number of responsive columns, physical control size, spacing and safe-area presentation may change.

Touch controls receive a stronger minimum target policy. Touch no longer receives a forced OptionButton focus highlight when opening a menu, while keyboard/controller navigation keeps a predictable focus anchor. Every page change resets the content scroll to the top. Requirement buttons preserve disabled state and expose the provided reason/availability label as interaction help.

## HUD/gameplay lock

The world remains the dominant visual layer. Primary attack stays lower-right. The top navigation retains a clearly accessible MENU entry without adding a permanent lower command bar. Opening routed panels continues to use the unified input guard, avoiding accidental sail/combat input through overlays.

## Placeholder continuity

Eight additional navy/gold SVG interface placeholders were added for Menu, Back, Close, Harbor, Fleet, Inventory, Ranking and Settings. They are replacement-ready UI assets, not final art. Existing M201 reference-grade ship/island/loot placeholders remain in use while later passes expand NPC, monster, harbor and world-prop coverage.

Native Godot/device visual QA is still required; this milestone is static-source verified only.
