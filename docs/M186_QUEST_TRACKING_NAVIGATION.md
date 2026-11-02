# M186 — Quest Tracking & Objective Navigation

M186 connects the M185 quest overview to the seekarte-first loop. A captain can select exactly one core, regional or event objective. That selection survives the existing save flow without moving progress or rewards away from their established runtimes.

## Player flow

1. Open `MENU > AUFTRÄGE` or `MENU > EVENTS`.
2. Choose `ZIEL VERFOLGEN`; choosing another objective replaces the previous selection.
3. The sea HUD shows only that selected objective in the mission lane.
4. If a matching node exists in the current sector, `AUF SEEKARTE ANSTEUERN` reuses Tap-to-Sail.
5. If nothing can be resolved, the control states `KEIN KARTENZIEL`; tracking remains valid for objectives completed through general actions.

The world presentation is intentionally singular: one priority marker or edge cue and one minimap ring. Detailed quest lists stay in the Command Deck, preserving the readable map center.

## Resolution policy

- Core sink, loot and dock objectives resolve to the nearest existing enemy, loot pickup or port.
- Dynamic objectives first honor authored `content_ids`, `content_tags` and `target_groups`.
- Event objectives filter actual event participants/interactables; Halloween exploration resolves to the existing ghost wreck.
- The resolver never creates missing content, teleports, fabricates a path or grants progress/rewards.

## Persistence and authority

`TrackedQuestRuntime` saves only source, quest ID and objective index through `GameState`. Mission, dynamic quest and event runtimes remain progress owners. Admin no-code records can describe presentation/target policies through Draft → Review → Publish, but cannot add arbitrary code or client-side reward authority.

## Validation boundary

Python contracts and recursive JSON parsing are run before packaging. Native Godot 4.7.2 parse/render checks and Android/iOS high-DPI interaction testing remain required on an equipped machine.
