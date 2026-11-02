# M217 Production Report

M217 continues from M216 with combat pursuit and defeat-loop reliability.

Implemented:
- forced NPC aggro break when the current player target is sunk or respawn-protected;
- AI RETURN state and per-AI reacquire lock extending beyond the player protection window;
- passive encounter provocation reset after player defeat;
- presentation-only hostile broadside threat metadata and target-panel `SALVE` cue;
- M217 contract, documentation and regression coverage;
- release identity M217 / 0.217.0 / build 217.

No balance values were intentionally changed. Native Godot/device visual QA remains required.
