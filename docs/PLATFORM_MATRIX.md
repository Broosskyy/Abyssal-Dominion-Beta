# Platform matrix — M18 / Godot 4.7.2

Latest verification: `M18_REPORT.md`; networking limits: `M12_CROSSPLAY_PLAN.md`.
Presets/configuration alone do not mean native exports have been built or installed.

| Target | Renderer/profile | Input | Export result |
| --- | --- | --- | --- |
| Android | GL Compatibility, balanced, adaptive low fallback | Touch joystick, action zones, pinch zoom, optional gamepad | APK/AAB-ready preset; signing still required for store release |
| iOS | GL Compatibility, balanced, adaptive low fallback | Touch joystick, action zones, pinch zoom, optional controller | Xcode/iOS preset; macOS, team ID and signing required |
| Mobile Web | GL Compatibility, low baseline | Touch joystick, action zones, pinch zoom | Same single-thread Web build; no development service worker |
| Desktop Web | GL Compatibility, balanced | Keyboard, mouse wheel, mouse fire, gamepad | Same Web export; runtime profile detected automatically |
| Windows | GL Compatibility, high | Keyboard, mouse and gamepad | Embedded-PCK executable preset |
| macOS | GL Compatibility, high | Keyboard, mouse and controller | Universal application preset; signing/notarization external |
| Linux | GL Compatibility, high | Keyboard, mouse and gamepad | x86_64 executable preset |

## Shared architecture

- One gameplay codebase and one X/Z water-plane simulation
- Controlled oblique camera; no free orbit, third-person mode or free Y movement
- Safe-area-aware HUD and touch hit zones
- Automatic pause on mobile/Web focus loss and resume on focus return
- Adaptive 3D resolution and reduced water/shore geometry on constrained devices
- Reference-only assets remain excluded from every release preset
- SVG app icon and PNG boot splash are included

## External requirements

Export templates must match the actual Godot executable: this revision targets
Godot 4.7.2 stable. M12 reports describe historical 4.5.1 builds. Android store delivery
requires a release keystore. iOS requires macOS/Xcode, an Apple team ID and signing.
Desktop signing/notarization remains platform-specific. Nothing is publicly hosted
or signed automatically by the preview launcher.
