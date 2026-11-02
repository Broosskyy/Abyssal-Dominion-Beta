# M12: Cross-platform foundation, not completed multiplayer

## Implemented boundaries

| Layer | Current implementation | Meaning |
| --- | --- | --- |
| Game | One GDScript project, Compatibility renderer | Same offline mechanics/assets across targets |
| Web | Single-thread WebGL2/WASM export, start gate, resize, touch, fullscreen request | Desktop/Mobile Web preview |
| HTTP server | Python stdlib, localhost by default; opt-in trusted LAN | Delivers exported files only |
| Transport | WebSocket client and local probe server, protocol 1 / build M12 | Tests connection compatibility only |
| Save | Local `user://` JSON with backup | Per-device/browser storage; no cross-save |
| Authority | Local single-player simulation | NOT ready to accept multiplayer state |

WebSocket is selected as a common native/browser transport because browser exports
do not offer arbitrary raw TCP/UDP. It does not itself supply game authority,
latency compensation, account security, scalability or matchmaking.

The probe accepts at most eight concurrent peers, a short initial handshake,
bounded packets and matching protocol/build. Session numbers are server-local
probe identifiers, **not authenticated player IDs**. No original game endpoints
are called. It binds only loopback. It is not safe to publish as an account/game server.

## Required next implementation for actual crossplay

1. Separate authoritative simulation from `ShipMotor` visuals/input and the local
   progression/encounter modules. Clients send bounded input intentions, not trusted
   gold, inventory, damage, positions or reward claims.
2. Dedicated fixed-tick server owns movement constraints, combat, NPC lifecycle,
   loot, inventory transactions and sector membership. Client visuals interpolate
   snapshots; reconcile prediction when server state differs.
3. Stable entity IDs and explicit versioned schemas for join, input, snapshot,
   fire, dock, equip, inventory result, sector transfer, disconnect/reconnect.
   Test duplicate/out-of-order messages and idempotent purchases/rewards.
4. Authentication and short-lived session credentials over HTTPS/WSS; server-side
   persistence/authorization; no shared secret in Godot exports. WSS endpoint from
   deployment configuration, not original-client credentials.
5. Interest management per sector, bounded update rates, heartbeat, timeout,
   rejoin and safe state recovery. Browser background tabs can suspend processing.
6. Test two actual device classes in one session: desktop Web + Android native,
   iOS Web + desktop native, plus browser refresh/background and network loss.

Do not call the transport probe a multiplayer milestone. M12 only prepares the
portable transport and build workflow so these next layers have an explicit boundary.

## Target readiness

| Target | Prepared | Still required |
| --- | --- | --- |
| Desktop Web | Working build/launcher; browser QA | More browsers, real GPU/performance |
| Mobile Web | Same build, low-quality profile, touch UI, safe-area handling | Android Chrome/iOS Safari physical-device acceptance |
| Android | ARM64 export preset, Internet permission for future networking | SDK/JDK, debug/release keys, real APK installation |
| iOS | ARM64 preset, stable bundle ID | macOS/Xcode/team/signing and installation |
| Windows | Desktop preset | Export templates, run on Windows |
| macOS | Universal preset | macOS tests and distribution signing |
| Linux | x86_64 preset | Native export/run test on target distro |

The Web preview intentionally disables PWA/service-worker caching during iteration.
Production PWA packaging is a separate release configuration and requires HTTPS.
Do not call browser persistence equivalent to durable cloud backup.

## Official technical references (consulted for M12)

- [Godot Web export: WebGL2, single-thread mode, mobile, HTTPS and limitations](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Godot WebSockets](https://docs.godotengine.org/en/stable/tutorials/networking/websocket.html)
- [Godot Android export prerequisites](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [Godot iOS export prerequisites](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html)

The executable actually tested here is Godot 4.5.1, regardless of the current stable documentation version.
