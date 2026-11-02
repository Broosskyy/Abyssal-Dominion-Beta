# M52 — Shipyard 3D Preview + Mastery Comparison

- Added dedicated ShipyardPanel with real SubViewport 3D model preview, ship selector and 45-degree rotation controls.
- All 3 starter ships and all 50 main progression design IDs are browsable.
- Main-design previews resolve their own stable model slot first; without final GLB override they fall back to the assigned starter archetype.
- Current ship vs selected ship comparison includes mastery-scaled Hull/Damage plus Speed, Armor and Turn deltas.
- Mastery milestone badges 2–10 are visible in the shipyard.
- Equip remains harbor-only and uses PlayerShipRoster gameplay state.
- Added ShipyardVisualResolver and ShipCardPipeline contracts.
- Added GLB → QA → approved preview → independent ship-card slot workflow. M52 does NOT claim automatic runtime thumbnail capture.
- Mastery milestone economic/item rewards remain intentionally undefined; M52 only exposes presentation hooks instead of inventing rewards.
- Added shipyard UI/VFX/audio replacement slots.
- Production coverage now contains 281 stable slots. Missing final overrides: P0 148, P1 124, P2 9.
- Static validation only; native Godot 4.7.2 runtime/device QA is still required.
