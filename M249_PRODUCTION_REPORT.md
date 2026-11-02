# M249 Production Report

Milestone: M249 / 0.249.0 / build 249
Master: V3.8

## Scope
PvP / Honor / Ranked authority-safe replica plus continuous client polish pass.

## Competitive foundation
- Open-Sea PvP, Ranked, Guild War, Event PvP, Bounty Hunt and Duel vocabulary aligned to V3.8.
- Server-owned zone/flag/protection, Honor, MMR/Rank Points, matchmaking, match results, combat timer, modifiers, anti-farm verdicts and reward settlement.
- No invented final Honor values, MMR formula, Rank Points, combat-timer duration, PvP modifiers or Ranked rewards.
- Command Deck now shows server-backed PvP zone, Honor, Battle Rank, queue and combat timer state.
- HUD displays PvP danger/combat timer only when published by the authoritative replica.

## Continuous polish
- Responsive status-card padding/type sizing for compact touch layouts.
- Restrained Command Deck open transition and short staggered card reveal.
- Subtle ready-to-fire pulse on the existing lower-right primary attack control.
- No permanent new world-covering UI and no balance/gameplay changes.

## Verification
See automated pytest/JSON/ZIP checks in the release handoff. Native Godot/device visual QA remains required.
