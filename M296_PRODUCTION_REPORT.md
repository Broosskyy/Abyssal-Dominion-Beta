# M296 Production Report

The active coastal sloop and gunship slots both previously referenced the same scout GLB. M296 supplies two distinct, whole-ship GLB placeholders with different footprints, materials and baked geometry. The gunship has broadside silhouette pieces and raised decks baked into its one mesh; the coastal ship has a narrower light-colored hull and baked aft deck. Each GLB has one node and one mesh with multiple material surfaces, not runtime interchangeable ship parts. Original P0 copies remain only as historical/fallback files.

The stable asset identities remain `npc_friendly_coastal_sloop` and `npc_gunship_01`. Existing runtime structural decorators are disabled only when these two new GLBs are selected, while other legacy fallbacks and user replacements are preserved. Future finished models can replace the same slots. All alterations are visual-only: hit boxes, motor, Tap-to-Sail, combat and reward authority remain untouched. Seafight and Battle of Sea remain clean-room genre/UX references; no proprietary content is included.

These models are programmatic placeholders, not professionally authored finished 3D art. Native Godot desktop/mobile import, gameplay silhouettes, draw-call budget and GPU QA remain NOT_EVALUATED.

Static validation: 442/442 zero-argument regression/contract functions and 17/17 unittest cases passed (459/459); 569/569 JSON files parsed. Both generated GLBs reproduced their documented hashes and passed binary layout, accessor, index-range and triangle-count checks. No native Godot executable was available.
