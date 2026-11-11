# Abyssal Dominion: Gesamtdurchgang und Referenzvergleich

Stand: 11. November 2026. Browser und Android bleiben Clients derselben Simulation. Dies ist eine Bestandsaufnahme mit priorisierten nächsten Arbeiten, keine Behauptung, dass alle Bereiche fertig sind.

Verbindliche zeitliche Eingrenzung: [Referenzrichtung](REFERENCE_DIRECTION.md). Seafight hauptsächlich 2008–2014, höchstens ergänzend bis 2016/2018; Battle of Sea im aktuellen Stand.

## Referenzen und Ableitungen

- Seafight, offizielle Seekartenübersicht: https://board-en.seafight.com/threads/sea-chart-overview.172255/ — getrennte Statusanzeigen, Aktionsleisten, Weltkarte, Ausrüstung und soziale Bereiche.
- Seafight, offizielle Aktionsleisten: https://board-en.seafight.com/threads/sea-chart-toolbars.1953/ — individuell belegbare Gegenstandsplätze neben festen Kampfaktionen.
- Battle of Sea, offizielle App-Bilder: https://play.google.com/store/apps/details?id=com.gamepatron.battleofsea — Referenz für Seekarten- und Kampfanordnung auf Mobilgeräten.
- Battle of Sea, offizielle Updatehistorie: https://forum.battleofsea.com/en/thread-3 — mobile UI-Skalierung, Ausrüstungskategorien, differenzierte Spielernamen und konfigurierbare Zielabwahl.

Für unser Spiel abgeleitet: Auf der Seekarte die wichtigsten Informationen direkt zeigen, Ausbau und Einkauf klar trennen, Wiederholungsaktionen kurz halten und den nächsten Spielschritt auffindbar machen. Eigene Grafiken, Spielwerte und Struktur bleiben maßgeblich; keine fremden Assets übernehmen.

## Bereiche

| Bereich | Aktueller Stand | Befund und nächster sinnvoller Schritt |
| --- | --- | --- |
| Einstieg / Updater | Startseite, Gast/Account, signierte Android-Spieldaten, kleiner Browserexport | Einladungen führten ausschließlich zum Download. Jetzt gemeinsame Browser-Einladung mit optionalem Android-Link; danach Erstspielerablauf mit echten neuen Testern prüfen. |
| Seekarte / HUD | Profil links, HP/Schild, mittige Menüs, EXP/BP, Währungen rechts | Anordnung beibehalten. Gegner-Schild jetzt separat sichtbar; Kampfbereitschaft mit unterscheidbaren Farben. Weiterhin dichte Begegnungen und kleinste Geräte prüfen. |
| Steuerung / Kampf | Einzeltipp wählt, optional Doppeltipp feuert, Kamerapad, Abwahl, Salven und Effekte | Bestehende Abläufe erhalten. Weitere Arbeit: langfristige Touch-Tests bei bewegten und eng stehenden Zielen, Effekte unter voller Kampflast. |
| Quests / Logbuch | Sieben lokale Kampagnenaufträge, echte Fortschritte und einmalige Auszahlung | Aktiven Auftrag vom Archiv getrennt, Fortschrittsbalken und passende Hilfs-/Kartenlinks hinzugefügt. Weitere Kapitel und wiederholbare Aufgaben brauchen ein eigenes Content- und Balancepaket. |
| Profil / Progression | Kapitän, Gilde, Währungen und lokale BP | Reale EXP-/BP-Meter und Statistiken plus Links zu Aufträgen, Karten und Belohnungen hinzugefügt. Langfristige Klassen-/Prestigeprogression nicht als fertig darstellen. |
| Werft / Arsenal | Designs von Original-GLBs, Filter, Kanonenmontage und Lager | Browser zeigt gleiche Designs als acht Richtungsbilder. Weiterhin alle Ansichten und Ausrüstungszustände visuell abgleichen; keine Munition in die Werft verschieben. |
| Markt / Handel | Echte lokale Goldkäufe, getrennte Ausrüstung/Munition/Items/Auktion | Große Produktbilder und Kaufaktionen vorhanden. Preise, Bestände und Erwerb über lange Spielsitzungen testen. Gemeinsame Auktion bleibt Serverarbeit. |
| Decks / Kastelle / Talente | Zehn Standarddecks, Materialpfad, HP/Kanonenboni, Sonderdecks und Talente | System vorhanden; Beta-Werte nicht als final behandeln. Nächster Schritt: verständliche Vorher/Nachher-Vergleiche und langfristige Kostenkurve. |
| Weltkarte / Hafen | 40 normale Karten, Portale, Gildeninseln und Andockstellen | Falsche feste Tiamat-/Patrouillenbeschreibung entfernt. Weitere Kartenindividualität, Hafenasset-Kanten, Routen und Inselgrößen prüfen. |
| Bonuskarten / Kessel | Fragmente, Schriftrollen, Wellen und lokale Belohnungen | Funktionierende Content-Schleife. Weiterhin Verständlichkeit des Fragmentfortschritts und Schwierigkeit über mehrere Durchläufe prüfen. |
| Events / Monster | Lokale Halloween-/Entdeckerinhalte und Monsterjagd | Mehr eigene Monster- und Inselgrafiken sowie Eventaufträge sinnvoll. Zeitplan, Belohnungen und Spawnregeln müssen zusammen abgestimmt werden. |
| Tagesbonus / AFK | Lokales Belohnungsbuch, einmalige Tagesabholung | Abholbare Belohnungen werden jetzt auch im Menü kenntlich. Keine zusätzlichen Auszahlungen oder fingierten Online-Boni. |
| Gilde / Freunde / Ranglisten | Lokale Gilde/Festung, Einladungslink, eigener Fortschritt | Gemeinsame Freundschaften, Gruppen, Ranglisten und Wirtschaft benötigen den öffentlichen Server. Kein bezahltes Hosting ohne neue Entscheidung provisionieren. |
| Browser / Android / Crossplay | Geteilte Spielmechanik, native GLBs / Browseratlanten, vorbereiteter HTTP-/WebSocket-Server | Direkt geladene Designs erhalten; Lade- und Wiederbesuchsbudget prüfen. Öffentlicher Server bleibt zurückgestellt, automatisierte Zwei-Client-Tests bleiben aktiv. |

