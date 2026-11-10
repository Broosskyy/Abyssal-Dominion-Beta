# Abyssal crossplay preparation

This is a runnable **presence sandbox**, alongside the existing local Godot beta. It provides persistent account registration/login, expiring hashed session tokens, WebSocket map rooms, ordered route intents and server-limited 20 Hz positions. Other captains now render as real ships with the same design catalog in browser sprites and native GLBs, heading, name and cosmetic HP. Position, heading and design persist per account and map across restart. Godot's HTTPRequest and WebSocketPeer transport work with Android, iOS, desktop and web exports. This does not turn the local combat simulation into an authoritative MMO.

## Run locally

```sh
python3 -m venv .venv
.venv/bin/pip install -r server/requirements.txt
ABYSSAL_DATABASE=/absolute/persistent/path/abyssal.sqlite3 .venv/bin/python server/world_server.py
```

The default bind is `127.0.0.1:8787`. To expose a development instance, configure `ABYSSAL_BIND` and put a TLS reverse proxy in front. Configure a comma-separated allowlist in `ABYSSAL_WEB_ORIGIN` for a hosted browser client. The client accepts HTTPS/WSS and local loopback HTTP for testing. Configure the endpoint in the captain harbor under **Einstellungen & Konto**; no public endpoint is invented or enabled automatically.

## Protocol 1

- `POST /v1/register`: `{protocol:1,email,password,username}`. Username 3–24 characters, password 10–128. The database stores scrypt hashes with independent random salts.
- `POST /v1/login`: same fields, username omitted. Both return `{protocol,token,account:{id,username},scope:"presence-preview"}`.
- `GET /v1/world`: WebSocket; first message `{type:"join",protocol:1,token,map_id}`. Tokens go in the first frame, never a query string. Only the 40 public sea ids are admitted; bonus maps are separate local instances.
- Course intent: `{type:"course",sequence,x,y}` or `{type:"course",sequence,route:[[x,y],...]}` (maximum 128 points). Server rejects duplicate/stale sequences, nonfinite/out-of-world points and excessive input. Clients never supply velocity, gold, rewards or privileges. `appearance` accepts a skin index 0–13 and bounded `hp`/`max_hp` solely for the visual presence preview; those HP are client-reported, never trusted for combat or persisted as character progression. Movement uses 165 world units/second; routes come from the client navigator, so coastline validation is not yet server authoritative.
- Server replies `welcome`, then `snapshot` with tick, map id and room-local `{id,username,x,y,sequence,heading,skin,hp,max_hp,moving}` records. Welcome includes persisted spawn position, heading and design. A new authenticated connection replaces the old account connection so map changes can resume immediately. One active connection per account and at most 32 captains per room. A new token is held in memory by the client, not saved to guest files.

Tests: `python3 -m unittest discover -s server -v`; with this server running, Godot `tests/network_client_test.gd` exercises real HTTP registration and WebSocket motion from the game client. CI runs both.

## Deliberate boundary

The production service is **not deployed**. The live sea remains the local guest game. The transport and auth page are wired, but authoritative coastline collision, combat, economy/rewards, inventories, guild conquest, automatic reconnect and full cross-device character progression are not yet connected to it. Presence ships are shown on the illustrated sea; the NPC/combat simulation is still separate on each device. Re-login restores map-specific position and skin; guest progression remains separate. Guest progress is never uploaded as trusted online progress. Production launch also needs account verification/recovery, revocation, backups, deployment configuration, privacy/account lifecycle and native-device/network acceptance. Local staff codes never issue server rights.

## Prepared public test deployment

`railway.toml` configures a single Docker instance and `/health`. In Railway select this repository, set **Root Directory `/server`**, and attach a persistent volume at **`/data`** before enabling public registrations. Keep one replica: room state and SQLite have one owner. The Dockerfile binds `0.0.0.0` and honors Railway's `PORT`.

Set `ABYSSAL_WEB_ORIGIN=https://abyssal-dominion-browser.vercel.app,https://abyssal-dominion-browser-beta.vercel.app`. Generate an HTTPS public domain, verify `/health`, then enter that HTTPS base URL in **Einstellungen & Konto** on both browser and APK. Do not enable a fictional endpoint or reuse an unrelated project's database. Service and volume pricing must be reviewed in the hosting account before provisioning a paid resource. Back up `/data/abyssal.sqlite3` with SQLite's backup API.

Validation now includes Python two-account/room tests, account/position/design persistence across a fresh World instance, and `tests/online_ships_test.gd`: two actual Godot HTTP/WebSocket clients, remote ship actor, preloaded browser design, native hull/finish mapping, course/heading/HP updates, own server movement, and removal on departure. It does not substitute for testing browser and APK on two physical devices over the public network.
