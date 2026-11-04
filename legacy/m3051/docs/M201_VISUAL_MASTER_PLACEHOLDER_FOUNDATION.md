# M201 — Visual Master Placeholder Foundation

M201 continues convergence toward the V3.8 visual master rather than adding another meta-system. The gameplay world remains the primary screen. The explicitly rejected permanent lower selection/menu bar and center-bottom primary attack layout remain forbidden.

## Reference-grade placeholders

The source now includes a compact clean-room placeholder set under `assets/production_placeholders/m201_reference/`: three starter-ship GLBs, four island GLBs, four loot GLBs and eight navy/gold SVG HUD icons. These are intentionally **not final art**. Their job is to make current gameplay composition readable at the intended angled top-down camera while keeping every slot immediately replaceable by final production assets later.

The starter ships have distinct small/medium/large silhouettes, masts, sails, trim and cannon masses. Islands use layered rock/coast/ground silhouettes with sparse landmarks instead of featureless discs. Loot uses chest, coin-cache, salvage and repair-crate silhouettes that remain readable on water. UI icons use a consistent dark navy tile and gold high-contrast symbol language.

`assets/placeholder_pack/manifest.json` now points the relevant current runtime slots at the M201 placeholders. Gameplay collision, movement, combat sockets, loot authority and interaction are still supplied by their existing wrapper nodes, not by the GLBs.

## Harbor readability

Procedural harbor service modules receive a visual-only navy roof and gold facade accent. Their collision and service interaction volumes are unchanged. This helps harbors read as intentional destinations from the sea without turning them into giant UI/menu structures.

## Platform parity

M201 fixes a remaining old placeholder-quality divergence: `ProductionPlaceholderContract.quality_profile()` no longer assigns different world VFX/LOD semantics to compact/mobile versus desktop. World models and gameplay VFX stay canonical across Mobile, Web and Desktop. Only interface size, spacing, safe areas, fonts and touch targets may respond to the display.

## QA status

M201 is static-source verified. Native Godot rendering on Android/Desktop/Web still requires visual QA before any claim of final reference fidelity.
