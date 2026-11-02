# M118 — Deterministic Bonusmap Waves + Ancient Guardian Combat

Gold and Abyss bonus maps no longer use generic EncounterDirector cadence. BonusMapWaveDirector owns explicit stable wave definitions: Gold 5 waves, Abyss 6 waves with monster wave 3 and Guardian wave 6. Only instance-owned enemies feed their matching progress runtime.

PL31–35 now has Ancient Guardian/Titan encounter identities. Level 32 can surface Ancient Guardian and level 34 Titan Spawn with dedicated production slots. Their deeper active mechanics are explicitly staged for the next pass rather than falsely claimed complete.

Legendary Fragments now have a real sink: five fragments can be forged at port into one Ancient Relic Core. The forge persists with Voyage state and has harbor UI.

Native Godot 4.7.2/mobile/web/desktop QA remains pending.
