# M253 — Realtime World Session, Presence & Reconnect

M253 extends the V3.8 online-readiness boundary with an authority-safe realtime world/session replica. It does **not** claim a production world server exists.

The client may render a server-verified session, map/instance/channel identity, published presence and reconnect state. Snapshot and world revisions are monotonic. A locally cached/stale snapshot can support presentation continuity but can never settle ownership, rewards, economy, map transfers, population, server time or resume success.

Reconnect is modeled as connected/degraded/reconnecting/resume_pending/resumed/closed. Resume references are opaque and server-issued. The client cannot fabricate a ticket or final verdict. Gameplay HUD receives only a transient reconnect/degraded chip when that state derives from a server snapshot; there is no permanent network-debug panel.

Production completion still requires a real Zone/World server, verified remote transport, presence service, map join/transfer, server-issued resume flow, latency/packet-loss/load testing and native device QA.
