# M3082 – Drei neue echte GLB-Spielerschiffe

Der Spieler kann aus 30 Designs wählen. Die ursprünglichen 27 sind unverändert.
Die neuen Schiffe befinden sich in der Werft (AUSRÜSTEN ohne Goldkosten):
- Skin **27**, \`Crimson Voyager · Startschiff\`: neue Kapitäne starten mit diesem
  Schiff, **sobald das vollständige Original-GLB eingebunden ist**.
- Skin **28**, \`TEST · Totenkopf-Galeere\`: großes rotschwarzes Piraten-Testschiff.
- Skin **29**, \`TEST · Schattenkriegsschiff\`: großes schwarzes Boss-Testschiff.

Alte Save-Dateien werden nicht überschrieben, weder Name/ID noch
Spielerposition, Gold, Fortschritt oder aktuelle Schiffsauswahl.
Beim Wechsel in der Werft ändern sich ausschließlich Aussehen und Modellmaß
(in der Seekarte); keine zusätzlichen HP oder Kanonen.

**Technik:** Hybrid- und 3D-Ansicht instanziieren originale GLB-Geometrie im
SubViewport auch für Spieler-ID 0; beim Classic-Modus werden 8 real aus dem
GLB gerenderte transparente Sprites verwendet. Die Z-Achsen-Modelle werden um
90° lokal in die gleiche Bugrichtung wie die bestehende Flotte gedreht.
Das bereits vorhandene Nine-Ship-NPC-Set wird nicht verändert.

## Binär-Dateien aktivieren

Die drei GLBs sind absichtlich nicht über die Text-API geschrieben.
Lade **beide** Dateien direkt auf GitHub \`Broosskyy/Abyssal-Dominion-Beta\`,
Branch \`main\`, hoch (genau diese Dateinamen im Repo-Hauptverzeichnis):

- \`Abyssal_Dominion_M3082_Testschiffe_Teil_1_von_2.zip\`
- \`Abyssal_Dominion_M3082_Testschiffe_Teil_2_von_2.zip\`

Beide Archive sind unter 25 MB, enthalten die Originalgeometrie und
sechs aus den Modellen gerenderte transparente PNGs. Der Workflow
\`.github/workflows/m3082-import-test-ships.yml\` prüft Dateien, Texturen,
Modellgeometrie und SHA-256, entpackt die Ressourcen direkt nach
\`rebuild/m3052/assets/player/test_ships/\` und pusht sie auf \`main\`.
Er löst anschließend den bestehenden signierten Datenbuild aus.

**Nicht als abgeschlossen betrachten**, bevor der Import-Workflow *und*
der nachfolgende signierte Datenbuild erfolgreich sind. Bei teilweisem
Upload zeigen bestehende Installationen weiterhin ihre bisherigen Schiffe.
