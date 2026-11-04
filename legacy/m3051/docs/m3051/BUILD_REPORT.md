# M3051 Android test build - 02.11.2026

Built with Godot 4.7.2.stable.official.ed1daf0bf, JDK 17 and Android build-tools 35.0.1.

## Result

- APK: `releases/M3051/ABYSSAL_DOMINION_M3051_ARM64_TEST.apk`
- Package: `com.abyssaldominion.mobile`
- Version: `0.305.1-test.1`, Android versionCode `305101`.
- Architecture: ARM64.
- Size: 73,460,286 bytes.
- SHA-256: `de9989c44243bd60f90061c696bcb96198a10b6df93bbf33ca5c590c762692e5`.
- Archive integrity, Android manifest, development signature and 16 KB zip alignment: PASS.
- Ten integrated reference images and their exported texture mappings audited, including matching `pack.json`.

The first post-export audit incorrectly expected PNG or .remap paths. Godot actually exported .import mappings plus compiled .ctex textures. The audit was corrected to inspect both the mapping and its compiled target, and the full build was rerun successfully.

## Regression checks

All six existing checks passed again on this snapshot, each with isolated user storage. Machine-readable results and engine logs are alongside this report.

1. Authoritative zone simulation.
2. Local WebSocket end-to-end test with the actual chart and a second client.
3. HUD, ammunition and ship-frame stability.
4. Ammunition / shipyard controls and responsive layout.
5. Immediate tap-to-sail and retained route planning.
6. Mobile artwork ZIP importer and path validation.

## Scope

This is a packaged version of the existing M3050 prototype with build identity M3051, integrated reference graphics and reproducible build tooling. It does not implement all features of the research dossier.

No physical Android installation, on-device performance or touch acceptance was performed. Local play is available through the first start-menu button. Online mode requires a separately running reachable development server; there is no configured public server, account service or persistent MMO world.

## Repository

A new independent local Git repository was initialized on `main` from the existing project snapshot. Code, source graphics, build tooling, documentation and this APK are included in the local commit. No signing key or credentials are included.

Remote GitHub creation was not completed: the available GitHub connector has no repository-creation action, direct API access is unauthenticated, and the browser authentication request returned `declined`. No new remote repository or successful push is claimed.

Historical build instructions and reports remain historical. Current entry points are the root README and `tools/build_android.py`.
