# M31 — lokaler Progressions- und Kampfabschnitt

Basis ist das verifizierte M30-Paket, nicht der beschädigte frühere M31-Upload.
Keine Vermischung mit Abyssal Dominion oder Loot Launch. Mockup bleibt visuelles
Ziel; dieser Meilenstein liefert hauptsächlich zusammenhängende Spielsysteme.

## Implementiert und verbunden

| System | M31-Verhalten |
| --- | --- |
| Starter | Clipper / Swift Barco / Iron Chalupa, einmalig vor dem ersten Seestart wählbar; bestehende Profile behalten ihr Schiff |
| Piratenfortschritt | Bestehendes Level/XP/Gold bleibt bestehen |
| Schiffsfortschritt | Je Design Level 1–10; 150 × aktuelle Stufe XP zum nächsten Level; +2 % Basisrumpf/-schaden pro weiterem Level |
| XP-Zurechnung | Positive Piraten-XP aus vorhandenen Aktivitäten zählen zugleich für das aktuell ausgerüstete Schiff; andere Schiffe erhalten diese XP nicht |
| Verbesserungen | Rumpf/Kanone/Segel je Design; bestehende Preise und Stufenlimits; Kauf nur am Hafen |
| Loadouts | Zwei gespeicherte Presets je Design, inklusive Kanone, Munition und Waffenmodus; Anwendung über Arsenal/Command Deck |
| Erste Prüfung | Hafen + Piratenlevel 2 + Rumpfverbesserung 1; anschließend 3 Siege / 2 Beuten / 1 Hafenbesuch; Sinken bricht ab |
| Prüfungsabschluss | Einmalig im Hafen: 300 Gold, 120 XP, Zugang Green Frontier und AUTO; spätere Karten für neue Profile noch gesperrt |
| Zielkampf | Zielauswahl erforderlich; kein ausrichtungsabhängiger Schaden, keine automatische Verfolgungsfahrt |
| Projektil | Verfolgt sein festes Ziel, begrenzte Flugstrecke/-dauer, Swept-Ray-Kollisionsprüfung; Hindernisse blockieren |
| Harpune | Ein Projektil pro Schuss, separater Bestand; nur gegen Monster. 40 Startbestand, Hafenangebot 30 für 35 Gold |
| Reload | Dauer beim Schuss festgehalten; Waffenwechsel verkürzt laufenden Reload nicht |
| Tages-/Wochenziele | UTC-Tag und Montag-UTC-Woche; neue Perioden setzen nur jeweilige Zähler/Claimflags zurück |
| Lokale Jagd | Start im Hafen; 900 Sekunden aktive Spielzeit, danach 300 Sekunden Pause; Sieg +10 und Beute +5 Marken; Reparatur für 15 Marken |
| UI | Fortschritt/Prüfung und Waffen/Loadouts im scrollbaren Menü, Harpunen im Arsenal, AUTO-Sperrhinweis; M30-Systemeinstellungen erhalten |

Alle Zahlen sind transparente lokale Testabstimmung, keine behaupteten Original-Serverwerte.
Der neue Jagdtest ersetzt nicht die bestehenden kumulativen Event-Meilensteine.
Er besitzt noch keine eigenen Gegnerwellen, saisonale Quests oder Rangliste.

## Speicherstand und Migration

Der tatsächliche bisherige `user://`-Ordner bleibt unverändert. JSON-Saveversion 1
bleibt lesbar, M31 ergänzt `m31_version: 1`, `voyage`, `ship_roster.designs`,
`inventory.loadouts_by_ship` und `player.weapon_mode`.

- Alte globale Verbesserungen werden dem damals ausgewählten Schiff zugeordnet,
  nicht auf alle Schiffe vervielfacht. Neue Schiffe beginnen mit eigenen Werten.
- Alte A/B-Presets wandern zum ausgewählten Schiff; Material-/Munitionsbestand bleibt.
- Alte Kartenposition und Kartenzugang bleiben erhalten. Neue Profile nutzen die Prüfungssperre.
- Alte Tages-/Wochenzähler werden der aktuellen UTC-Periode zugeordnet, nicht sofort gelöscht.
- Zurückgestellte Geräteuhren lösen keinen erneuten Reset aus. Vorstellen der Uhr bleibt bei
  Offline-Dateien manipulierbar; keine Anti-Cheat-/Serverzeitbehauptung.
- Die JSON-Prüfsumme wurde repariert: Zahlen werden vor dem Hashen normalisiert.
  Bei alten Dateien wird zusätzlich die originale kompakte Payload-Schreibweise überprüft,
  damit Ganzzahl-/Dezimalzahl-Unterschiede nicht fälschlich gültige Saves verwerfen.
- Eine manipulierte Payload ohne passende Prüfsumme wird weiterhin abgelehnt.
  Unlesbare Primär- und Backup-Dateien sperren das Speichern. Eine beschädigte Primärdatei
  wird nicht über ein intaktes Backup kopiert. Prüfsummen sind Integritätschecks, keine Signaturen.

## Verifikation

`tools/check_m31.py` prüft GLB-Längen/Hashes, den Godot-Import, die M30-Regressionssuite
und neue M31-Laufzeittests. Der Runner wertet auch ERROR-Ausgaben aus; Exitcode 0 allein
gilt nicht als Erfolg. Aktuelle Anzahl/Resultate stehen in `m31_current_validation.json`.

Zusätzlich getestet: Speichern/Lesen/Backup eines vollständigen isolierten Testprofils,
Legacy-Prüfsummen inklusive Strings/Escapes, manipulierter Payload, M30-Feldmigration,
vier Angriffsausrichtungen, Treffer und Hindernisblockade, Modalsperren, Abbruch und
Doppelauszahlung, Designs/Loadouts, UTC-Reset und Uhr-Rückstellung.

Ausführung hier mit **Godot 4.5.1 stable, ergänzend headless**. Keine neue GPU-Darstellung,
keine echten Geräte-/Exporttests und keine bestätigte 4.7.2-Abnahme. Keine Store-Freigabe.

## Bewusst offen

Navigation weiterhin Tap-to-Sail auf direktem Kurs; noch keine Hindernis-Routenplanung.
Mobile Starterwahl liegt im scrollbaren Einstiegsbereich; echte Safe-Area-/Lesbarkeitstests
auf Geräten fehlen. Bisherige 18 GLB-Platzhalter bleiben, Harpune jetzt aktiv eingebunden.
Grafikqualität bleibt unter dem Mockup. Weiteres Balancing, vollständige Welt-Events,
Online-Auth, Multiplayer/Crossplay, Native-Pakete und finale Originalgrafik bleiben offen.
