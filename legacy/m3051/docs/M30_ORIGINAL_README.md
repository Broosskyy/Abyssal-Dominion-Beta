# SeeFight 3D — M30 (auf vollständigem M29 neu aufgebaut)

Version 0.30.0. Eigenständiges Rekonstruktions-/Testprojekt, kein offizieller Spielclient.
**Windows, macOS, Android und iOS sind die Hauptziele. Web dient nur als Preview.**

## Tatsächlicher Stand

- 18 austauschbare GLB-Platzhalter mit Katalog; Original-Meshes und Texturen bleiben erhalten.
- 6 austauschbare SVG-Grafiken für Einstieg, Wappen und Button-Zustände.
- Splash → lokale Profile / Gast → Startseite → See → Kapitänsmenü → Einstellungen.
- Kompakteres HUD, Arsenal im Querformat, echte scrollbare Menüs, Kamera-Rad und Zentrieren.
- Gespeicherte Grafik-, Audio-, Kamera- und Anzeige-Einstellungen; Wasser-Normalen korrigiert.
- Bestehende M29-Spielmechanik bleibt Basis. M31 und M32 sind **nicht** enthalten.

**Keine 1:1-Grafik oder vollständige Unity-Code-Rückgewinnung.** Die neuen GLBs sind einfache,
eigens erstellte Platzhalter, keine rekonstruierten Originalmodelle. IL2CPP-Metadaten sind keine
vollständigen Funktionsimplementierungen. Der Abstand zum Mockup bleibt erheblich.

## Start und Tests

Projekt über `project.godot` im Godot-Editor importieren und starten. Die Projektvorgabe
bleibt **4.7.2**; Verfügbarkeit und Freigabe dieser Zielversion sind hier nicht bestätigt.
In dieser Umgebung ist nur **4.5.1 stable** verfügbar. Damit wurden ergänzende Headless-
Import-/Laufzeittests durchgeführt; das ist **keine 4.7.2-, Grafik- oder Gerätefreigabe**.

Aktuelles Ergebnis: `docs/m30_current_validation.json`.
Ältere Berichte, Screenshots und Versionsangaben in historischen Dokumenten belegen nicht M30.

```sh
python3 tools/check_m30.py --engine /pfad/zum/godot
# Nur für ausdrücklich ergänzende Tests mit einer anderen Engine:
python3 tools/check_m30.py --engine /pfad/zum/godot --supplementary
```

Preview: `python3 tools/preview.py --godot /pfad/zum/godot` oder `npm start`.
Dafür werden die vorgegebene Engine und passende Web-Export-Templates benötigt.
**Kein vorgebautes M30-Web-Spiel enthalten.** Alte M18-Web-Binaries werden nicht ausgeliefert.
Der Preview-Server ist kein Multiplayer-/Account-Server.

## Bedienung

Meer tippen/klicken: Kurs setzen. Gegner auswählen, dann Feuer. AUTO feuert auf das gewählte
Ziel, verfolgt es aber nicht. Touch-Steuerrad: Kamera verschieben, nicht das Schiff steuern.
Zwei Finger: Zoom; ZENTR: Kamera zum Schiff. Desktop zusätzlich WASD, T und Leertaste.
MENÜ enthält Aufträge, lokale Eventziele, Versorgung, Hilfe, Logbuch, Einstellungen und Heimkehr.

Login/Register sind **passwortlose lokale Profile**, keine Onlinekonten. Gastmodus speichert
keinen Fortschritt. Den internen Projektnamen M28 nicht ändern: Er erhält den tatsächlichen
M29-Spielstandordner. Anzeige und Versionsnummer sind M30.

## Assets tauschen

Siehe `docs/M30_ASSET_SWAP.md`. Modellpfade stehen in
`assets/placeholder_pack/manifest.json`. In den Einstellungen lässt sich für den nächsten
Seestart auf rekonstruierte Referenz-Meshes umschalten.

Das Quellpaket enthält alle Laufzeit-Assets. Das ergänzende Referenzpaket enthält große
historische Analysen und reine Referenzbilder mit unveränderten relativen Pfaden; optional
in denselben Projektordner entpacken. Kein Referenzpaket zum Spielen erforderlich.

## Noch offen

Echte visuelle Abnahme gegen das Mockup, ausmodellierte Schiffe/Inseln und Texturen,
Messungen auf Zielgeräten, native Exporte/Signierung, Online-Auth und Crossplay.
M29-Tages-/Wochenziele sind weiterhin lokale Testzähler ohne kalendarischen Reset.
Keine Store-Reife, Leistungs-/FPS-Garantie oder plattformübergreifende Abnahme.
