# Abyssal Dominion — M303.5 Visual/Core Integration
29 October 2026 — branch: `rebuild/classic-seafight-m303`

## Zielbild
*SeaBattles: Pirate War* 1.24.0 dient als Haupt-Referenz für Bildschirmwirkung: klassisch schräge Seekarte, kleine Schiffe, NPCs, Inselumrisse, Namen und Trefferpunkte, kreisförmige Minimap sowie klar getrennte Bedienbereiche. Spiellogik, Grafik und Backend bleiben voneinander getrennt.

**Aktuell geliefert:** Godot-4.7.2-Quellstand auf GitHub, Bootszene auf `scripts/classic/m3035_seabattles_core.gd` umgestellt; Stand ist nicht als APK/Android-Release getestet. Die öffentliche Version enthält **keine** APK-Originalgrafiken.

## Boot- und Fullscreen-Status
- `project.godot`: Startszene `scenes/classic/classic_sea_map.tscn`, `0.303.5`, `window/size/mode=3` (Fullscreen), `window/handheld/orientation=4` (sensor landscape).
- `m3034_fullscreen_sea_map.gd` stellt die gesonderte, responsive Querformat-HUD-Implementierung bereit, mit großen Touchflächen, Minimap oben rechts, Kamerabedienung unten links, Kampfbedienung unten rechts und Hochformat-Hinweis.
- `m3035_seabattles_core.gd` führt ein grafisches Umschaltmenü ein. Das Wechseln startet die lokale Testszene neu (Testfortschritt wird nicht gesichert).

## Sprite-/3D-Grafiksystem
`m3035_render_adapter.gd` lädt lokal vorhandene private PNG-Dateien automatisch:
- `assets/classic/private_seabattles/ships/elite8.png` (Spieler),
- `ships/warship.png`, `ships/pinnace.png`, `ships/flyingdutchman.png` (NPCs),
- `islands/snow.png`, `islands/rock.png`, `islands/tropical.png`.
- Standardannahme vor echter Richtungs-QA: **8 Ansichten als 4 Spalten × 2 Zeilen**. Diese Anordnung wurde aus einer zuvor erzeugten Unity-Diagnosevorschau abgeleitet. Der exakte Frame-Order und die Texturfarben sind noch nicht bestätigt. Daher Rotations-Abnahme erforderlich.

Für die Hauptschiffe nutzt der Adapter `Sprite3D` im bisherigen Godot-Weltkoordinatensystem (nicht einen komplett neuen 2D-Motor). Dadurch bleiben Routen, Navigation, Kamera und Kampf gleich, wenn später echte 3D-GLBs eingesetzt werden. Ohne die privaten Dateien: vorhandene eigene 16-Richtungs-Platzhalter bzw. M302-GLB-Modelle.

**Grafikschalter:** `APK-TEST` → `3D` → `2D`. Bei `APK-TEST` fällt die Darstellung automatisch auf die bisherigen 2D-Platzhalter zurück, solange keine private PNG-Datei eingebunden ist. Keine falsche Behauptung, dass die Originalgrafik bereits sichtbar ist.

## So werden die vom Nutzer gelieferten APK-Ressourcen lokal vorbereitet
```bash
python -m pip install UnityPy Pillow
python tools/import_seabattles_local.py "SeaBattles (1.24.0).apks"
```
Das Offline-Werkzeug extrahiert ausgewählte Unity-Texture2D-Grafiken in das **gitignorierte** Verzeichnis `assets/classic/private_seabattles`, schreibt ein `scan_report.json` und führt keine App aus. Eine ETC2-Decodierung kann je nach Texture-Version fehlschlagen oder Farbverschiebungen liefern; in diesem Fall bitte nicht als akzeptierte Endgrafik markieren. Außerhalb der vier bekannten Schiffsnamen werden weitere Grafiken zunächst nur inventarisiert, nicht automatisch als finale Assets gemappt.

## Aus M302 wiederverwendet / bewusst NICHT übernommen
| M302-Teil | M303.5 |
|---|---|
| Schiffsbewegung / Motor `ship_motor.gd` | Beschleunigungsrampe, sanfte Drehung portiert; keine PlayerInventory-Abhängigkeiten |
| `camera_rig.gd` | weiches Follow/Zoom-Pan-Konzept; neue simple orthographische Kamera |
| `player_input.gd` | Tap-to-Sail; direkte Weltkoordinaten, kontrollierte UI-Tap-Erkennung |
| `ship_weapons.gd` | manuelle/automatische Kanonen, Harpunen als separate Spielmodi |
| M287 / `ship_wake.gd` | lediglich zurückhaltendes, visuelles Heck-Kielwasser; keine große weiße Fan-VFX |
| M268/M267 online | NICHT aktiv; keine echten Netzwerk-Positionen, Auth oder Combat-Rewards |

## Noch offene QA
- Godot 4.7.2 Godot-Import/Parser, native Android und Web-Export müssen wirklich ausgeführt und bestätigt werden; keine Behauptung eines APK/Browser-PASS.
- Nach Import muss Sprite-Atlas (4×2) auf transparente Frames, richtiger Formatdecoder, Orientierung, Ankerpunkte und Proportionen geprüft werden.
- Auf einem Samsung im Querformat: Systemleisten, Sichtbereiche, Minimap, Kamerakontrolle, alle Touchflächen, Beute/NPC-Kampf, Inselnavigation prüfen.
- Bei grafischen Inseln muss der sichtbare Umriss zur Navigationsbarriere passen; feste Kreisradien sind nur die initiale Testnäherung.

## Rechte und Quellen
Die ursprünglich vom Nutzer bereitgestellten SeaBattles-APK-Dateien dürfen als technische Referenzen untersucht werden. Dass die Originalgrafik privat betrachtet wird, klärt mögliche Nutzungsrechte nicht automatisch. Das öffentliche Repository enthält nur eigenständige Platzhalter und Code für die lokale Einbindung; ein späterer öffentlicher Build benötigt eigenständige oder entsprechend lizenzierte Grafikressourcen.
