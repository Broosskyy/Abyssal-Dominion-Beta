# Abyssal crossplay preparation

This is a runnable **presence sandbox**, alongside the existing local Godot beta. It provides persistent account registration/login, expiring hashed session tokens, WebSocket map rooms, ordered movement intents and server-limited 20 Hz positions. Godot's HTTPRequest and WebSocketPeer transport work with Android, iOS, desktop and web exports. This does not turn the local combat simulation into an authoritative MMO.

## Run locally

```sh
python3 -m venv .venv
.venv/bin/pip install -r server/requirements.txt
ABYSSAL_DATABASE=/absolute/persistent/path/abyssal.sqlite3 .venv/bin/python server/world_server.py
```

The default bind is `127.0.0.1:8787`. To expose a development instance, configure `ABYSSAL_BIND` and put a TLS reverse proxy in front. Configure exactly one `ABYSSAL_WEB_ORIGIN` for a hosted browser client. The client accepts HTTPS/WSS and local loopback HTTP for testing. Configure the endpoint in the captain harbor under **Einstellungen & Konto**; no public endpoint is invented or enabled automatically.

## Protocol 1

- `POST /v1/register`: `{protocol:1,email,password,username}`. Username 3–24 characters, password 10–128. The database stores scrypt hashes with independent random salts.
- `POST /v1/login`: same fields, username omitted. Both return `{protocol,token,account:{id,username},scope:"presence-preview"}`.
- `GET /v1/world`: WebSocket; first message `{type:"join",protocol:1,token,map_id}`. Tokens go in the first frame, never a query string. Only the 40 public sea ids are admitted; bonus maps are separate local instances.
- Course intent: `{type:"course",sequence,x,y}`. Server rejects duplicate/stale sequences, nonfinite/out-of-world points and excessive input. Clients never supply velocity, gold, HP, rewards or privileges.
- Server replies `welcome`, then `snapshot` with tick, map id and room-local `{id,username,x,y,sequence}` records. One session per account and at most 32 captains per room. A new token is held in memory by the client, not saved to guest files.

Tests: `python3 -m unittest discover -s server -v`; with this server running, Godot `tests/network_client_test.gd` exercises real HTTP registration and WebSocket motion from the game client. CI runs both.

## Deliberate boundary

The production service is **not deployed**. The live sea remains the local guest game. The transport and auth page are wired, but authoritative coastline collision, combat, economy/rewards, inventories, guild conquest, reconnect/resume and cross-device character saves are not yet connected to it. The presence room is an empty movement sandbox, not the local illustrated sea. Guest progress is never uploaded as trusted online progress. Production launch also needs account verification/recovery, revocation, backups, deployment configuration, privacy/account lifecycle and native-device/network acceptance. Local staff codes never issue server rights.
