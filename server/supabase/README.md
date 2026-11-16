# Abyssal Dominion — Supabase crossplay beta (2026-11-16)

The **new Supabase Free project is ACTIVE** in Frankfurt:

- **Project:** Abyssal-Dominion
- **Reference:** `eysiaedrtfcomyzqqkxj`
- **Dashboard:** https://supabase.com/dashboard/project/eysiaedrtfcomyzqqkxj
- **Auth API:** https://eysiaedrtfcomyzqqkxj.supabase.co/auth/v1
- **Godot client:** `rebuild/m3052/network_client.gd`
- **Client public configuration:** `rebuild/m3052/online_config.json`

## Already wired in this branch

1. Godot browser and Android clients can register an e-mail/password identity **directly against the same Supabase Auth project**. If e-mail confirmation is enabled, the login screen instructs the player to confirm first.
2. GoTrue supplies the user id and short-lived access/refresh tokens. Only in-memory sessions are kept in the existing Godot scene tree; **passwords and bearer tokens are not written to guest-save files**.
3. Existing `/v1/world` WebSocket server accepts the Supabase access token on its first `join` message. It asks the **Supabase Auth /user endpoint** to verify it. Forged client metadata does not grant server authority.
4. If the server has a separate, private service-role credential, join/map/position checkpoints are persisted in `public.captains` and `public.captain_positions`. The existing server still runs the shared 20-Hz sea course simulation with common coordinates for browser Classic 2D and native renderers. A restarted server can retrieve a map-specific saved position from Supabase when its local SQLite data is absent.
5. Four Supabase tables were created with least-privilege RLS:
   - `captains`: display name, guild and rank metadata (only owners can read their profile).
   - `captain_progress`: **server-only writes**, own-player reads.
   - `captain_positions`: **server-only writes**, read within your map for recently online captains.
   - `captain_settings`: own-player read/insert/update only.
6. `private.create_new_captain` provisions safe default rows automatically on `auth.users` inserts; no client may grant itself currency or rank. The SQL definition of the tables, trigger, constraints, grants and policies is captured in `SCHEMA_SETUP.sql` for a *fresh project only*.

## Deploying the existing public test sea server

The database is hosted by Supabase. **A live 20-Hz WebSocket server is still a separate process**: Supabase is not, by itself, the authoritative game simulation. No public WebSocket server has been provisioned yet.

The existing `server/Dockerfile` and `server/railway.toml` support deployment, with **Root Directory /server**, one replica and a persistent `/data` volume. Deployment may incur hosting charges; review pricing before creating it. Once hosted, configure its private environment:

```env
ABYSSAL_SUPABASE_URL=https://eysiaedrtfcomyzqqkxj.supabase.co
ABYSSAL_SUPABASE_PUBLISHABLE_KEY=<copy-public-key-from-online_config.json>
ABYSSAL_SUPABASE_SERVICE_ROLE_KEY=<PRIVATE-SERVER-ONLY-KEY>
ABYSSAL_WEB_ORIGIN=https://abyssal-dominion-browser.vercel.app,https://abyssal-dominion-browser-beta.vercel.app
ABYSSAL_DATABASE=/data/abyssal.sqlite3
```

Keep `ABYSSAL_SUPABASE_SERVICE_ROLE_KEY` in the hosting provider's **secret environment**, never in the public repo, Vercel client variables, Godot, APK, or browser. The game client includes a **publishable key** only (intentionally safe for public distribution). Configure custom domains/origins based on your actual deployed URLs.

In Godot, enter the public **HTTPS** sea-server address under `Einstellungen & Konto` on both devices. The client upgrades it to WSS; it must not contain an Auth token in URL query parameters.

### E-mail confirmation configuration

Before external testers register, configure the Supabase dashboard at **Authentication → URL Configuration** with the production site URL and allowed redirect URLs for the actual deployed browser app. Inspect the confirmation e-mail flow on one Android device and one browser. Supabase's default SMTP has delivery limits, so configure production e-mail later.

### Manual acceptance sequence

1. On an up-to-date APK, **Konto erstellen** with e-mail A; verify e-mail; log in.
2. In a separate desktop/mobile browser, create e-mail B and log in (same Supabase project).
3. Configure the *same* public HTTPS world-server URL on both clients.
4. Both sail to the same map (for example, `1/1`) and see each other's player name, ship skin, world coordinates and route movement.
5. Select identical chart destination coordinates on both devices; server snapshots (not camera mode) must be the same world route.
6. Switch only the renderer between app Classic 2D and 3D where supported, without changing course, map ID or physics.
7. Cross to another map: the old room must drop that account's ship. Log in on the other device and verify its server-stored position.
8. Check Supabase `captain_positions` records; if no private server key is configured, remote persistence is intentionally disabled.

### Boundaries

**Prepared, not shipped as a public MMO**: a publicly reachable hosted WebSocket world service, two-device live acceptance, e-mail redirect configuration, reconnect/revocation tests, production-grade server-authoritative coastline/collision validation, shared NPCs/combat, inventories, guild wars, premium shop, and economic settlement remain to be completed. Local guest progress is still separate and is *not* uploaded as trusted server currency. The online game server's SQLite simulation state is still authoritative for the test rooms; Supabase is the accounts and durable checkpoint layer. Testing the Supabase tables or Auth does not establish live online gameplay.

### Safety and verification

- Supabase security advisor: 0 warnings after RLS setup.
- Read access as `authenticated` on an empty project returns 0 rows without recursive-policy errors.
- Python: `python -m unittest discover -s server -v`.
- Godot existing local crossplay: `rebuild/m3052/tests/network_client_test.gd`.
- No secret keys were committed.
