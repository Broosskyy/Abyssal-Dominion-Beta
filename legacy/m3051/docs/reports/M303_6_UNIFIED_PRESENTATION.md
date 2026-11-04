# M303.6 – one game, two artwork sources

The player-facing presentation now supports only SeaBattles and SeaOfBones.
The old 2D/3D comparison choices are not exposed by the main scene. The earlier
M303.5 comparison script remains a historical development tool, not the player UI.

Both sources share the same HUD, water shader and coastline. SeaBattles island
images define the common chart. The source choice affects ship/monster sprites
and the ship portrait. Visible sprite bounds normalize vessel scale across the
two packages. Nameplates use consistent screen-relative sizing.

The captain card now contains the ship portrait, live hull bar, gold and kills.
The empty target panel is hidden until a target is selected. Status messages are
contained in a dedicated panel; old M303.1 debug text is absent from the main HUD.
Low-resolution HUDs are no longer scaled below 1x; larger screens scale upward.

Graphics selection lives under MENU. Switching between the two packages replaces
only visual children in place. Scene/actor identity, positions, headings, route,
camera, hull, ammunition, target, firing, reload/repair timers, gold and kills
remain unchanged. Water, coastline, HUD and controls do not get recreated.

The new entry script is `scripts/classic/m3036_unified_sea_map.gd`.
`tests/m3036_unified_smoke.gd` exercises live source switching and combat state.
`tests/m3036_visual_capture.gd` checks viewport containment and renders both
sources plus 844x390, 1280x720 and 1920x1080 layouts.

Android version `0.303.6-test.1`, code `303601`, keeps the existing package
`com.abyssaldominion.m3035test` and signing identity, allowing an update of the
previous test APK. The new APK is `ABYSSAL_DOMINION_M303_6_TEST.apk`.
The existing build-tool filename and export-preset name are retained for
compatibility; use `tools/build_m3035_android.py` as before.

Private artwork remains in ignored local packs; public commits contain code,
configuration and documentation only. No physical Android device playtest is
claimed by desktop rendering or APK structure/signature checks.
