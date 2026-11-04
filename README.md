# Abyssal Dominion

**Current gameplay build: [M3059 — signed data updates and 2D sea foundations](rebuild/m3052/README.md).** Open `rebuild/m3052/project.godot` in Godot 4.7.2. Current Android version is `0.305.9-test.1` (code `305901`). The bootstrap APK is published as a [GitHub release](https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases); compatible game changes ship as signed `data-N` releases without a new APK. Package `com.abyssaldominion.rebuild` and the guest save migrate from M3052.

## Repository layout

| Path | Content |
| --- | --- |
| `rebuild/m3052/` | **Active game** (Godot project, tests, build tools, updater). The folder name is kept for the Android upgrade path. |
| `.github/workflows/m3052.yml` | Active CI: tests, signed data pack, optional APK, release publishing. |
| `updates/` | Live update manifests (`latest.json`, `data.json`) read by installed apps. |
| `releases/M30xx/` | Build reports, checksums and capture logs per milestone. APKs live in GitHub releases; renderer captures are attached to each `data-N` release (`ABYSSAL_CAPTURES_N.zip`) and to the CI run artifact. |
| `docs/` | Design and audit documents; `docs/reports/` holds the historical M162–M3048 production reports. |
| `project.godot`, `scenes/`, `scripts/`, `assets/`, `tests/`, `tools/` | Legacy M3051 project with the shared WebSocket test chart (see below). Not used by the active build. |

M3054 corrects displaced reflected ships, direction ordering, transparent-padding scale differences, waterline pivots and detached wake/shadows. [Video analysis and limitations](docs/m3054/SHIP_RENDER_AUDIT.md). Later milestones are summarized in the [active project README](rebuild/m3052/README.md).

## M3051 historical snapshot

Godot **4.7.2**, mobile-first naval combat prototype. Android test version **M3051 / 0.305.1-test.1**.

## Current build

- Start menu with local playable sea chart and a separate shared WebSocket test chart.
- Tap water to sail; select targets and fire; ammunition selection, repair, NPCs, loot and shipyard prototype.
- Reference graphics for four ship types, four islands, one monster and ocean noise are included in this private development snapshot.
- The shared chart uses an authoritative development server. There is no public MMO server, account service or complete cross-platform release yet.
- Visual reference priority: Seafight 2013-2020, Battle of Sea, the project's own mockup. Other games supplement individual systems.

## Open and play

Open `project.godot` in Godot 4.7.2 and press F6 on `scenes/network/start_menu.tscn`, or F5 for the project. Choose **LOKALE SEEKARTE SPIELEN** for offline play.

The M3051 APK is published as GitHub release `v0.305.1-test.1`. It uses package `com.abyssaldominion.mobile`, so it installs separately from earlier prototype package names. It is signed with a development key, not a Play Store release certificate. This snapshot does not contain the signing key.

## Android build

Requirements: Godot 4.7.2 and its matching Android debug export template, JDK 17, Android SDK platform-tools, build-tools 35.0.1 and Android platform 35.

Create a local debug key outside the repository, then run:

```bash
keytool -genkeypair -keystore /path/outside/repo/debug.keystore -storepass android -alias androiddebugkey -keypass android -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Abyssal Dominion,C=DE"
python3 tools/build_android.py --godot /path/to/godot --android-sdk /path/to/android-sdk --java-home /path/to/jdk17 --debug-keystore /path/outside/repo/debug.keystore
```

The script audits the integrated graphics, imports the project, exports the APK, verifies its signature, 16 KB alignment and manifest, and writes checksums and logs next to the APK.

## Local multiplayer test

```bash
godot --headless --path . scenes/network/zone_server.tscn -- --bind=0.0.0.0
```

Connect from another client using `ws://SERVER_LAN_IP:9080`. The default `127.0.0.1` address refers to the device running the client; a phone must use the server computer's reachable LAN address. Browser deployment over HTTPS requires a secure `wss://` endpoint. Guest progress is not persisted.

## Source and graphics

This is a new independent Git snapshot of the existing local M3050 work, based on `Broosskyy/SOH-2` commit `da940ca` and its M3049 base `958dd7e`. The existing checkout was preserved.

`assets/classic/private_seabattles/pack.json` records the selected reference assets and checksums. These are supplied APK reference graphics; public redistribution rights have not been established. This private test snapshot does not grant a license to third-party art. No raw APK source archives, credentials or signing keys are committed.

The older milestone documents and build scripts are historical records. For the current build use this README, `tools/build_android.py`, `docs/m3051/BUILD_REPORT.md` and `releases/M3051/`. Historical workflows are under `docs/legacy_workflows/`; they are not active CI.

