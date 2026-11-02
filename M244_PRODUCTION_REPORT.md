# M244 Production Report

Scope: V3.8 Crafting & Salvage convergence.

Implemented: canonical crafting-category contract; local craft transaction preflight + rollback; data-driven regional-equipment salvage with harbor/ownership/equipped/binding/capacity guards; partial material returns and zero Gold refund; Command Deck salvage preview/action; admin `salvage_definition` content type; M239 convergence promotion from FOUNDATION to PARTIAL.

Balance: prototype salvage return fraction is 50% and explicitly non-final. No recipe damage, combat, movement, spawn, loot-table or PvP values changed.

Authority: production online craft/salvage remains server-authoritative and must be atomic/idempotent. M244 does not claim a connected economy backend.

Native Godot/Android/Desktop/Web visual and interaction QA remains pending because a Godot executable is unavailable in this environment.
