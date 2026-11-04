# M211 — Asset Intake & Ship Visual Hierarchy

M211 makes the next production step explicit: authored 2D art replaces stable presentation slots; it never becomes gameplay authority. AI/recraft generation sheets remain production material only. Every approved icon is isolated as its own transparent master before optional atlas packing and is reviewed at 96/64/48 px.

## First authored intake
Start with UI01 cannon ammunition, UI02 harpoons, UI03 combat items and UI05 cannon families. Keep 5–8 large isolated assets per generation, generous transparent spacing, no shared glow/shadow and no text baked into icons. Silhouette must carry identity before color.

## Ship visual hierarchy
The ship is read as one composition: hull/design first, representative cannon battery and rigging second, armor/ram/harpoon modules third. Normal deck progression remains visibly stacked below the hull; an equipped special deck is a separate lower layer beneath the normal deck stack. These layers are visual only and never alter collision, navigation or projectile authority.

## Replacement flow
Generation sheet → isolated source master → 96/64/48 review → runtime single → optional approved atlas → stable VisualAssetCatalog slot. Keep the isolated master even after atlas packing.
