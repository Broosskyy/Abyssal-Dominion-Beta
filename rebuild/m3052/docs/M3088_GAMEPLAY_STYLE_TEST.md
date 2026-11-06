# M3088 – Isolated black-green ship gameplay look experiment

**Target:** Base Basic PBR (shipyard skin 29), the black/green heavy test ship.

To use it in the installed game:

1. Equip **TEST · Schattenkriegsschiff** in the Werft.
2. Choose **GRAFIK HYBRID** or **GRAFIK 3D**.
3. Open **Menü → Anzeige & HUD anpassen**.
4. Under **M3088 · Schattenkriegsschiff – Stiltest**, compare:
   - **A ORIGINAL 3D / PBR**: unchanged GLB and imported materials.
   - **B GAMEPLAY-LOOK**: same GLB mesh and albedo/emission maps, less shine and normal-map micro-detail via per-instance material overrides.
   - **C ACHT RICHTUNGEN / 2,5D-SPRITES**: existing real GLB-derived eight-angle transparent texture frames instead of the live player mesh.
5. Keep the zoom, ship heading, map and lighting as similar as possible while testing readability.

## Guardrails

The source GLB remains untouched; this is *not* mesh decimation.
No images are AI-generated. No new 16-direction assets are claimed.
Only player skin **29** is affected. NPCs, other player ships, hitboxes,
combat stats, saves and movement logic are unchanged.
The chosen test profile persists as a device display preference.

B should preserve the recognizable black sails, green details and hull
silhouette. B is reversible at runtime, including on a live instance.
C uses a previously imported original-GLB atlas with eight heading
frames; it can serve as a performance/visual baseline.

## Android acceptance criteria

At ordinary and distant zoom, compare:
- recognizable prow and stern from all eight headings
- clear black sails and green decorations; no crowded dark noise
- surface shimmer while sailing and turning
- alignment of waterline, captain label, shield, HP and deck markers
- frame rate on a mid-range Android device
- NPC hulls staying unchanged and no duplicate player hull

Choose a rendering pipeline after seeing these tests, not based
on the raw polygon count alone.
