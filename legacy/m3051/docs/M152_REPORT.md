# M152 · V3.8 Companions, Artifacts and AFK Rewards

M152 implements the first local vertical slice of the additive V3.8 master concept. It preserves the binding ship progression of three starter ships, 100 regular classes and separate Prestige P1–P5.

## Implemented

- Six data-driven companion definitions with one initial active slot, six roles, stable GLB/icon/portrait/VFX/audio addresses and distinct procedural visual fallbacks.
- Six mechanic-oriented artifacts with two initial active slots, caps, cooldowns and tradeoffs. Preview effects are intentionally not applied to authoritative gameplay.
- Four capped Harbor Operations profiles. The local preview calculates basic gold, material, ammunition and small XP rewards; competitive, event, boss and rare endgame outcomes are prohibited.
- Active local test claim with stable claim IDs and same-session duplicate protection.
- Mobile-safe Meta panel with 52-pixel controls and responsive positioning.
- Three additional Admin Content Studio types for companions, artifacts and AFK reward profiles.
- Thirteen replaceable SVG graphics and stable asset paths.

## Authority boundary

This source package contains a local simulation only. A production implementation still requires authenticated server ownership, trusted server time, transactional and idempotent claim processing, database persistence, versioned LiveOps data, audit records and abuse telemetry. Web remains a preview/acceptance target; native desktop, macOS, Android and iOS remain the quality targets.

## Asset replacement

Companion model paths are already represented as stable slots. If a valid replacement GLB exists, `AssetVisualLibrary` installs it; otherwise the visible fallback is classified as temporary and non-authoritative. SVG icons can be replaced at their existing paths without changing UI logic.
