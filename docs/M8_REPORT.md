# M8 – Recovered runtime integration

## Outcome

M8 converts the previously debug-only Unity reference subset into actual test-runtime content. Release-test exports now load recovered SeeFight assets instead of showing only procedural primitives.

## Runtime asset set

- Player: recovered multi-part Clipper hull, sails and port/starboard cannons.
- NPCs: recovered Barco and Chalupa visual profiles.
- World: two tropical island profiles, one desert profile and one snow profile.
- Harbor: recovered wooden pier and lighthouse mesh.
- Water: recovered bump and foam maps drive the Godot-native compatibility shader.
- Audio: recovered ocean ambience, cannon blast and sinking sound.

Procedural geometry remains only as a fallback, collision proxy and missing-part supplement. The recovered test subset lives under `assets/recovered_test/m8/`; the original full reference dump remains separate.

## Runtime fixes carried forward

- HUD is mounted below a dedicated `CanvasLayer`, preventing the previous invisible-Control-under-Node3D problem.
- Recovered adapters no longer stop outside debug builds.
- Web, mobile and desktop presets include the small M8 runtime subset.
- Touch/desktop input now supports a reconstructed target-position sailing mode in addition to direct steering.
- A visible sea target marker represents the recovered `_puntero`/target-position concept.

## IL2CPP integration

The supplied analysis contains 2,282 Assembly-CSharp types, 9,884 methods and 9,797 fields. Its report, key types, metadata skeleton and machine-readable tables are preserved under `docs/il2cpp/`. See `M8_IL2CPP_IMPLEMENTATION_MAP.md` for the concrete Godot mapping.

## Validation boundary

Static GDScript parsing/linting, asset existence, archive integrity and platform contracts are validated in this environment. A Godot 4.7.2 executable is not available here, so a genuine rendered screenshot and export launch must still be produced on the runtime-capable Cursor/Godot machine. M8 must not be described as visually runtime-verified until that pass succeeds.

## Legal boundary

Recovered files are included for the user's private reconstruction/testing request. They must be replaced or separately licensed before public or commercial distribution.
