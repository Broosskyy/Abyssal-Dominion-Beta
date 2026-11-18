# M394 – Erste echte spielbare Insel: A01

**Ziel:** Aus einem echten vom Benutzer hochgeladenen Originalbild wird das erste überprüfbare, spielbare Inselasset. Keine erneute ImageGen-Substitution.

## Original und Material

- Originaltafel: `209642.png`, vom Benutzer in dieser Unterhaltung bereitgestellt.
- Aufgeteilte Referenz: `209642_01_tropical_spire_islet.png` (M393).
- Freigestellte und für Mobile/Web optimierte **512×512 RGBA-PNG**: `rebuild/m3052/assets/m392/islands/a01.png`.
- PNG SHA256: `52ac3bd963cde48f5ca7d5f1707c8d16f65419394b2d24c59a1b9b3bb899b442`.
- Passende **20-Punkte-Wasserlinien-Kollision**: `rebuild/m3052/assets/m392/collision/a01.json`.
- Polygon SHA256: `ce4d7255a3fb0a7447c6047b63ea7c90e7ce38dec9e29289189b6a957e189516`.
- Stil: originalgetreu, tropisches kleines Felsen-Eiland mit langer vertikaler Felsnadel, zwei Palmen und erkennbarer Sandscholle. Aus Nutzerbild extrahiert, NICHT aus fremdem Bild-/Stockkatalog.

## Kollision und Rendering

Die sichtbare Felsnadel wird **nicht** als zusätzliches quer über das Wasser ragendes physisches Hindernis gewertet. Die 20 normalisierten Küstenpunkte beschreiben nur die schiffbare untere Strand-/Felsgrundfläche. Das Spiel skaliert diese Punkte mit **derselben exakten Bildgröße und Position**, mit der es das isolierte PNG an die Seekarte zeichnet (`Vector2(.5,.65)` Bildanker). PNG und Kollision werden über M392-Audits, SHA256 und eingebettete signed-data-Metadaten gemeinsam freigeschaltet.

- **Nur A01 ist approved**. Die übrigen 29 Insel-IDs behalten bis zur späteren Abnahme automatisch ihre bisherigen verlässlichen Grafik- und Kollisions-Fallbacks.
- Das PNG wird vom Renderer einmalig vorgeladen, um auch in Android/WebGL exportiert und sofort darstellbar zu sein.
- Betroffen sind nur die **freiwilligen neuen Reviere 1–4** im 20-Reviere-Beta. Die historischen 40 Maps, Guild-Buchten und Bonusmaps werden nicht angepasst.
- Kein Einfluss auf M376-Rasterfahrt, 2D-/3D-Weltkoordinaten, Multiplayer, NPC-Damage, Belohnungen, Save-Schema oder Commerce.
- Ein visuell gefärbtes Overlay `A01_coastline_review.jpg` und die ursprüngliche transparente RGBA-PNG liegen zusätzlich im herunterladbaren Chat-Testpaket.

## Validierung und Abnahme

**Automatische Inselprüfung:** M392-Validator muss A01 als einzeln genehmigtes Artwork bestätigen und kontrolliert PNG-SHA256, RGBA-Alphakanal, Transparenzfläche, sichere Außenränder, Pixelauflösung, Polygon-SHA256, Polygon-Eigenkreuzungen sowie die Überdeckung der durchsichtigen Wasserzone. Die Strandpolygon-Abdeckung betrug lokal etwa **89 % opake PNG-Pixel**.

**Godot-Mobil-/Gameplay-QA:** Neue `tests/m394_first_island_test.gd` prüft echte Engine-Textur, 20 Küstenpunkte, 4 Region-A-Seekarten, die vorhandenen Randübergänge, START→Hafen, blockierte Strandmitte, **sicheren Umfahrungskurs links→rechts** und jede daraus gebildete Kursstrecke, alte 40er-Welt, Bonuskarten und Wiederherstellung alter Saves. Kamerafokus wird für das wirkliche Draw-Cache geprüft.

**Echter Spiel-Screenshot:** `tests/m394_island_capture.gd` nimmt die Insel direkt aus dem Godot-Spiel in Landscape und kleinem Mobil-Viewport auf. Die CI hängt beide PNGs als GitHub-Actions-Artefakt **Abyssal-M394-A01-real-game-screenshots** an – keine erfundenen Mockups.

**Release-Regeln:** Nur nach grünem Browser-Godot-Export, M394- und allen bisherigen Tests in den Hauptbranch. Dann via bestehendem GitHub-Signierworkflow das automatische Android-Datenupdate veröffentlichen. **Kein Vercel-Deployment** und keine neue native APK, sofern Bootstrap-Hash unverändert bleibt.

## Nächste visuelle Etappe

A02, A03, A04, A05, A06 jeweils einzeln aus den vom Benutzer bereits gelieferten Originaltafeln als echte freigestellte PNGs und eigene schiffbare Küstenpolygon-Flächen einbauen. Die Hafenbuchten A05 nur mit echter freier Einfahrt und Schiffstest aktivieren.
