# M96 — Halloween Interaction/VFX + Admin Asset Browser + Core World Continuation

M96 closes several gaps from M95 and keeps the event work integrated with the normal sea-map architecture.

- The haunted wreck is now a real proximity interaction. Interacting updates the Halloween exploration quest locally.
- The Halloween portal is also interactable and reports the current event phase without changing progression.
- Touch/mouse event interaction is consumed before Tap-to-Sail so tapping the event action does not send the ship away.
- Halloween portal/wreck priorities are registered in the actual semantic marker catalog. The total marker budget is unchanged.
- Gravefire now has a dedicated runtime impact treatment through CombatVfx and a correct replaceable VFX slot.
- Halloween portal ambience and boss arrival route through the existing VFX replacement/fallback path.
- M95's incorrectly classified VFX placeholders were moved from UI to the VFX catalog.
- Halloween encounter hull/damage scales locally for PL2–5 testability without changing normal progression or live reward authority.
- Admin Mode now has a searchable asset/event spawn browser capped to 12 visible results.
- Admin safe-area coordinates are scaled from physical screen pixels into viewport coordinates.
- Six additional non-event world slots were prepared for irregular islands, harbor pirate identity, wreck silhouette and NPC sail identity.

No client-side admin, Halloween currency, event reward, guild relation or live schedule is treated as production authority.
