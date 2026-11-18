# ABYSSAL DOMINION – M392: 30 originale Insel-Assets

**Stand / Ehrliche Abnahme:** Das technische Inselsystem samt 30 festen IDs ist vorbereitet. Die Grafiken in diesem Branch sind **noch keine 30 freigegebenen Original-PNGs**. Bis ein Bild zusammen mit überprüftem Kollisionsumriss angeliefert und freigegeben wird, bleibt die bewährte bisherige Inselgrafik aktiv. **M391 ist im aktuellen Repo keine eigenständig implementierte vorausgehende Fassung.**

## Was bereits funktioniert

- 30 stabile Objekt-IDs A01–E06 für fünf maritime Regionen, 20 spielbare Reviere und Größenklassen small/medium/large/landmark.
- Metadaten pro Insel: Name, visuelle Artbeschreibung, eigener Meshy-/3D-GLB-Slot, echter RGBA-PNG-Slot, 4-/8-View-Ordner, Kollisionsdatei, bisheriges Referenzbild und Freigabestatus.
- Ein gemeinsamer, datengesteuerter `island_asset_catalog.gd`-Resolver ordnet allen 360 physischen M388-Inselplätzen genau eine regionale ID zu.
- Erst **nach** manueller Artfreigabe und Ermittlung der **zur PNG passenden Kollisionssilhouette** lädt die Simulation automatisch Bild **und** neue Polygonform zusammen. Im nicht geprüften Zustand werden weder Bild noch Kollision ausgetauscht.
- Auch der Native-Modus nutzt aktuell die bestehende 2D-Inseloberfläche; das optionale GLB ist zunächst eine Quellvorlage für gebackene 4/8-Sprite-Ansichten, **kein behaupteter fertig integrierter 3D-Landmass-Renderer**.
- Die altbekannten 40 Karten, die Gildenfestungen, Bonuskarten, alten Save-Schemas, M376-Routen und 2D-/3D-Koordinaten bleiben unverändert.

## Vollständiger erster Inselkatalog

| ID | Name / Aufgabe | Größenklasse | Bisheriger Fallback | Grafikstatus |
|---|---|---|---|---|
| A01 | Kleine tropische Felseninsel | small | rock | planned |
| A02 | Palmeninsel mit Sandstrand | medium | tropical | planned |
| A03 | Größere grüne Hauptinsel | large | tropical | planned |
| A04 | Koralleninsel mit Riffen | medium | tropical | planned |
| A05 | Natürliche Hafenbucht | large | tropical | planned |
| A06 | Große markante Küsteninsel | landmark | rock | planned |
| B01 | Kleine Lotseninsel | small | rock | planned |
| B02 | Leuchtturminsel | medium | rock | planned |
| B03 | Handelshafeninsel | large | tropical | planned |
| B04 | Insel mit alten Lagerhäusern | medium | rock | planned |
| B05 | Bewachsene Felseninsel | medium | tropical | planned |
| B06 | Große Insel mit Hafenstadt | landmark | rock | planned |
| C01 | Kleine Eisinsel | small | snow2 | planned |
| C02 | Felsinsel mit Schnee | medium | snow | planned |
| C03 | Eisbergformation | large | snow2 | planned |
| C04 | Insel mit vereister Bucht | medium | snow | planned |
| C05 | Große Fjordinsel | large | snow | planned |
| C06 | Markante arktische Hauptinsel | landmark | snow2 | planned |
| D01 | Karge Felseninsel | small | rock | planned |
| D02 | Insel mit Wachturm | medium | rock | planned |
| D03 | Kleine befestigte Insel | medium | rock | planned |
| D04 | Verlassene Festungsinsel | large | rock | planned |
| D05 | Hafeninsel mit Verteidigungsanlagen | large | rock | planned |
| D06 | Große strategische Inselfestung | landmark | rock | planned |
| E01 | Kleine zerklüftete Insel | small | rock | planned |
| E02 | Verwittertes Felsenriff | medium | rock | planned |
| E03 | Insel mit alten Ruinen | medium | rock | planned |
| E04 | Ungewöhnliche Korallenformation | large | tropical | planned |
| E05 | Geheimnisvolle Reliktinsel | large | rock | planned |
| E06 | Große Hauptinsel mit uralten Steinstrukturen | landmark | rock | planned |

## Grafikstil / Quell-Assets

- Semi-realistische hochwertige maritime 3D-/2.5D-Anmutung, natürliche Licht- und Materialwirkung; keine animeartige Überzeichnung.
- **RGBA-PNG ohne Wasser/Hintergrund**, vollständige Küstenkontur, hochauflösend (Ziel 1536×1024 oder ähnlich), klare Silhouette beim Mobilzoom.
- Feste isometrische 3/4-Kamera, orthogonale Projektion, Elevation **48°**, Azimut-Baseline **45°** und einheitliche Beleuchtung.
- Bei Hafeninseln (z. B. A05, B03, D05) bleibt die **tatsächlich schiffsgängige** Einfahrt frei. Das darf nicht per Alpha-Shading kaschiert werden; die reale Polygon-/Pfadprüfung ist zwingend.
- Keine versteckten Kosten: Es werden weder Meshy-Premium-Credits noch andere API-Aufträge ausgelöst. Die 30 jeweiligen Master-Artbeschreibungen sind im JSON vorhanden.

