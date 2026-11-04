# M190 — World Composition, Water Readability & Gameplay Framing

M190 is a presentation-only pass against the Masterkonzept V3.8 gameplay references. It does not change Tap-to-Sail, collision, combat ranges, ship stats, rewards, harbor authority, or global menu access.

## Camera framing

The default oblique sea-map camera is pulled modestly closer and narrowed to 38° FOV. Pinch zoom, camera-only wheel panning and recenter remain intact. The goal is larger readable ships/islands/encounters without scaling gameplay bodies.

## Water restraint

The ocean shader keeps the existing mobile-safe plane and reduced-motion support, but lowers micro-normal frequency, crest foam contribution and specular ceiling. Regional profiles are clamped toward rougher, darker, less reflective water so world silhouettes read over the sea rather than against bright glare.

## HUD/world separation

Harbor proximity feedback no longer occupies the middle third of the gameplay view. It is anchored below the top HUD. Generic POI text requires closer range while tracked objectives and combat nameplates keep priority.

## Authority

Presentation only. No economy, entitlement, progression, combat-authority, collision or world-navigation rules are fabricated or changed. Native Godot/Android visual acceptance remains required.
