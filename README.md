# Abyssal Dominion

**Current gameplay build: [M3059 — signed data updates and 2D sea foundations](rebuild/m3052/README.md).** Open `rebuild/m3052/project.godot` in Godot 4.7.2. Current Android version is `0.305.9-test.1` (code `305901`). The bootstrap APK is published as a [GitHub release](https://github.com/Broosskyy/Abyssal-Dominion-Beta/releases); compatible game changes ship as signed `data-N` releases without a new APK. Package `com.abyssaldominion.rebuild` and the guest save migrate from M3052.

## Repository layout

| Path | Content |
| --- | --- |
| `rebuild/m3052/` | **Active game** (Godot project, tests, build tools, updater). The folder name is kept for the Android upgrade path. |
| `.github/workflows/m3052.yml` | Active CI: tests, signed data pack, optional APK, release publishing. |
| `updates/` | Live update manifests (`latest.json`, `data.json`) read by installed apps. |
| `releases/M30xx/` | Build reports, checksums and capture logs per milestone. APKs live in GitHub releases; renderer captures are attached to each `data-N` release (`ABYSSAL_CAPTURES_N.zip`) and to the CI run artifact. |
| `docs/` | Active documents: `docs/design/` (concepts, design lock, reference analysis), the M3054–M3059 audits [`SIGNING.md`](docs/SIGNING.md) (signing keys) and [`ART_REPLACEMENT.md`](docs/ART_REPLACEMENT.md) (temporary test graphics still to replace). |
| `legacy/m3051/` | Archived M3051 Godot project with the shared WebSocket test chart, preview launcher, its docs and the historical M162–M3048 reports ([README](legacy/m3051/README.md)). Not used by the active build. |

M3054 corrects displaced reflected ships, direction ordering, transparent-padding scale differences, waterline pivots and detached wake/shadows. [Video analysis and limitations](docs/m3054/SHIP_RENDER_AUDIT.md). Later milestones are summarized in the [active project README](rebuild/m3052/README.md).
