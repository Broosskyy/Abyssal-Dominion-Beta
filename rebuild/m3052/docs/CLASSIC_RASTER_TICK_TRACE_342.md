> **Überholt durch Classic 343 (14. November 2026).** Dieses Dokument beschreibt die *alte* physische 4-Wege-Zickzack-Logik der Updates 339–342. Sie wurde nach Spielerfeedback als Ursache der falschen Fahrt erkannt und entfernt. Seit [PR #56](https://github.com/Broosskyy/Abyssal-Dominion-Beta/pull/56) bewegen sich Schiffe in Classic 2D, 2,5D und 3D auf denselben tatsächlichen geraden, kollisionsgeprüften Fahrstrecken. Nur die historische 4-Ansichten-Grafik wechselt bei 2D auf Basis echter zurückgelegter Entfernung. Keine physischen 48×32-Schritte, keine `_move_classic`-Route und kein Zickzack mehr. Tests prüfen 14 gerade Kurse, sofortiges Retap, exakte Ankunft, NPCs und identische Weltkoordinaten. Verifiziert in Godot 4.7.2 Browser-Test 130; Geräteprüfung bleibt nötig.

# Classic 2D – physical raster-tick rendering (342)

Status: Godot 4.7.2 Classic/WebGL regression passed on `browser-test-128`. Implemented in the active `rebuild/m3052` source. This document tracks verification of the movement correction after the prior `data-339` and `data-340` calibration updates.

## Problem

The Classic chart uses four actual movement diagonals (NE/NW/SW/SE), in the screen-space aspect ratio 48:32. The simulation runs at 30 Hz and can cross an isometric diagonal boundary *within one simulation tick*. Earlier rendering linearly interpolated between the tick's first and last world positions. That straight chord was not a physical part of the ship's course. The hull image also sometimes followed the latest heading while the visible body was still drawing the prior tick. This caused apparent sideways sailing and corners being skipped.

## Fix

- `simulation.gd`: during each `_move_classic` call, collect the actual subsegments traveled, with starting position, ending position, distance and physical heading. These traces are transient render data, not save or network state.
- `ship_visuals.gd`: `classic_trace_sample` selects an interpolated position and heading along the true subsegments, weighted by traveled distance.
- `sea_map.gd`: `_visual_actor_pos`, `_classic_frame_for_actor`, the waterline and direction-linked overlays use the same tick-specific trace. Fallback to the previous interpolation is retained when no valid trace exists (teleport, remote actor, paused/standing still).
- `tests/classic_mode_test.gd`: verifies NE/SE mid-tick changes, pixel-facing consistency, end position, retapping, 14 bearings, no alternate steering modes.

## QA on real Android and browser

1. Tap far right on clear water; observe small alternating diagonal *physical* legs and matching ship-facing changes, with no sideways drift between each 30 Hz update.
2. Tap far upper-left while sailing right; the course should re-target promptly without a nautical turning radius or following a stale diagonal.
3. Test diagonal, shallow-angle and vertical destinations; verify exact arrival and consistent island avoidance.
4. Check zoom and ship scale on a 390–720 px tall landscape viewport. The earlier mobile camera and hull scale calibrations are preserved.
5. Check selection ring, nameplate, wake, hull waterline and camera panning all stay attached to the actual ship.

Keep the existing Android app and signing key, save data, server-side movement, 2.5D/3D modes and ship graphics unchanged. A successful automated CI run is not a substitute for a user-visible device-motion acceptance test.

Related change: https://github.com/Broosskyy/Abyssal-Dominion-Beta/pull/55
