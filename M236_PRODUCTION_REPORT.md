# M236 Production Report

## Scope
- Dedicated read-only Event contribution/ranking view in Command Deck.
- Personal + group contribution cards and contribution breakdown.
- Server-provided next-threshold progress presentation.
- Qualification and reward-publication status.
- Optional authoritative leaderboard rows; empty state never invents players.
- Compact Event summary in Rankings with route to Events.
- Gameplay HUD remains uncluttered and presentation-only.

## Authority
M235 `EventRuntime.contribution_replica_snapshot()` remains the only connected-data source. M236 adds no rank calculation, qualification mutation, reward grant/claim, phase mutation or economy mutation.

## Native QA
Static verification is performed in this environment. Native Godot/Android/Desktop/Web visual QA remains pending.
