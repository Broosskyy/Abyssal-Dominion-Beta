# M17 — Zielkampf, Bergung und Beutedarstellung

Weiterentwicklung der M16-Ausgabe mit Godot **4.7.2 stable**, Projektversion
**0.17.0**. Eigenständiges SeeFight-Rekonstruktionsprojekt, nicht Abyssal Dominion.
Die Schiffe, Inseln, bisherigen Materialien, Profile und Spielstände bleiben erhalten.

## Implementiert

- Gegnerauswahl durch Tippen/Klicken innerhalb 36 Viewport-Einheiten um die
  projizierte Rumpfmitte. Bei mehreren Kandidaten gewinnt der nächstgelegene
  Bildschirmanker. Auswahl bewegt das Schiff nicht zu einem neuen Fahrpunkt.
  Bestehender Kurs bleibt erhalten. T/Zielbutton wechselt weiterhin das Ziel.
- Ausgewählte Salven richten ihre realen Projektile auf die aktuelle Zielposition.
  Ohne Auswahl bleibt die bisherige seitliche Salve erhalten. Kein Homing,
  kein garantierter Treffer und keine neue Zielverfolgungs-Navigation.
- Angriffszustand unterscheidet bereit, Nachladen, zu weit entfernt, kein Ziel,
  leere Munition, Menü offen und Hafenschutz. Desktop zeigt Distanz/Reichweite;
  kompakte Ansichten zeigen den Status. Minimap hebt das Ziel zusätzlich hervor.
- Sichtbarer AUTO-Button: explizit einschaltbares Dauerfeuer auf genau das
  ausgewählte Ziel. Reichweite folgt Projektilgeschwindigkeit und Lebenszeit
  mit Sicherheitsabstand. Normale Salvenkosten, Schaden und Kollisionsobjekte.
- Außer Reichweite pausiert AUTO ohne Munition zu verbrauchen. Kein automatischer
  Zielwechsel. Zielverlust, Versinken, Hafenschutz, Menüs oder leere Munition
  schalten AUTO aus. Bewusstes erneutes Einschalten erforderlich.
- Goldene Holztruhen und grüne Reparaturkisten ersetzen einfache Münzscheiben.
  Langsames Drehen, Schwimmen und emissive Metallbänder/Halo. Emission behauptet
  kein Bloom: Compatibility-Ausgabe muss noch visuell geprüft werden.
- Beute erscheint auf der Minimap; Lifetime 45 statt 18 Sekunden. Einsammeln
  meldet tatsächliches Gold oder tatsächlich wiederhergestellte Rumpfpunkte.
  Doppelter Kontakt zahlt nicht mehrfach aus. Reparatur bleibt direkte Heilung,
  kein zusätzlicher Inventarverbrauchsgegenstand.

## Ressourcenoptimierung

Alle neuen Beutekörper teilen einen BoxMesh, einen niedrig aufgelösten TorusMesh
und drei Materialressourcen. Keine Lichter/Partikelemitter pro Truhe, keine
Schattenwürfe der Kleinteile. Pro Goldtruhe sechs Mesh-Instanzen, Reparaturkiste
acht. Das erhöht gegenüber einer Scheibe die Geometrie; eine FPS-Verbesserung
wird nicht behauptet. Der Test prüft Mesh-/Materialwiederverwendung.

Die gemeinsame HUD-Geometrie berücksichtigt den neuen AUTO-Button. Bestehende
M16-Layouttests prüfen dadurch mehr Kombinationen: 829 statt 741 Assertions,
ohne alte Erwartungen zu entfernen. Neue Statusflächen werden von Namens- und
Schadensanzeigen sowie der Fahrpunkteingabe ausgespart.

## Bezug zu Originaldaten und Referenzen

In `docs/il2cpp/Assembly-CSharp.metadata-skeleton.cs` sind Ziel-/Angriffskonzepte
wie `SetCurrentSelectedTargetId`, `IsOnAttackRange`, `GetDistanceFromTarget` und
`StopAttack` vorhanden. Die exakten Methodenrümpfe, Reichweitenformeln und
Serverregeln sind daraus nicht zurückgewonnen. M17 ist eine eigene Godot-Logik.

`docs/unity_asset_catalog.csv` führt unter anderem ChestCollision, ChestSpawner,
ChestRewardGenerator sowie Dagon-chest-Texturen auf. Die neuen Beutemodelle sind
**native Ersatzgrafiken**, keine neu extrahierten Original-Truhen. Eine belastbare
Mesh-/Materialzuordnung dieser Original-Truhen bleibt ein weiterer Arbeitsschritt.

Der Nutzer-Mockup bleibt visuelle Richtung. Für Genre-Kontext wurden offizielle
Seiten von [Battle of Sea](https://www.battleofsea.com/en/),
[Terror of Sea](https://www.terrorofsea.com/) und
[Legend Pirates](https://www.legendpirates.com/) sowie das
[Seafight-Forum](https://board-en.seafight.com/) geprüft. Diese Vergleiche belegen
keine 1:1-Übereinstimmung der hier gewählten Mechanik. „Sea of War“ ließ sich
nicht eindeutig dem gemeinten Spiel zuordnen; dafür werden keine Details behauptet.

## Prüfung und Grenzen

- Godot 4.7.2 Import + M10–M17-Suiten: **1.280 / 1.280 bestanden**.
  Darin 78 neue M17-Prüfungen plus 829 aktuelle M16-HUD-Prüfungen.
- Python Preview-Tests: **12 / 12**, statischer Plattformvertrag **19 / 19**.
- Web-Build mit 4.7.2-Templates neu exportiert; aktuelle HTTP-Auslieferung,
  Versionsstempel und WASM-MIME geprüft.
- Browseraufnahme versucht, aber Chromium fehlt weiterhin. Keine aktuelle
  Bildschirmabnahme, kein M17-Screenshot und keine gemessenen Mobile-FPS.

Nachweise: `m17_engine_validation.json`, zugehörige Logs,
`m17_http_validation.json`, `qa_m17/capture_report.json`.

Zielauswahl arbeitet mit Bildschirmnähe und ist kein präziser sichtbarer
Mesh-Raytest. Sehr dicht stehende oder verdeckte Schiffe bleiben ein UX-Prüfpunkt.
Der 36px-Bereich ersetzt keine gesonderten nativen Gerätetests.
Keine neue Festung, kein Kraken, keine neuen Schiffs-/Inselmodelle, kein
Gilden-/PvP-Backend und kein fertiges Crossplay. Keine neue APK/IPA oder Signierung.

Nächste sinnvolle Arbeit: echte Bildschirm-/Touch-Abnahme, Original-Truhenzuordnung,
präzisere Auswahl verdeckter Schiffe und weitere Hafen-/Auftragsdarstellung.