## In diesem Paket umgesetzt

1. Browser-Einladungen auf Startseite und Seekarte vereinheitlicht.
2. Logbuch mit aktivem Auftrag, Fortschritt, Belohnung und separatem Verlauf.
3. Profil um echte Fortschrittsbalken und Spielstatistiken ergänzt.
4. Abholbare Tages-/AFK-Belohnungen im vorhandenen Menü sichtbar gemacht.
5. Gegner-Schild im Zielpanel und farblich unterscheidbare Kampfzustände ergänzt.
6. Irreführende feste Weltkartenbeschreibung entfernt.
7. Große Menübanner bei geringer Fensterhöhe verkleinert; aktive Aufträge ohne vorgeschalteten Dekobanner und Profilfortschritt vor Namensbearbeitung.

## Weitere Arbeit

- Spielbare Inhalte: Kampagnenkapitel, wiederholbare Aufträge und Monster-/Eventvielfalt gemeinsam mit Belohnungen entwickeln.
- Ausbau: Vorher/Nachher-Werte, Kostenkurve und verständliche Erwerbswege für Decks, Kanonen und Talente.
- Grafik: einzelne Schiffsansichten, Hafen-/Inselränder, Monster und Salven über reale Spielsituationen prüfen; nur gezielt fehlende eigene Assets erzeugen.
- Multiplayer: nach Bereitstellung eines öffentlichen Servers persistente Konten, Gruppen, Freundschaften, Gilden und serverautorisierte Kämpfe/Wirtschaft ausbauen.

## Folgepaket: Ausbauvorschau

- Alle sechs Kastelle zeigen aktuelle und nächste Werte anhand der vorhandenen Ausrüstung. Vollkugelschaden und Harpunen sind ausdrücklich unterschieden.
- Hafen-, Stufen- und Goldvoraussetzungen werden an der Kaufaktion genannt; maximale Stufen bieten keinen weiteren Kauf.
- Talentkarten zeigen den aktuellen und nächsten Talentbonus und erklären fehlende Punkte.
- Kastelle verlinken Hafen, Decks und Kanonenmontage.
- Die Prognosen werden gegen echte Käufe einschließlich aktiver Segnung und Talenten geprüft. Vorschau darf weder Gold noch Rumpfzustand ändern.
- Auf sehr schmalen Panels werden Katalogbilder und Produkttexte untereinander statt in einer gequetschten Seitenzeile angeordnet.

