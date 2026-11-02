# M32 — feste Anfängerprogression

## Auftrag und Umfang

Die freie M31-Starterwahl war falsch. Neue Kapitäne beginnen mit dem kleinen Schiff;
mittleres und großes Anfängerschiff werden innerhalb der ersten fünf Kartenlevel erspielt.
Die Elite-/Hauptdesignreihe folgt danach, vorläufig ab Kartenlevel 6, nicht Piratenlevel 6.

- BeginnerRules bündelt Startschiff, fünf Abschnitte, Ziele und Belohnungen.
- Swift Barco ist das einzige neue Startschiff, auch im Gastmodus und in der Startvorschau.
- Alle drei bestehenden Designs sind Anfängerdesigns. Unbesessene Designs zeigen
  ihre Aufgabe und können weder kostenlos noch mit Gold vorzeitig ausgerüstet werden.
- Fünf sequenzielle Aufträge ersetzen die einzige M31-Prüfung. Start und Abgabe im Hafen;
  Kämpfe/Beute auf dem jeweiligen Kartenlevel, Rückkehr erst nach diesen Zielen.
- Mittleres Schiff nach Auftrag 1, großes nach Auftrag 5; ohne Kaufkosten.
  Schiffswechsel bleibt eine bewusste Hafenaktion.
- Kartenfreigabe 1–6: Sektoren nutzen ihre level-Werte, nicht Kartennamen/Piraten-/Schiffslevel.
  Kartenlevel 7+ bleibt für neue Profile gesperrt.
- Erster Abschluss schaltet AUTO frei; AUTO fährt weiterhin nicht hinter Zielen her.
- Elite-Einstieg ist als Abfrage vorbereitet. Keine vorgetäuschte fertige Elite-Flotte.
- UI: keine Starterauswahl, Hafenaktion AUSRÜSTEN, Menü Kartenfortschritt erklärt Standort,
  Freigabe, getrennte Level, Ziele, Belohnungen und den Stand der Elite-Reihe.
- Kompakte Startseite verzichtet auf längeren Erklärungstext zugunsten des Play-Zugangs.

## Testwerte, keine nachgewiesenen Originalregeln

Pro Abschnitt 3 Versenkungen + 2 Bergungen + 1 Hafenrückkehr; 300 Gold + 120 XP.
Clipper nach Abschnitt 1, Chalupa nach Abschnitt 5, Elite-Grenze 6.
Der bestehende Piratenlevel-Bonus wird bei entsprechendem XP-Aufstieg zusätzlich vergeben.
Die Werte stehen zentral in scripts/progression/beginner_rules.gd.

## Migration und Schutz

m32_version: 1 im unverändert prüfsummengeschützten Save-Envelope.
Voyage speichert beginner_version: 1 und completed_trials. Zähler werden begrenzt;
abgeschlossene Anfängerphasen können nicht als aktive Aufträge geladen werden.
Spätere unbekannte m32_version-Werte werden abgewiesen.

M31-Prüfung bestanden → ein erledigter Auftrag. M31-Prüfung aktiv → erster Auftrag aktiv.
Schiffsgeschenke werden idempotent ergänzt, ohne Gold-/XP-Wiederholung und ohne
automatischen Wechsel. Bereits besessene Schiffe und eigene Designfortschritte bleiben.
Alter M30-Zugang bleibt als legacy_access separat erhalten und erzeugt keinen Elitefortschritt.

Schreibtests nutzen zufällig benannte Fixtures; nur diese werden entfernt.
Keine echten Nutzerdateien wurden verändert. Defekte Saves und gute Backups bleiben geschützt.

## Verifikation und Grenzen

Aktueller Nachweis: m32_current_validation.json und m32_*.log.
Runner: GLB-Integrität, Editorimport, M30-Regression, M31-Regression, M32-Laufzeitsuite.
M31-Ausrüstungstests verwenden jetzt explizit einen migrierten Flotten-Teststand;
die falsche freie Starterwahl ist keine Voraussetzung mehr.

M32 prüft Startschiff/Startseite, alle fünf Aufträge, alle Sektor-Gates, Kauf-/XP-Bypass,
passendes Kartenlevel, Hafenrückkehr, Sinken, Einmalbelohnung, eigene Designlevel,
Save/Load, vollständige M32-Dateien und M30/M31-Migration.
Die Kette wird mit kontrollierten Spielereignissen getestet: kein Ersatz für einen
manuellen Spieldurchlauf mit Navigation, Gegnerbalance und realer Spielzeit.

Nur ergänzend Godot 4.5.1 headless. Keine 4.7.2-/GPU-/Geräte-Abnahme.
Keine neuen finalen Modelle, kein neues Wasser, keine neue Routenplanung,
keine vollständige Elite-Reihe und keine Online-Serverimplementierung.
Das Mockup wird nicht als Laufzeitbild ausgegeben.
