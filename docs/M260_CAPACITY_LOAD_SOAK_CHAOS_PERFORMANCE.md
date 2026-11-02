# M260 — Capacity / Load / Soak / Chaos / Performance Operations

M260 adds a fail-closed Operations/QA readiness layer for capacity planning and resilience testing. It does not claim a production load-testing platform exists.

## Capacity dimensions
CCU, players per map/instance, combat load, NPC/monster population, chat throughput, database throughput, telemetry throughput and event spikes are explicit measured dimensions. No final limits are invented.

## Resilience testing
Load, soak, reconnect/packet-loss, world-server restart and selected dependency-failure/chaos scenarios are represented as versioned test campaigns. Destructive scenarios are not allowed to run uncontrolled on GLOBAL.

## Client performance
Quality profiles may tune render scale, shadows, particles/VFX, water, view/detail distance, LOD, post-processing and FPS target. They may not create different gameplay worlds or content between Mobile, Desktop and Web. Server simulation/combat authority is independent from client FPS.

## Authority
The Godot client only presents verified Operations results. Production scale decisions, autoscaling, test execution and capacity-gate approval remain external Operations/QA responsibilities.
