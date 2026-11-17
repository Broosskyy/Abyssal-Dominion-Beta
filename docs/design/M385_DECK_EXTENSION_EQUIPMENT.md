# M385 — Sechs modulare Deck-Erweiterungen: Besitz ≠ Ausrüstung

Die Referenz sieht wie **sechs getrennte Ausbauten** aus. Es gibt keine große Kanonenzahl mehr: in der Mitte bleiben **zehn individuelle Standarddeck-Punkte**, zwei Reihen zu fünf. Die sechs Schmuckmodule sind eigene Dateien, können separat erscheinen und haben voneinander unabhängige Erwerbs-/Montagezustände.

## Sechs Erweiterungsplätze

1. `mojo_frame` – eigenständiger offener **Mojo-Knochenrahmen** hinter der Komposition
2. `crown_left` – linke Krone
3. `crest_right` – eigenes Emblem oben rechts
4. `skull_top_left` – linker Totenkopf über den Punkten
5. `skull_top_right` – rechter Totenkopf über den Punkten
6. `skull_bottom` – mittiger Totenkopf unter den Punkten

Alle verwenden vorhandene separate `res://assets/ui/deck_extensions/*.svg`-Texturen. Kein statisches Kombibild.

## Zwei voneinander unabhängige Datenebenen

- `sim.deck_extension_owned[key]`: unveränderlicher Besitz nach einer echten Belohnung, kein geschätzter Preis, keine automatische Freischaltung, sechs boolesche Einträge.
- `sim.deck_extensions[key]`: **ausgerüstet / sichtbar**. Kann ein Besitzer individuell einschalten bzw. ablegen. Nichtbesitzer dürfen nicht ausrüsten.
- `sim.unlock_deck_extension(key)`: geschützte Spiel-API für **später definierte** Quest-/Event-/Beutequellen. Im normalen UI gibt es absichtlich keinen Gratis-Kauf- oder Freischaltknopf.
- `sim.set_deck_extension_equipped(key, true/false)`: einzige reguläre An-/Ablegefunktion, prüft vorher den Besitz. Es werden weder Gold noch Buffs, Kanonenplätze, HP, Koordinaten oder Navigation verändert.
- **UI:** neuer Reiter `Decks → ERWEITERUNGEN` mit sechs großen eigenständigen Asset-Karten, ehrlichem Status (**gesperrt**, **freigeschaltet**, **ausgerüstet**) und freischaltabhängigen Anlegeknöpfen.
- **UI-Vorschau:** `Decks → VORSCHAU` bleibt vollständig frei, aber **rein optisch**; dort lassen sich weiterhin alle sechs Assets unverbindlich unabhängig testen.

## Speicher- und Crossplay-Kompatibilität

Das bisherige lokale Speicherformat `schema: 8` erhält den optionalen Schlüssel `deck_extension_owned`. Alte M383/M384-Spielstände enthielten nur `deck_extensions`, weshalb bisher ausgerüstete Erweiterungen beim Laden automatisch als **bereits besessen** erkannt und weiter angezeigt werden. Der Ladevorgang akzeptiert nur genau die sechs bekannten Schlüssel mit echten booleschen Werten. Gespeicherte `deck_extensions=true` ohne Eigentum im **neuen** Format werden deaktiviert. Bei einem normalen neu angelegten Account sind alle sechs Module zunächst gesperrt.

Die Deck-/Buff-Zustände bleiben weiterhin lokal gespeicherte Betadaten; eine spätere **serverautoritative Online-Freischaltung** ist gesondert zu planen. Ein lokaler Speicherstand ist kein gesicherter Nachweis für PvP-/Zahlungs-Entitlements.

## Was ausdrücklich nicht Bestandteil von M385 ist

- Preise, Werte und Belohnungsbedingungen der sechs Erweiterungen: vom Nutzer noch nicht festgelegt; **nichts erfinden**.
- Die klassischen 10 Gold-/Perlen-/Kristall-Decks oder die drei zeitbegrenzten Spezialdeck-Buffs umbenennen / ersetzen.
- 2D-/3D-Fahrtweg, Trefferzonen, App-Login, Multiplayerserver oder Wasser-Rendereinstellungen verändern.

## Prüfung vor Freigabe

`tests/m385_deck_extension_equipment_test.gd`: reale Godot-Simulation und reales mobiles UI, Besitzschalter, einzelne Ausrüstungen, Legacy-Speicher-Migration, manipulierte unbekannte Flags, No-Buff-/No-Gold-/No-Crossplay-Effekte. Zusätzlich sämtliche Browser-/Android-Regressionen und echte 852×393-Screenshots prüfen.
