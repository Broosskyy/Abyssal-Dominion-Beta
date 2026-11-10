# Two-captain presence test

The browser and native app use the same Godot HTTP/WebSocket protocol. On each device, open **Einstellungen & Konto**, enter the same deployed HTTPS test-server URL, register a different account, and join the same sea map. No public endpoint is enabled until the backend has persistent storage and passes its health check.

Expected: both captains see each other's ship design, heading, movement, account name and cosmetic HP bar. Change design in the shipyard to update the other client. Re-login on another device restores that account's position and design on the selected map. Connecting the same account elsewhere closes its previous connection. Map changes remove the captain from the previous room.

HP are a client-reported visual preview. NPCs, damage, loot and progression remain local; these tests do not validate shared combat or trusted online inventory. All browser ship designs still load together in the startup core and are reused from cache.

Automated checks: `python3 -m unittest discover -s server -v`; start `server/world_server.py` locally, then run Godot 4.7.2 `tests/online_ships_test.gd`. Add `-- --browser` after the script argument to test the baked sprite renderer; without it the test checks instantiated native GLBs. Use a fresh `XDG_DATA_HOME` for each run. The native CI imports assets before this test. Public two-device acceptance remains required after hosting is connected.
