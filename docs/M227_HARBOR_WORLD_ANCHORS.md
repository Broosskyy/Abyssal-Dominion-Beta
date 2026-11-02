# M227 — Harbor world anchors

M227 makes the existing harbor service areas read as distinct parts of the physical harbor at the M213/M214 high/wide gameplay camera. The change is visual and authored-asset-ready rather than a second interaction/economy layer.

The four existing module sockets now expose stable service identity and replacement slots. Shipyard uses a gantry/crane silhouette, repair a tall repair frame, market an awning silhouette, and arsenal a compact battery silhouette. Form is the primary differentiator; color is secondary. This keeps the harbor readable after final authored assets replace the procedural placeholders.

M225/M226 remain authoritative for dock/undock, repair purchase and service actions. Navigation, collision, economy, combat, rewards and cross-platform world parity are unchanged. Final harbor assets must remain separate from water, fog and temporary gameplay VFX so Godot can own those systems.
