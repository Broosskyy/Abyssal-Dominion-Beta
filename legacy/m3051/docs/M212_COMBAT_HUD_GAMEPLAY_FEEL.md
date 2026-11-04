# M212 Combat HUD & Gameplay Feel

M212 focuses on the visible combat loop rather than adding new balance. The selected-target panel now exposes a compact read-only combat-readiness payload: distance, effective weapon range, range state and current ammunition. The lower-right primary attack continues to be the dominant combat action and now communicates reload, out-of-range and empty-ammunition states directly.

The sea chart remains the primary visual surface. No persistent bottom command bar is introduced and the primary attack is not moved to the center. Mobile, Web and Desktop keep the same gameplay/world presentation; only responsive sizing, spacing, safe areas and touch-target dimensions may differ.

This milestone intentionally does not change damage, range formulas, reload timing, ammunition consumption, collision, navigation or encounter balance. Final visual fidelity still depends on authored UI/world assets and native Godot/device QA.
