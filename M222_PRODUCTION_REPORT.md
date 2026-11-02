# M222 Production Report

M222 builds on M221 with the explicit round-gameplay-minimap / rectangular-full-sea-chart design lock and a shared existing-world target-action contract.

- Gameplay minimap remains circular, upper-right and north-up.
- Expanded sea chart remains rectangular/full-screen for planning density.
- Track/untrack stays TrackedQuestRuntime authority.
- Combat selection stays TargetingSystem authority.
- Navigate delegates only resolved existing Node3D targets to PlayerShipInput.
- No second route simulation and no gameplay/balance mutation.
