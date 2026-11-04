# M130 — Progression/Economy No-code Migration

This pass closes several important gaps in the Admin-first architecture.

Now runtime-configurable:
- player XP curve, level-up gold, upgrade costs/limits/effects
- ship mastery curve/milestones through verified LiveConfig override
- beginner trial goals/rewards/token gains
- Abyss bonusmap entry, waves, wave rewards and completion rewards
- Gold bonusmap full definition override
- cannon/deck/bundle economy values
- dynamic item inventory persistence and per-item stack limits
- additive regional equipment modules
- generic dynamic shop purchase for gold-based offers

Critical fix: admin-created items were previously resolvable in Content Studio but PlayerInventory rejected them because it accepted START_STOCK IDs only. M130 removes that blocker while retaining validation and stack limits.

This still does not claim every specialized PL6–50 numeric catalog or every action-item mechanic is fully migrated. Those remain explicit next work.
