# M5 report — Mobile, Web and Desktop hardening

## Delivered

- Runtime profiles for mobile Web, native Mobile, desktop Web and native Desktop
- 72%, 86% and 100% 3D-resolution tiers with automatic low-FPS reduction
- Platform-dependent water and shoreline mesh density
- Mobile/Web focus-loss pause and deterministic resume
- Conflict-free deferred touch actions: actions execute on release instead of first contact
- Two-finger pinch zoom without accidental firing or steering
- Safe-area transforms shared by HUD and touch hit zones
- Keyboard state reset fix after releasing movement keys
- Optional gamepad axes and combat/action buttons
- Landscape expansion across varying widescreen aspect ratios
- ETC2/ASTC and S3TC/BPTC import paths
- Updated Android, iOS, Windows and macOS version metadata
- Original production SVG icon and splash screen
- Reusable static platform-contract validator

## Verification boundary

The M5 validator passes 19/19 platform-contract checks. All 26 GDScripts also pass parser/lint validation. Both production SVG files are valid XML and the export configuration contains all twelve expected preset/options sections.

Static validation confirms project settings, code paths, export presets and reference exclusions. Runtime frame pacing, device thermals, WebGL behavior, Android packaging, iOS signing and desktop executables must still be tested with Godot 4.7.2 export templates on the corresponding platforms.