## Folgepaket: wiederholbare Seeverträge

- Drei unabhängige PvE-Aufträge im Logbuch: vier NPC-Schiffe, vier geborgene Gegner-Beutekisten oder ein Seeungeheuer.
- Verträge müssen ausdrücklich angenommen werden und zählen nur den danach erzielten Fortschritt. Mehrere Verträge dürfen parallel aktiv sein.
- Nach einmaliger Auszahlung kann eine neue Runde angenommen werden; alte Abschüsse werden dabei nicht erneut gewertet.
- Aktive Runden und erfüllte Verträge werden im bestehenden Gastspielstand gespeichert. Alte Spielstände starten ohne erfundenen Vertragsfortschritt.
- Keine Battle Points, Kalenderfristen oder Online-Belohnungen. Die kleinen Gold-/EP-/Essenzprämien sind Beta-Werte.
- Nächster Content-Schritt: weitere Kampagnenkapitel, regionsbezogene Aufgaben und abwechslungsreichere Monster-/Eventbegegnungen.

## Folgepaket: klassische Eventjagd

- Halloween und Columbus erhalten je einen markierten Eventgegner auf normalen Seekarten; Auswahl und Hinfahren schießen nicht automatisch.
- Echte Spielerabschüsse vergeben zusätzliche Zeichen, abgestuft nach Kartenlevel. Bestehende normale Beute bleibt erhalten.
- Zeichen können im Eventmenü gegen feste Munitionspakete getauscht werden. Beta-Werte, keine bezahlten Freischaltungen.
- Eventwechsel verändern weder Gegnerzahl noch Rumpf, Schild oder Respawnzeit. Gesunkene Gegner bleiben gesunken, bis der normale Timer endet.
- Eventgegner werden auf der Minikarte markiert. Eigene vorhandene Schiffsgrafiken halten das Browser-Ladebudget klein.

## Folgepaket: Jagdvorbereitung und lebendige Monsterübersicht

- Die Übersicht zeigt echte HP, Distanz und aktuelle Goldbeute. Besiegte Monster bleiben mit ihrer tatsächlichen Wiederkehrzeit sichtbar; fehlende Arten werden nicht als lebendig ausgegeben.
- Wiedererscheinende Monster werden ohne erneutes Öffnen auswählbar. Anvisieren und Hinfahren bleiben getrennt vom Angriff.
- Der Solo-Richtwert für Harpunen nutzt die gemeinsame Schadensbasis mit aktiver Ausrüstung, Elitebonus und Segnung; Markierung, Regeneration und fremde Treffer sind ausdrücklich nicht eingerechnet.
- Harpunenladen ist eine bewusste Aktion ohne Munitionsverbrauch und ohne automatisches Feuern. Der Marktlink führt zur tatsächlichen Harpunenkarte; ein Kauf bleibt eine separate Entscheidung.

## Folgepaket: große Seekarten, Randüberfahrten und Monsterbewegung

