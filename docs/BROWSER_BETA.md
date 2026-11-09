# Abyssal Dominion — erste Browser-/Crossplay-Tests

Status: **HTML5-Webexport und Bereitstellungsautomatik vorbereitet**. Nur ein tatsächlich erfolgreicher Web-Build/Deployment liefert eine funktionierende Browser-Adresse. Die normale Spielsimulation bleibt vorerst lokal; das Online-Modul ist eine streng getrennte **Präsenzvorschau**.

## Browser-Spielbuild

- `.github/workflows/browser-preview.yml` exportiert die echte Godot-4.7.2-Anwendung (WebGL2/WASM, ohne Threads) aus `rebuild/m3052`, prüft `index.html`, `index.js`, `index.wasm`, `index.pck` und veröffentlicht ein gezipptes, eindeutig versioniertes Release `browser-test-N`.
- Der Webexport enthält die Spielinhalte direkt; die Android-Installation und ihr signierter Datenupdater sind im Browser **nicht erforderlich**.
- Optional wird auf GitHub Pages deployed. Ein Repo-Administrator muss einmal **Settings → Pages → Build and deployment → Source: GitHub Actions** auswählen, dann in **Settings → Secrets and variables → Actions → Variables** die Variable `ABYSSAL_PAGES_ENABLED=true` setzen. Erst nach einer erfolgreichen Pages-Action darf die tatsächliche Spiel-URL geteilt werden.
- Zusätzlich kann die bereits verknüpfte Vercel-Umgebung `web_preview/` als statische Browser-Beta veröffentlichen. Das Build-Skript lädt die neueste erfolgreiche HTML5-Prerelease, prüft gegebenenfalls ihren SHA-256-Digest und legt die geprüften Dateien als statische Site bereit.
- Nur für lokal heruntergeladene ZIPs: Dateien entpacken, **per HTTP-Server** ausliefern (nicht per Doppelklick mit `file://`), z. B. `python3 -m http.server 8000 --directory browser-ordner`, dann `http://localhost:8000` öffnen.

## Zwei Spieler sehen: ausschließlich Präsenztest

Das Projekt besitzt bereits einen eigenständigen Python-`aiohttp`-Server in `server/world_server.py` und Clienttransport `network_client.gd`. Der Server betreibt registrierte Testkonten und WebSocket-Räume für Seekarten. Er ist **noch nicht öffentlich deployed**.

So wird ein Entwicklungsserver ausgeführt:

```bash
python3 -m venv .venv
.venv/bin/pip install -r server/requirements.txt
ABYSSAL_DATABASE=/absolute/persistent/path/abyssal.sqlite3 \
ABYSSAL_WEB_ORIGIN=https://browser-origin.example \
ABYSSAL_BIND=0.0.0.0 PORT=8787 \
.venv/bin/python server/world_server.py
```

Für Browserzugriff muss das Backend mit **TLS/HTTPS + WSS** über einen Host oder Reverse Proxy erreichbar sein, nicht einfach mit einem offenen unverschlüsselten HTTP-Endpunkt. `ABYSSAL_WEB_ORIGIN` ist exakt die **Origin** der Web-Site (Schema + Host, ohne Pfad), beispielsweise bei GitHub Pages nur `https://broosskyy.github.io`. Keine fremden Origins freigeben. Backend-WebSocket-Lebensdauer braucht einen dauerhaften Server; Vercel-Serverless-Funktionen sind dafür kein Ersatz.

1. Browser oder APK starten → **Einstellungen & Konto** → die echte HTTPS-Basisadresse des Testservers eintragen → **Verbindung speichern**.
2. Zwei unterschiedliche Testkonten über `Konto erstellen` registrieren/anmelden (verschiedene Browserprofile oder Geräte).
3. Auf beiden Geräten dieselbe normale Seekarte betreten. Der Godot-Client öffnet den WebSocket-Raum.
4. Das untere/seitliche Spielmenü zeigt die Anzahl der online angemeldeten Kapitäne. **Türkise Testmarkierungen** stehen für andere Benutzer im selben Raum.
5. Auf freies Wasser tippen. Das gesendete Kursziel wird separat auf dem Server verarbeitet. Die andere Verbindung sieht den sich bewegenden **Präsenzmarker**.

**Grenzen des ersten Tests:** Keine synchronisierten 3D-Schiffe oder NPCs, kein gemeinsamer Kampf, keine PvP-Schäden, kein gemeinsames Gold, keine servergespeicherten Charakterstände, keine echte Gildenfreigabe. Lokale Saves bleiben getrennt. Die Session wird nicht in die Gast-Speicherdatei geschrieben. Die temporären Marker sind ausdrücklich keine fertige MMO-Synchronisierung.

Tests im Repository: `python3 -m unittest discover -s server -v`, Godot `tests/network_client_test.gd` und UI-Regressionstests. Noch erforderlich für öffentliche Tests: erfolgreiches Browser-Deployment, echte TLS-Serveradresse, Datenschutz-/Accountlebenszyklus, Geräteprüfung und Sicherheitshärtung.
