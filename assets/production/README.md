# Authored asset intake — M210

Production assets replace stable visual slots; they never own gameplay stats, collision, navigation, rewards or unlocks.

## 2D
1. Generate 5–8 separated assets per sheet on transparent background.
2. Extract and keep one clean source master per asset ID.
3. Review at 96 / 64 / 48 px.
4. Import approved singles into `authored_2d/runtime/`.
5. Build atlases only from approved isolated masters. Never bind runtime logic to AI sheet coordinates.

## World assets
Ships/islands/loot/harbors remain individual authored models. No baked water, fog or global glow. Collision/navigation stay in Godot wrappers.