- Seekarten von 4400 × 3200 auf 8800 × 6400 vergrößert (vierfache Fläche). Die Positionen der vorhandenen Inseln und Ausgangsflotten werden verteilt; Grafikgröße, Reichweiten und Schiffsgeschwindigkeit bleiben erhalten.
- Einzelne Portalgrafiken und Tipp-Hotspots entfernt. Jede komplette offene Kante führt zur räumlichen Nachbarkarte: Ost/West entlang der Stufen, Süd von /1 nach /2, Nord zurück. Weltgrenzen und gesperrte Kanten sind anders markiert, auch auf der Minikarte.
- Gewöhnliche Fahrbefehle lösen die Überfahrt aus. Ankunft auf der gegenüberliegenden Seite mit erhaltener Querposition und sicherem Abstand zum Rand; Stufen- und Kampfregeln bleiben gültig. Weltkartenkurse wählen einen passenden Punkt am gesamten Rand.
- Alte lokale Positionen, Hafenlieger und Bonus-Rückkehrpunkte werden einmalig migriert. Crossplay-Protokoll 2 und Servergrenzen verwenden dieselbe Weltgröße; gespeicherte Serverpositionen werden ebenfalls einmalig umgerechnet. Der öffentliche MMO-Server bleibt ausstehend.
- Krakenarme, Schlangenkörper/-schwanz und Krabbenbeine/-schere erhalten unterschiedliche, zwischengespeicherte 2D-Verformungszyklen und sanfte Wasserkontakte. Keine neuen Texturpakete oder 3D-Laufzeit nötig. Es handelt sich um prozedurale 2D-Animation vorhandener Grafiken, nicht um neu gezeichnete Tiamat-Einzelframes.
- Der Animationsschalter friert auch den Tiamat ein. Treffflächen und Namensanker bleiben unabhängig von der Bewegung. Keine NPC- oder Spielerschiffsmodelle geändert.
- Prüfung: 561 zusätzliche Simulation-/Animationschecks, 6 GPU-Bewegungsvergleiche (bewegte Monster verändern Pixel, ruhende bleiben identisch), bestehende UI-/Navigation-/Progressionsprüfungen sowie HTTP/WebSocket-Tests.
- Weiterer Feinschliff: eigene gezeichnete Monster-Angriffs-/Trefferphasen, Küsten-/Hafenübergänge, regionsbezogene Begegnungsdichte und zusätzliche Umgebungsdetails.

## Folgepaket: klassische Fahrbewegung und native 2D-Auswahl

- Grundlage ist das vom Nutzer hochgeladene Bewegungsbeispiel `208771.mp4`: kurze diagonale Fahrstücke, sofortiger Ansichtswechsel, kein Wendebogen.
- Die frühere generelle 64-Einheiten-Zickzack-Navigation war auch in 2,5D/3D aktiv und erzeugte zu hektische Richtungswechsel. Sie wurde durch eine reine Classic-2D-Route mit bis zu 144 Einheiten je Diagonalstrecke ersetzt. Ein neuer Tipp ersetzt den bisherigen Kurs direkt. Acht vorhandene Modellansichten bleiben verfügbar; freies Wasser nutzt überwiegend die vier diagonalen Perspektiven.
- An engen Küsten/Hafenpassagen bleibt ein bereits kollisionsgeprüfter kurzer Abschnitt zulässig, wenn kein diagonaler Ausschlag sicher ist. Monster behalten ihre eigene Navigation.
- Die Grafikmodi nutzen weiterhin dieselbe Simulation, Kollision, Trefferpositionen und Basisgeschwindigkeit, aber die Steuerrouten unterscheiden sich absichtlich: Classic 2D fährt diagonal, 2,5D/3D fahren direkte Wege. Ein Moduswechsel berechnet die Reststrecke zum gleichen Ziel neu, ohne die aktuelle Schiffsposition zu verändern. Der Presence-Server folgt der vollständigen Wegpunktfolge und akzeptiert begrenzt bis zu 512 Punkte; zwei echte Godot-Clients prüfen wechselnde diagonale Richtungen.
- Unter Anzeige > Grafik können native Nutzer Classic 2D mit Zickzack-Fahrt, 2,5D mit direkter Fahrt oder 3D mit direkter Fahrt wählen. Classic entfernt die 3D-Flottenansicht vollständig und erstellt beim nächsten Start ebenfalls keinen 3D-Viewport. Zurückschalten stellt die originalen GLBs wieder her.
- Native Pakete rendern die gleichen 23 originalmodellbasierten Atlanten wie der Browser vor. Ihre Geometrie-Metadaten sind im bereits exportierten Provenienzindex enthalten, sodass die vorhandene APK die Funktion über ein signiertes Datenupdate erhält. Kein zusätzlicher Schiffsgrafik-Download im Browser.
- Prüfungen: neue Modus-/Kursregression, Wechsel während laufender Fahrt, gespeicherte Auswahl und Neustart, Flotte zurück in 3D, unabhängiger Start und Wechsel aus dem tatsächlichen signierten Datenpaket. Native 2D zusätzlich im echten OpenGL-Renderer visuell geprüft.
