# M238 — Season progression and settlement

M238 extends the server-replica event stack with a separate season snapshot. The snapshot is read-only on the client and can represent the active or recently settled season identity, authoritative start/end window, season score, division, personal placement, event results contributing to the season and the publication/settlement state of the season reward.

The client does not advance season time, convert event contribution into season points, determine a division, calculate an authoritative rank, create a settlement or grant/claim a season reward. Missing server data stays visibly missing instead of being filled with simulated rankings or rewards. Snapshot revisions are monotonic so stale season replicas cannot overwrite newer state.

M235/M236 remain the active event contribution/ranking layer and M237 remains the completed-event/history/receipt layer. M238 only aggregates server-confirmed season continuity above those systems. Gameplay balance, navigation, camera, minimap and world composition remain unchanged.
