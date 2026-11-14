# Classic 344 — Kachelraster-Kurswechsel und langsame Fahrgeschwindigkeit
Date: 2026-11-14

## Anlass
Der Nutzer meldete nach Update 343 weiterhin unpassendes Steuern und deutlich zu hohe Schiffsgeschwindigkeit und zeigte ein 24.39-s-Video (`209058.mp4`, 2340×1080, 59.94 fps) mit sichtbarer Modusanzeige **ADM · TEST · LOKAL**. Der lokale Modus ist ein wichtiger Hinweis, dass die Fehlbewegung nicht nur vom Online-Server kommt.

## Ursachen im vorherigen Code
- Classic nutzte `PLAYER_SPEED=165` world px/s und multiplizierte die physische Geschwindigkeit je Rasterroute nochmals mit `_iso_speed_scale=path_length/direct_length` (bis 2x). Bei 24×16-Schritten waren etwa 0.175 Sekunden pro Schritt vor weiteren Upgrades/Boni möglich, statt einer vergleichsweise ruhigen Rasterfahrt.
- Ein Kurswechsel mitten im Kachelweg begann eine neue Richtung aus den interpolierten Zwischenpixeln des aktuellen Schritts. Diese sind keine legalen 48×32-Kachelzentren.
- Der Klick suchte den euklidisch nächstgelegenen Mittelpunkt, statt das tatsächlich getippte Diamantfeld zu nehmen. Beispiel: `world(15,4)` liegt in der Raute um `(0,0)`, aber ist euklidisch näher am Mittelpunkt `(24,16)` einer Nachbarraute.
- Der Staff-Badge zeigte einen optional aktiven 2.5x-Geschwindigkeitscheat nicht ausdrücklich.

## Umsetzung
- Classic-Kachelgeschwindigkeit auf `CLASSIC_TILE_SAIL_SPEED=76.0` px/s reduziert. Eine 24×16-Diagonale ist 28.844 Einheiten lang und dauert bei normaler Grundgeschwindigkeit ~0.380 s. Upgrades bleiben berücksichtigt, aber auf max. ×1.35 beschränkt. Die automatische Umweg-Beschleunigung ist entfernt. Native 2.5D/3D-Bewegung bleibt unverändert.
- Normierte Diamantkachelzuordnung über `abs(dx)/24 + abs(dy)/16` statt euklidischer Metrik. Nur bei blockierter ausgewählter Raute wird nach einem befahrbaren Nachbarn gesucht.
- Wechselt ein Spieler während einer begonnenen Rasterfahrt das Ziel, schließt er **nur den bereits begonnenen Tile-Schritt** bis zum nächsten globalen Kachelmittelpunkt ab. Danach fährt er ohne Kreiswenden, Teleport und zusätzliche Zwischenpixel-Diagonale den neu berechneten Weg.
- Die gleiche atomare Kachelregel gilt für durch Skripte/AI direkt ersetzte Pfade. Bereits off-grid gespeicherte Spawnpositionen werden in einem kurzen animierten Ausgleich zum globalen Kachelzentrum gefahren; kein Teleport.
- HUD-Badge ergänzt `TEMPO-BOOST ×2,5`, falls Staff-Speed tatsächlich aktiv ist; die Anzeige `ADM TEST LOKAL` allein bedeutet nicht automatisch einen Boost.
- Optionale Python-Onlinepräsenz wurde ebenfalls auf 76 px/s für Classic korrigiert; unveränderte Native-Modi bleiben bei 165 px/s. Das laufende Backend muss separat aktualisiert werden, bevor online die neue Geschwindigkeitsvorgabe greift.

## Verifikation und Grenzen
- Entwicklung: GitHub Actions Browser Run #152 erfolgreich (Godot 4.7.2, echte 23 gerenderte GLB-Atlanten, Classic-/UI-/Navigationstests, WebGL-Lauftest); 2,760 Classic-Checks PASS, 7 Python-Backend-Tests PASS.
- Zusätzliche rechnerische Kontrolle: 100,000 zufällige Welt-Klickpunkte wurden den tatsächlichen globalen Rasterdiamanten zugeordnet, ohne geometrische Lücken.
- Integration: GitHub PR #60 nach erfolgreicher CI nach `main` gemergt.
- WICHTIG: **Dies ist eine technisch geprüfte Korrektur**, keine Beweisführung, dass die proprietären historischen Seafight-Algorithmen exakt rekonstruiert sind. Ein Echtgerätevergleich bleibt erforderlich.
