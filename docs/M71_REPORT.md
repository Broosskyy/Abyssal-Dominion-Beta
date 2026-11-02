# M71 — Early World Content Depth + Island/Harbor Composition

M71 attacks the visual sameness of the early sea map while preserving the 2D/2.5D gameplay plane.

- Six island composition profiles: small, medium, long shoal, thin spit, cliff cove and rocky islet.
- Shared/fallback island art gains multi-lobe visual composition so early islands are no longer uniformly round.
- Island collision/navigation remains wrapper-owned and independent from decorative visual lobes.
- Procedural island fallback now uses the replaceable M64 rock/sand/vegetation material families.
- Haven's Reach now has a visual-only modular content composition using the M70 lighthouse, dock, warehouse, market, quest board, crate and buoy slots.
- Service availability is NOT inferred from those models.
- Added Low/Balanced/High decorative density/distance budgets and mixed-silhouette Shattered Shores authoring examples.
- Final GLBs continue to replace stable slots without rebuilding gameplay.

Native Godot/device QA remains pending.
