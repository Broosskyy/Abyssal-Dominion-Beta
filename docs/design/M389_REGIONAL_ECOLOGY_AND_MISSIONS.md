# M389 – Regionale Seekarten, Begegnungen und Revieraufträge

**Projekt:** Abyssal Dominion · Godot 4.7.2 · Android, Browser 2D Classic und App 3D

## Spielbarer Inhalt

Nur die freiwillige 20-Reviere-Welt (IDs 43–62) erhält die folgenden Veränderungen. Die bisherigen 40 Karten, Gildeninseln und Bonuskarten behalten ihre Inhalte, IDs und Überfahrten.

- **18 Inseln je Seekarte** – auf zwei zusammenhängende Kartenhälften verteilt, innerhalb sicherer Wassergrenzen, eigene deterministische Positionen, echte Kollision, fünf maritime Biome und passende vorhandene Inselgrafiken.
- **16 Schiffs-NPCs je Revier** – verteilte Patrouillen, regional passende Rollen, die bisherigen Schiffsmodelle und dieselben 2D-/3D-Weltkoordinaten.
- **Vier Seeungeheuer je Revier** – bestehende Monsterarten und Harpunenregeln, neue regionale Jagdgebiete und Namensvarianten sowie 20 unterschiedlich benannte Hauptwächter.
- **Vier feste Bergungsplätze** über beide Seekartenhälften und zusätzliche Gezeitenfunde.
- **Fünf abgestimmte Meerespaletten:** helle Küste, Handelsmeer, Nordmeer, Kriegsgewässer und Tiefenmeer. Nicht durchgehend Dark Fantasy.
- **Ein einmalig abschließbarer Revierauftrag:** drei tatsächlich geborgene Gezeitenfunde und ein besiegtes Seeungeheuer aus diesem Revier. Prämie je Stufe: Gold, Erfahrungspunkte und Essenz. Keine Battle Points und kein Premiumgeld.

## Bedienung

**Logbuch → REVIER** enthält zwei Fortschrittsanzeigen, die anwesenden Seeungeheuer mit HP/Respawn, Schaltflächen zur Monsterjagd und Weltkarte sowie einen einmalig nutzbaren Belohnungsknopf. Auf der Weltkarte werden die Fortschritte des ausgewählten eigenen Reviers angezeigt. Alte Kampagnen- und See-Vertrags-Tabs bleiben unverändert.

## Technische Schutzregeln

- Das neue Datenmodul realm_ecology.gd beschreibt die 20 Reviere ohne 20 einzelne, schwer wartbare Szenen.
- Inseln, Kollisionsformen, AStar-Navigation und NPC-/Monster-Spawns arbeiten mit identischen Weltkoordinaten. M376-Fahrtbewegung und M388-Hybrid-Kartenränder bleiben unangetastet.
- Bestehende Monster- und Schiffsassets werden nur anders verteilt und benannt. Eigene Grafiken können später ausgetauscht werden, ohne Kampflogik und Serverpfade neu zu programmieren.
- Revieraufträge zählen nur im freiwilligen Beta-Modus; Staff-Modus bekommt keine Belohnung. Doppeltes Töten eines bereits zerstörten Monsters zählt nicht.
- Fortschritt wird je Revier über ein optionales Save-Feld gespeichert, mit begrenzten Zählern und einmalig markiertem Anspruch. Bestehende Schema-8-Saves bleiben kompatibel.
- Aktuelle Online-Grenze: Neue Rooms sind im Servercode vorbereitet, aber die Produktion benötigt einen separaten Backend-Rollout, um Online-Spieler in den neuen Revieren sichtbar zu machen.

## Qualitäts- und Veröffentlichungsregeln

M389-Tests decken 20 Reviere, Gelände/Art-Varianten, sichere Spawns, echte Mission und UI, Einmalprämien, Speicherstände sowie M388-/M376-/M385-Regressionen ab. Browser/WebGL-Testreleases dürfen über GitHub erzeugt werden, jedoch **niemals automatisch an Vercel deployen**. Signierte Android-App-Datenupdates werden nach erfolgreich durchlaufener Hauptbranch-CI **immer veröffentlicht**, ohne unnötige native APK-Neuerstellung.

Nächste Gestaltungsschritte: je Gebiet eigenständige Inselgrafiken, besondere Monster-Silhouetten, neue Schiffsmodelle und originale Geschoss-, Treffer- und Untergangseffekte. Die Orte und Rollen dafür sind bereits als spielbare Daten angelegt.
