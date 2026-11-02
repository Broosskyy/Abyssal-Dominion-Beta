# M56 — Main Progression Track + Local Reward History

- Added a dedicated mobile-first ProgressionTrackPanel.
- The track explicitly separates map level, eligibility, earned ownership and boss reward milestones.
- Filters: NEXT, ELIGIBLE, OWNED, ALL and HISTORY.
- The first PL6–15 reward milestones are shown from the existing data-driven reward catalog.
- Future main designs without a bound PL6–15 reward source are labeled as not yet bound instead of inventing an acquisition method.
- Successful first-time main-design awards now create a local reward-history row stored inside PlayerShipRoster save data.
- Repeated boss kills cannot duplicate ownership and therefore do not create duplicate history entries.
- Existing old saves remain valid; reward history defaults to empty when absent.
- Added ProgressionTrackCatalog and five stable UI slots for progression states/history.
- No server audit, online authority or live reward backend is claimed.
