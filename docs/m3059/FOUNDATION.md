# M3059 — signed game-data updates and 2D sea foundations

This is a one-time Android bootstrap upgrade from M3058. The earlier updater distributes full APKs and needs Android installation confirmation. M3059 adds a separate signed ZIP resource channel for compatible game GDScript, scenes, shaders, textures and content. Engine, Android plugin, updater and bootstrap configuration changes still require a versioned APK. A game session is never silently rewritten while running.

## Release behavior

Every push under the active game triggers validation. tools/release_plan.py compares the installed-shell version and a hash of protected bootstrap/native files. A higher shell version builds an APK; unchanged shell code produces only a data package. A protected change without a shell-version increment fails instead of advertising an incompatible hot patch. The workflow run number identifies immutable data releases. The original Android RSA key signs SHA-256 digests of each ZIP. Its public key is embedded in the bootstrap, and its existing certificate fingerprint is checked before signing. Private key material exists only in runner temporary storage. GitHub hosts APK/ZIP assets in releases; main preserves manifests, public key, reports, source and renderer evidence. APK copies are no longer accumulated in git history.

At startup the installed updater checks native releases and then game data. Android DownloadManager owns each data transfer too. Hash, RSA signature, fixed URL, engine/ABI, minimum shell and the signed archive's internal revision must match before activation. The archive cannot contain updater paths or native libraries. Cached signed data mounts before loading gameplay. Interrupted downloads resume; offline mode retains the cached/bundled game. Manual checks after gameplay has loaded stage the update for the next app launch to avoid stale script caches. The UI reports App and Data versions separately.

Two owned cache slots allow atomic handover without deleting a mounted archive. An old unused slot is removed on a later process start. A trial is marked attempted immediately before gameplay and confirmed after the sea scene initializes; an unconfirmed failed launch falls back to the previous valid cache or bundled resources. The captain save remains separate and unchanged. Data ZIPs contain the compatible resource set, not a byte-level delta; storage/network claims must use measured release sizes. Android/native changes still use an APK.

## Four-view navigation

Legacy NPC definitions declare four authored views and sprite rendering. Their actual routes are converted into alternating 45-degree legs, with bounded leg lengths and a coastline check for every segment. Eight/16-view sprites and future 3D renderers bypass this legacy routing restriction. Unsafe zigzags are rejected rather than teleported through land. This prepares the rendering/navigation distinction; it does not claim a completed 3D runtime or newly authored ship views.

## Coast and presentation

The four existing island PNGs were measured using alpha ≥180, largest connected land region and simplified contours. Polygons share the exact sprite anchor (0.5, 0.65), scale and per-region art selection. Collision checks use those polygons with a ship margin, not the old circle centered below much of the visible island. Minimap land follows the same outline. Large extra island ellipses are removed. Existing PNG pixels are unchanged; their native coast feathering remains. The harbor uses a compact anchor marker. Water uses moving directional wave slopes, layered noise and sparse crests. Ammunition buttons show type, stock and a colored selected marker without moving the established HUD controls.

## Verification limits

Tests cover signed metadata, tampered ZIPs, replayed revisions, activation, independent pack-only scene loading, navigation legs, free navigation for eight-view/3D metadata, measured collision geometry and existing gameplay/UI/save behavior. Renderer captures include actual simulated legacy motion plus telemetry and water/coast/ammunition views. They are controlled fixtures, not device replays. Physical Android data-download/background/relaunch acceptance remains pending. Further ships, guild islands, detailed cannon loadouts and guild systems remain separate content/system work; none are claimed by this foundation update.

## First content-only acceptance release

After the bootstrap was built and verified, a separate game-only change adds the extracted static RoyaleTowerIcon3 sprite as a neutral harbor watchtower, aligns island captions with measured coast bounds and suppresses the harbor icon beneath nearby ship labels. This is scenery, not implemented guild ownership or siege rules. The source PNG is recorded in assets/provenance.json. Its release must report apk_built=false and preserve the existing native version/signature before this is described as an end-to-end data-only publishing test.
