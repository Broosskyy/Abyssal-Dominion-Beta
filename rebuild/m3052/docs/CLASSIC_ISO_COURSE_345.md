# Classic 345 — Kursfindung auf demselben 48×32-Raster wie die Schiffsbewegung
Datum: 14. November 2026

## Nutzerfeedback
Nach Update 344 ist die **Schiffsbewegung korrekt**, aber die Kurssetzung und tatsächliche Route sind teilweise noch unpassend. Die als korrekt bestätigten Schiffssprites, Animationen, 76 Weltpixel/Sekunde, Zoom und Kameramodus dürfen deshalb nicht verändert werden.

## Technische Ursache
Bis 344 setzte `simulation.gd::plan_path` auf ein quadratisches 48×48-AStarGrid2D und glättete die Inselumfahrung zu beliebigen Weltkoordinaten. Die danach in `_move_classic_tiles` berechneten Schritte liegen jedoch auf einem **weltweit festen 48×32-Rautenraster** mit vier direkten 24×16-Nachbarn. Sobald eine gerasterte Teilstrecke die Küste berührte, fiel der alte Code auf `tiles=[goal]` zurück: ein gerades Fahrstück, das der gewählten Rasterfahrtrichtung und Animation nicht entsprach. Außerdem hatte der Online-Sender die Route erneut selbst ermittelt und konnte diese Gerade wiederherstellen.

## Umsetzung
1. `navigation.gd::classic_safe_route(start,goal,segment_clear)` behält exakt die bewährte Greedy-Kursfolge aus Update 344, **wenn sie vollständig befahrbar ist**. Bei blockierten Kachelschritten benutzt sie eine echte Vier-Nachbar-A*-Suche auf demselben festen 48×32-Isometrieraster mit Min-Heap und Manhattan-Heuristik in q/r-Kachelkoordinaten. Jede Kachelkante wird vor Befahrung mit der tatsächlichen Insel-/Küsten-Kollisionsfunktion geprüft; max. 16.000 untersuchte Kacheln.
2. `simulation.gd::course(point,true)` bestimmt die komplette gerasterte Route bereits bei Kurssetzung. Ein Retap während eines angefangenen Kachelschritts plant von dessen festem **nächstem** Kachelzentrum, nicht vom Zwischenpixel. Falls kein sicherer Weg existiert, bleibt der bisherige Kurs erhalten und die Nachricht lautet „Küste voraus · kein befahrbarer Rasterkurs“.
3. Die falsche Fallback-Gerade wurde auch für NPCs sowie geskriptete Hafen-/Portal-Kurse entfernt: Bei einem blockierten Rastersegment muss eine sichere Vier-Nachbar-Route gefunden werden oder der Kurs wird abgebrochen.
4. `sea_map.gd::_send_online_course` nutzt die identische, bereits kollisionsgeprüfte vollständige Spielerroute statt den Weg unabhängig erneut als Zickzack oder Gerade zu konstruieren. Der optional bereits begonnene Schritt wird vorangestellt.
5. Die historischen 48×32-Atlasansichten, physische Bewegungsgeschwindigkeit (76 px/s), 30-Hz-Interpolation und mobile Kamerakalibrierung von 344 bleiben unverändert.

## Tests und Einschränkungen
- GitHub Actions Browser-CI #160 erfolgreich: `classic_course_test.gd` prüft 18 Aspekte, darunter 344-Kursfolge unverändert auf offener See, reale Küstenbarriere, ausschließlich 24×16-Schritte um Hindernisse, spielbereite NPC-Kurse, vollständige simulierte Ankunft und Mid-Tile-Retap. Alle 18 PASS.
- Die bisherigen 2.760 Classic-Modus-Checks, 27 Kurs-/UI-Checks und weitere 91 Navigationschecks sowie vollständige Godot-Grafik-/WebGL-Regressionstests bestanden.
- Technische Prüfungen beweisen die Rastergeometrie und die Sicherheit der Kursumfahrung, nicht eine vollständige Rekonstruktion proprietären Original-Seafight-Quellcodes.
- Bei Online-Kursen bleibt der jeweilige externe Präsenzserver autoritativ für die Position; reale Crossplay-Gerätetests müssen das Zusammenspiel weiterhin bestätigen.
