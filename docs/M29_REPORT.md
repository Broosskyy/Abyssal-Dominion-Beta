# M29 — Harbor Hub, Loadouts & Mobile Command

M29 continues from M28 without resetting combat, encounters, events or the project mockup direction.

## Added
- Harbor market is now an actionable hub rather than presentation-only UI.
- Harbor supply bundle with ammunition, repair and boost restock; purchases are restricted to a valid port.
- Two persistent weapon loadout presets (A/B), saved in the normal player inventory state.
- Arsenal can save the current cannon/ammunition combination into either preset.
- Command Deck market can equip presets with large touch-friendly cards.
- Captain home page now exposes equipped ship, deck level and campaign-chain progress.
- Campaign-chain metadata now has explicit stage descriptions and goals.
- M29 menu header and mobile command presentation updated while preserving the responsive M26-M28 bottom navigation.

## Direction lock
- Project mockup remains the visual master.
- Seafight/Battle-of-Sea-like breadth is used as a gameplay/system reference, implemented with original code, UI and assets.
- Mobile, web and desktop remain first-class targets.

## Runtime note
The package is statically validated in this environment. A Godot 4.7.2 executable is not available here, so an engine parse/render/export still needs to be run on a Godot-enabled machine before visual acceptance.
