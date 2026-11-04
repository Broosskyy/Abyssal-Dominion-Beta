# M87 — Safe-Area Input Protection + PL1–5 World Silhouette Polish

M87 continues mobile/desktop quality work under the Masterkonzept and P0 production order.

- Added touch gesture-edge protection for critical movement and combat HUD controls. Critical touch controls are clamped inside an additional safe inset; desktop layouts are not padded unnecessarily.
- HUD editor now uses a two-row toolbar on narrow landscape screens and warns about critical controls near the system/gesture edge.
- Island procedural fallbacks now reuse cached primitives and gain profile-specific asymmetric accents for cliff/cove, thin-spit and long-shoal silhouettes.
- Island composition metadata explicitly describes asymmetric coast/silhouette intent; it remains visual-only and does not redefine navigation collision.
- Haven's Reach now wires sailcloth bundle and harbor cart slots without creating fake services.
- PL3 monster-zone dressing now wires bone-spine and harpoon-rack slots under the existing mobile object caps.
- Eight more stable model slots are prepared for harbor, wreck, irregular island/cove and monster-hunt art.
- Crossplay boundary remains unchanged: device-specific presentation/input safety, same gameplay rules/intents.

Native Godot 4.7.2 parser/runtime, Android/iOS gesture-area screenshots, desktop QA and GPU profiling remain pending.
