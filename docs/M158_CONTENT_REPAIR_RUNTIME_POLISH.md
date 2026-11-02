# M158 — Content Repair & Runtime Polish

M158 deliberately combines new depth with repair of older content. The patch avoids parallel subsystems and reuses the existing encounter, cannon, bonus-map and Halloween runtimes.

## Runtime changes

PL6–50 admirals now receive a band-specific `m158_phase_profile`. `EnemyShipAI` uses this profile at phase transitions, falling back to the previous generic boss escalation when no profile exists. PL1–5 remains unchanged.

Player cannon upgrades now use `M158CannonRuntime`: damage, reload and range scale with the already-existing cannon upgrade level, while tier 3/5 role mastery can reward preferred ammunition. This closes the previous gap where upgrade tiers were mainly presentation data.

Bonus-map final bosses are identified by map + final wave and receive map-specific mechanics, phase profile and loot-visual metadata. Existing progress/entry/save authority is preserved.

Halloween adds a fourth phase and more local-preview quests/shop rows through the existing `EventRuntime`. Live purchases/rewards still require future server authority.

## Safety / preservation

No third-party assets or exact designs are introduced. Stable production slots, save ownership, beginner neutrality and server-authority boundaries remain intact.
