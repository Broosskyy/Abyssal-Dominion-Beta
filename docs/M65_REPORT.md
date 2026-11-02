# M65 — Starter Ship Integration Polish + P0 Asset Acceptance

M65 turns the existing replacement architecture into a stricter acceptance pipeline for the three starter ships and five PL1–5 NPC ship assets.

The Asset QA Lab now has `M65 P0 SHIPS` and reports bounds, role, waterline, +Z forward direction, starter size-envelope diagnostics and visual socket status. The size envelopes are project QA/tuning guidance and never derive gameplay statistics.

A visual socket contract covers port/starboard muzzle, wake, bow foam, nameplate and selection anchors. If a final GLB does not contain these visual anchors, `ShipVisualSocketAdapter` can derive safe anchors from imported visual bounds. Socket count never defines cannon count or damage.

Material/texture memory guidance builds on M64: shared materials are preferred, 1K secondary maps are encouraged, and unique 4K textures are outside the PL1–5 mobile baseline until profiling proves they are justified.

The pipeline intentionally prefers simple mobile shaders, limited transparency and readable silhouettes. Final models remain replaceable GLBs; gameplay, collision and combat stay in the wrapper.

No native Godot 4.7.2 parser/runtime/device profiler QA was available in this environment.
