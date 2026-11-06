# M3092 · Optimized black/green ship model test

The uploaded ZIP was verified by SHA256 and imported by the M3092 GitHub Action.

**Werft skin 29** now offers three *real* full 3D models via **Menü → Anzeige & HUD → M3092**:
- **A (original):** the original existing ~30.8k-triangle base_basic_pbr GLB, unchanged
- **B (gameplay):** the supplied 5,918-triangle base_basic_gameplay_pbr.glb, 2K textures and normalmap
- **C (shaded):** the supplied 5,918-triangle base_basic_gameplay_shaded.glb, baked emissive look

These are all genuine GLB PackedScenes, rotated continuously in HYBRID or 3D. The former M3088
sprite choice was migrated to C, but the game-wide CLASSIC sprite fallback remains intact.

The uploaded models are Z-long with their **bow at +Z**, Y-up and min Y=0; new keys use
the correct axis, scale, water immersion, label hull projection and 0.614 source half-beam.
The previous model remains selectable as A; no change to equipped skin ID, inventory,
physics, damage or NPCs. Existing saves continue to load.

**Manual Android test:** equip TEST Schattenkriegsschiff in the shipyard; choose HYBRID or
3D; open Display & HUD and compare A/B/C while moving in eight directions at same zoom.
Confirm bow forward, sail symbols and green light, no water hover, captain label below hull,
and no duplicate meshes. Use PBR (B) as first candidate; C is an alternate.