## M392-Verzeichnis und Pipeline

```text
rebuild/m3052/
  island_asset_catalog.gd                    # freigabegebundener Renderer/Collision Resolver
  assets/visuals/m392_island_catalog.json    # 30 Inselentwürfe, IDs und Pfade
  assets/m392/
    islands/a01.png ... e06.png              # zukünftig freigegebene Einzel-PNGs
    models/a01.glb ... e06.glb               # optionale eigene Modelle
    collision/a01.json ... e06.json          # geprüfte transparente Küstenkontur
    views/a01_4/00.png ...                   # offline gebackene 4 Winkel
    views/a01_8/00.png ...                   # offline gebackene 8 Winkel
  tools/validate_m392_islands.py             # Python-Validierung
  tools/bake_island_views.gd                 # Godot-4.7.2-Offline-Baker
  tests/m392_island_catalog_test.gd          # echte Welt-/Kollisions-/Save-Regression
```

**Asset-Freigabe ohne stillschweigende Risiken:**

1. Ein neues einzelnes, transparentes `a01.png` usw. in den genau definierten Slot einfügen. Noch nicht freischalten.
2. `python3 rebuild/m3052/tools/validate_m392_islands.py` prüft den Gesamtbestand. Unfertiges bleibt entsprechend `planned`, `reference` oder `in_review`.
3. Ein reales, zum sichtbaren Landgrundriss passendes Polygon im **selben Koordinatensystem** wie PNG erzeugen, manuell auf Buchten/Zufahrten prüfen und als `collision/a01.json` mit `schema:1`, `asset_id:A01`, `reviewed:true`, `size:[W,H]`, `points:[[x,y],...]` exportieren. Keine Uferteile auf Wasser zeichnen.
4. SHA-256 für tatsächliche PNG-Datei und die geprüfte JSON-Datei berechnen. Erst nach Abnahme Status `approved`, `approved:true`, `collision_reviewed:true`, `sha256_png` und `sha256_collision` gemeinsam im Manifest setzen.
5. `python3 rebuild/m3052/tools/validate_m392_islands.py --require-approved` und vollständige Godot-Tests ausführen. Der Validator prüft Alpha/Größe/Ränder, Form, Eigenüberschneidungen und Überdeckung von Landpixeln, aber **ersetzt nicht** die Kontrolle der Hafenanfahrten durch echte Fahrtests.
6. Erst danach im Branch testen, freigeben und veröffentlichen; der Runtime-Resolver schaltet nur die bestätigte Grafik-/Kollisionspaarung ein.

## Optionale echte GLB-Modelle zu 4/8 Ansichten backen

Nach Vorliegen eines geprüften GLB und erfolgreich importiertem Godot-4.7.2-Projekt:

```bash
godot --headless --path rebuild/m3052 --editor --import --quit
xvfb-run -a godot --path rebuild/m3052 --script tools/bake_island_views.gd -- --asset=A01 --views=8
xvfb-run -a godot --path rebuild/m3052 --script tools/bake_island_views.gd -- --asset=A01 --views=4
```

Die erzeugten Winkel werden mit festem transparentem Hintergrund und einer Kamera erstellt, nicht im Browser/Android zur Laufzeit gerendert. Dies ist bewusst eine **vorbereitete Toolchain** – sie beweist nicht, dass schon ein GLB für alle 30 Inseln existiert.

## QA-/Release-Gates

- M392-Asset-Validator, 30-IDs und 360-Inselplätze, 40 alte Karten, 20 neue Reviere, reversible Speicherstände, Insel-/Hafen-Kollisionen, M376-Fahrtwege und identische Weltkoordinaten.
- Browser-WebGL-Testbuild über GitHub erlaubt. **Kein** automatisches Vercel-Deployment. Bestehende Vercel-Build-/Preview-Sperre wird nicht verändert.
- Android/App-Updates werden wie gewünscht nach vollständiger bestandener CI signiert und über den bestehenden Daten-Updater veröffentlicht. Eine nicht freigegebene Insel darf nie nur als hübscher Schein in den Build gelangen.

## Offen / Folgeschritte

- [ ] Hochwertige originäre Referenz **je Region**, nach identischem Masterrenderstil, einzeln freigegeben.
- [ ] 30 **tatsächliche, einzelne transparente, zurechtgeschnittene PNG-Inselgrafiken**; nicht nur Namen, Muster oder Collagen.
- [ ] Für jede freigegebene Grafik ein eigener geprüfter Küstenumriss plus Hafen-Test.
- [ ] Optional eigene GLBs sowie daraus gebackene 4-/8-Richtungs-Sprites.
- [ ] Eigene 3D-Landmass-Ansicht nur nach tatsächlichem Renderer-/Kollisions-/Crossplay-Test.
