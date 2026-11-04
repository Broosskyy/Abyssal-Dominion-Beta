# M251 — Companions, Artifacts & AFK Convergence + Client Polish

M251 converges the V3.8 companion, artifact and limited AFK-return systems without inventing final balance. The existing M152 catalogs remain development definitions/previews; M251 adds an explicit monotonic server-replica boundary for ownership, progression, loadouts, trusted offline time and claim receipts.

## V3.8 locks preserved

- Companions are bounded roles and never replace cannons, harpoons or manual combat.
- Initially one active companion is the intended direction; extra slots remain balancing-dependent.
- Gameplay-relevant companions and competitively relevant artifact power remain earnable.
- Artifacts specialize mechanics rather than becoming another generic stat ladder; strong effects need triggers, limits, cooldowns or trade-offs.
- AFK rewards are a limited return pool, not automated sea-map combat. They never efficiently replace active farming, events, ranked, guild war, world bosses or rare endgame drops.
- Offline time is production-server derived; client clock/save manipulation cannot mint rewards.
- Claims are server-authoritative and idempotent with reward/transaction receipts.

## Client polish

The Command Deck receives a first-class `Meta` destination with compact responsive status cards. The legacy floating meta panel is reduced to development preview/presentation duties and no longer exposes a normal local reward-claim button. Opening/closing uses restrained presentation-only transitions; no world/gameplay parity changes are introduced.

## Production gap

Still required: connected account/inventory/progression/reward services, authored acquisition/progression content, final companion models/portraits/animation/audio, final artifact hero/world assets, native mobile/desktop/web UX QA, telemetry-backed AFK caps/rates and production claim settlement.
