# M393 – 39 freigestellte Inselreferenzen aus 10 gelieferten Bildtafeln

## Was heute **tatsächlich** entstanden ist

Die zehn vom Entwickler bereitgestellten transparenten Referenztafeln `209629.png`, `209640.png`, `209641.png`, `209642.png`, `209647.png`, `209648.png`, `209649.png`, `209695.png`, `209704.png` und `209809.png` wurden mithilfe eines nachvollziehbaren Alpha-Komponenten-Verfahrens in **39 einzelne transparente Sprite-Dateien** zerlegt, ohne die originalen Inselmotive zu verändern.

| Material | Einzel-PNGs | Rolle |
|---|---:|---|
| Reguläre Inselkandidaten | 18 | Für den bestehenden M392-Inselkatalog vorgesehen |
| Gildeninsel-Varianten | 5 | Inseln mit offener Hafeneinfahrt, noch kein geprüfter Gameplay-Einbau |
| Einzelne Gildentürme | 5 | Separate Türmgrafiken, zerstörbar/platzierbar erst nach Integration |
| Event-/Spezialinseln | 11 | Vulkan, Winter/Weihnachten, Blüten und Friedhof |
| **Gesamt** | **39** | **Noch nicht final abgenommene Referenzsprites** |

Der voll aufbereitete Sprite-Ordner mit Einzel-PNGs, kontaktbasierten Vorschauen, CSV, SHA256-Manifest und automatisierten Alpha-Außenkonturen wurde als ZIP **in der Chat-Konversation ausgeliefert**. **Die Binärdateien liegen noch NICHT im GitHub-Repository.** Diese Dokumentation und `assets/visuals/m393_reference_candidates.json` sind zunächst nur die verlässliche Zuordnung und ein vorbereiteter Importauftrag. Bitte keine PNG-Platzhalter oder nicht vorhandenen Dateien als vorhanden markieren.

## Echte Abdeckung des 30er-Katalogs

Aktuell gibt es aus den gelieferten Bildern **Kandidaten** für genau diese **14 unterschiedlichen M392-IDs**:

- **A / Küstenbuchten:** A01, A02, A03, A04, A05, A06 – 6 von 6 haben mindestens eine Vorlage.
- **B / Handelsmeer:** B02, B03, B04, B06 – 4 von 6 haben eine Vorlage. Es fehlen spezifische B01-Lotseninsel und B05-bewachsene Felseninsel.
- **C / Nordmeer:** C01–C06 – **0 von 6** regulären, *nicht saisonal dekorierten* Inseln. Die vier Weihnachtsinseln im Paket sind Event-Assets, kein generischer Nordmeerersatz.
- **D / Kriegsgewässer:** D01–D06 – **0 von 6** freigegebene reguläre Inseln. Fünf Gildeninseln und fünf Gildentürme sind vorhanden, gehören aber in das separate Gildenfestungssystem, nicht automatisch in D06.
- **E / Tiefenmeer:** E03–E06 – 4 von 6 haben Vorlagen. E01/E02 als kleinere natürliche Felsenformen fehlen.

**Nicht mit Fertigstellung verwechseln:** 14/30 bedeutet *visuelle Kandidaten-Zuordnung*, nicht 14 geprüfte Spiel-Assets. **0/30** haben aktuell M392-Status `approved`.

## Qualitätssicherung

- Alle 39 PNGs haben echte Transparenz, freigestellte Einzelobjekte, eindeutige Namen und SHA256-Werte.
- Das Skript erhält den Original-Alphakanal und ordnet lose Nachbarfelsen nach der nächstgelegenen Objektmaske zu. Die Rohquellen bleiben unverändert.
- **10 von 39** benötigen besondere Sichtkontrolle, da das Motiv im Originalblatt sehr nah an einer Bildkante liegt oder diese berührt.
- 34 automatisch erfasste Objekt-**Außenkonturen** sind als Hilfsdaten enthalten; sie sind ausdrücklich **keine geprüften Wasserlinien-Kollisionen**.
- Ein offener Karten-/Hafeneingang wird nicht durch eine grobe Außenkontur verschlossen. Vor Freigabe muss die echte Schiffsfahrt im Godot-Raster erfolgreich sein.
- Keine neue Grafik wurde in `sea_map.gd` aktiviert, keine M376-Fahrbewegung, Serverposition, Spielerstände, Bonuskarten oder alte Seekarten verändert.
- Keine Vercel-Deployments. Kein kostenpflichtiges API-Aufladen oder fremde Bildquelle nötig.

## Nächster konkreter Einbauschritt

1. Binärpaket aus dieser Chat-Konversation in die lokale Entwicklungsumgebung übernehmen; `extract_islands.py` im ZIP reproduziert alle 39 Zuschnitte aus den Originaltafeln.
2. **Zuerst A01 und B02** in zwei kleinen, isolierten Testgebieten mit bestehendem Schiff und Zoom prüfen. Qualität/Größe/Kamera festlegen. Danach alle übrigen A- und B-Assets.
3. Für jede Grafik in `M392` separat die tatsächliche schiffbare Küstenlinie zeichnen, Einfahrten testen und PNG+Kollisions-JSON mit Hashes gemeinsam reviewen.
4. **Erst nach erfolgreicher Prüfung** die jeweiligen M392-IDs von `planned` auf `approved` setzen. Bis dahin Fallback-Texturen beibehalten.
5. Parallel **sechs normale Nordmeer-Inseln und sechs reguläre Kriegsgewässer-Inseln** im vorgegebenen Renderstil produzieren. Event-/Gildeninseln dafür nicht zweckentfremden.
6. 2D-Browser und 3D-App auf identische Wasser-/Kollisionkoordinaten prüfen. Android-App-Datenupdate erst nach bestandenem Build und ohne automatische Vercel-Veröffentlichung.

Die nächste motivierende, überprüfbare Etappe ist **eine** sauber eingebundene neue Insel, die man im Spiel umfahren kann, statt ein weiterer technischer Masterplan ohne sichtbare Grafik.
