# M38 — Responsive Mobile HUD & Combat Selection UX

M38 prioritizes the visual/mobile-comfort feedback from the latest device screenshot. The former 720p-oriented HUD could remain at scale 1.0 on a high-resolution landscape phone, making labels and touch targets physically too small.

## Implemented

- Density-aware HUD scaling using reported screen DPI in addition to viewport resolution.
- High-density touch devices use a 1.15–1.70 comfort scale; normal desktop DPI keeps the denser desktop layout.
- High-density touch devices are treated as compact UI even when the raw landscape resolution is wide.
- Core top/profile/stat/nav geometry, mission text, combat buttons and native themed panels scale with the density profile.
- NauticalTheme now scales native Button/OptionButton font size, padding and VBox spacing.
- Arsenal, Captain Journal and Command Deck widths scale for high-density touch while remaining constrained by safe area.
- Large current-ammunition selector beside the Fire button.
- Large Items selector beside combat actions.
- Ammo picker: Iron Shot, Explosive, Chain Shot and Harpoon, each with stock and short role description.
- Items/Supplies picker: Repair, Boost, Black Powder, Armor Plates and Harpoon.
- Active ammo/supply state is visibly highlighted.
- Picker touch input is modal: taps do not leak through into Tap-to-Sail navigation.
- Legacy three small ammo quick-buttons are hidden on high-density touch devices but remain available on desktop.
- Android/iOS safe-area behavior remains in the existing safe-rect contract.

## Reference interpretation

The supplied Battle of Sea / Seafight screenshots are used only as interaction/reference direction: large primary fire action, prominent current-ammo control, readable inventory/ammo lists, and thumb-reachable combat controls. No external UI artwork is copied into the project.

## Deliberately not claimed

- No native Godot 4.7.2 binary is available in this environment, so M38 has not been accepted on a physical Android/iOS device here.
- DPI reporting differs by device/vendor; native APK QA is mandatory before locking scale constants.
- This pass does not introduce a fake online backend or server-owned guild/economy state.
