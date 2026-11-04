# Abyssal Dominion — M238 Production Report

M238 adds a read-only, server-authoritative season continuity layer on top of the M235–M237 event stack. The client can now display season identity and period, server-confirmed season score, division/rank, contributing event results and the publication/settlement state of season rewards.

Implementation includes a monotonic `authoritative_season_snapshot` replica in `EventRuntime`, `M238SeasonProgressionCatalog` for UI formatting, Command Deck surfaces under Events and Rankings, an explicit authority contract and regression tests. No client-side season scheduling, rank calculation, reward granting or settlement is introduced.

Gameplay balance, world navigation, collision, spawns, loot/reward values, the M213/M214 camera, round gameplay minimap and rectangular full sea chart are unchanged. Native Godot/device visual QA remains pending where the runtime executable is unavailable.
