# Update 346 – gemeinsamer Seekartenkurs in Classic 2D und nativem 3D

Datum: 14. November 2026

## Verbindliche Produktregeln
- **Browser**: ausschließlich Classic 2D mit den vorhandenen gebackenen 8-Winkel-Schiffsatlanten. Es wird kein 3D-SubViewport oder GLB-Schiffsrenderer gestartet.
- **Android / iOS / Desktop (native)**: genau **Classic 2D** und **echtes 3D**. Kein dritter auswählbarer 2,5D-/Hybridmodus. Vorhandene gespeicherte Auswahl `hybrid` wird verlustfrei in `3d` überführt.
- **Alle Schiffsspieler und NPC-Schiffe** fahren auf demselben globalen 48×32-Rautenraster (Nachbarschritt +/-24,+/-16), mit derselben kollisionsgeprüften Küstenroute und demselben regulären Tempo 76 Weltpixel pro Sekunde bei identischen Spielwerten. Keine Berechnung eines anderen Schiffskurses auf Basis des Anzeige- oder Plattformmodus.
- **Grafikwechsel während der Fahrt** darf weder Schiffsposition, Heading, Kursziel, bisherige Wegpunkte noch einen begonnenen Raster-Schritt oder dessen Fortschritt ändern.

## Behobene Architekturabweichung
Vorher nahm `sea_map._ready` den Grafikmodus `browser_classic` als Steuerungsflag. Der 2D-Pfad lief physisch im 48×32-Raster und sendete `navigation_mode='classic_48x32'`. 3D reaktivierte dagegen mit `set_classic_steering(false)` die alte direkte Navigation mit 165 Weltpixeln/s und sendete den Serverkurs ohne Modushinweis. Deshalb konnten 2D- und 3D-Spieler mit gleicher Zielkoordinate eine andere Spur fahren.

Jetzt ist das Raster selbst die **modeunabhängige Simulationsregel**, voreingestellt `simulation.classic_steering=true`. Die bisherige Methode `set_classic_steering(bool)` bleibt nur für alte Skripte als No-op mit Raster aktiviert; Grafikumschalten ruft sie nicht auf und verändert keinerlei Wegzustand. `sea_map._send_online_course` überträgt für beide Renderer dieselben vorgeplanten Kachel-Wegpunkte mit `navigation_mode='classic_48x32'` und `raster_preexpanded`, sobald eine passende sichere Route vorliegt. Das Test-Backend unterstützt dieses Protokoll mit Classic-Tempo 76 Weltpixel/s.

Die bestehende Classic-Animation, Kamera, Zoom, Schiffsgrößen und Seekartengeometrie sind nicht verändert worden. Im nativen `ship_mesh_layer.gd` gibt es nur noch den tatsächlichen GLB-3D-Modus; der Browser benutzt weiterhin ausschließlich den Atlasrenderer.

## Tests
Browser CI #173: erfolgreich.
- `shared_render_route_test.gd`: 17/17 PASS. Zwei unabhängig initialisierte Schiffe mit identischem Start, Ziel und Geschwindigkeitswert fahren bei jedem 30-Hz-Tick positionsgleich. Zwischendurch wird die native Grafik nach 3D und zurück gewechselt – Route, aktueller Index und Heading bleiben erhalten. Die Online-Kurs-Payloads für 2D und 3D sind identisch, inklusive Waypointliste, Ziel, Modushinweis und vorkalkulierter Route.
- `classic_course_test.gd`: 18/18 PASS. Vier-Nachbar-Küstenumfahrung, kein geradliniger Insel-Fallback, gleichbleibende freie Rasterroute.
- `classic_mode_test.gd`: 2760/2760 PASS.
- `classic_navigation_test.gd`: 27/27 PASS.
- `navigation_test.gd`: 92/92 PASS.
- `simulation_test.gd`: 33/33 PASS.
- `ui_test.gd`: 2213/2213 PASS.
- Python-Backend-Tests: 7 PASS.
- Reales Godot-WebGL-Starten: PASS, ca. 19,4 MB initialer Kaltstarttransfer.

## Grenzen / Nachbereitung
- Das bestätigt eine identische Route **bei gleichen Start- und Zielkoordinaten und gleichen Schiffswerten**. In Formation mit verschiedenen Startpunkten müssen sich die Schiffe auf eine gemeinsame Route einfädeln; sie können nicht zugleich exakt denselben Startschritt zurücklegen.
- Der GitHub-Code des Präsenzservers unterstützt bereits Rasterrouten. Ein tatsächlich von mehreren Geräten erreichbarer Live-Server und Netzwerk-Latenz/Schiffsformationen müssen separat real getestet werden; diese CI-Bestätigung ist kein Beweis für ein erfolgtes Backend-Deployment.
- Browser-Build als GitHub Release verfügbar; eine bestehende Vercel-Produktion darf nur als aktualisiert beworben werden, wenn die tatsächlich ausgelieferte SHA geprüft wurde.
- Die native Datenaktualisierung benötigt die vorhandene Signatur- und Updater-APK mindestens `305903`; keine separate Android-/iOS-Logik für 2D oder 3D.
