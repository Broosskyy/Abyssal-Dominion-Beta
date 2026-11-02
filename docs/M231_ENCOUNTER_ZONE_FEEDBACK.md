# M231 — Encounter Territory Feedback

M231 turns the M229/M230 encounter semantics into restrained crossing feedback in normal gameplay. Existing elite, monster-territory and admiral encounters can now produce a short enter/leave read when the player crosses a presentation-awareness boundary. Ordinary patrols remain silent.

The awareness radii are presentation thresholds only. They are not aggro, weapon, collision, spawn or navigation ranges. A small hysteresis and cooldown prevents repeated messages near a boundary. Regional temperament and formation metadata can be appended as a compact secondary hint, while the sea-chart center stays free.

The round gameplay minimap, rectangular full sea chart, M213/M214 camera composition, M228 spawn budget and M229/M230 encounter semantics remain unchanged. Native Godot/device visual QA is still required.
