# M3057 Android background updater

The native bridge is adapted from Realm Alliance WORK 733, commit 0640535b25e219b4660a7f37e38a7b9a1f88203f (development/android_updater717), to the existing Abyssal application and certificate. This is an APK updater, not a separate asset patcher.

The launcher checks a small HTTPS manifest on Android, downloads newer APKs through Android DownloadManager, shows progress and opens Android's installation flow after verification. Switching into gameplay, switching apps or recreating the launcher does not cancel the system download. Request metadata persists in Android private preferences and Godot user storage. Android manages connectivity pauses. Installation requires the user's Android confirmation and, initially, permission to install updates from this app. The installed M3056 needs one manual bootstrap update to receive this feature.

HAFEN → UPDATES PRÜFEN saves guest progress and returns to the launcher. Gameplay remains available during downloads and when the update endpoint is unavailable. The application ID com.abyssaldominion.rebuild and captain_m3052.json are unchanged.

## Trust and installation

The client accepts only the fixed distribution repository, matching version-specific APK path, package, pinned signing certificate, bounded size and lowercase SHA-256 metadata. It rejects downgrade/repeat downloads. Completed files are streamed through SHA-256 verification before the native installer checks the app-owned path, package, strictly newer exact version and APK signer. FileProvider grants temporary read access to Android's installer. No GitHub credentials or broad storage permission are embedded. CI refuses a replacement signing certificate; a missing original signing cache is a hard failure.

## Distribution

GitHub metadata now reports Abyssal-Dominion-Beta public (the initial inspection earlier in this session reported private). No repository visibility change is made by this implementation. The updater uses this existing repository's public GitHub releases and updates/latest.json. CI uploads the verified APK under ABYSSAL_DOMINION_<version_code>.apk in release abyssal-<version_code>-android, then commits the manifest last. Each manifest records the exact APK hash, size, signer and version. No additional repository or credential is needed. Newer source on main prevents stale publication; a failed test or signature check prevents release publication. The workflow's existing repository-scoped token creates releases in its own repository only.

Future releases need the same original signing key, a higher Android version code and matching update_model.gd VERSION_CODE. The original development signing cache is required and CI fails closed if it is missing. Existing supplied/reference artwork has no established public redistribution clearance; this change does not introduce any new artwork or change repository visibility.

## Verification

The workflow runs existing simulation/progression/ship/UI tests plus updater tests for trust metadata, corrupt/partial files, offline behavior, native queue persistence simulation, reconnect without duplicates, pause/resume, install permission handling and mobile launcher layout. The fake native adapter is explicitly a simulation. CI checks actual APK DEX symbols, registered plugin/provider, permissions, embedded configuration, signature, app/version, ARM64 and alignment. Captures render the actual launcher using documented fixture states; they do not show a real network transfer. A physical Android upgrade/background/permission/save-retention test is still required, as is an actual authorized hosted release-to-release update.
