# M383 — Modulare Deckanzeige (Referenzen 208798, 208799, 208801, 208803, 209593)

## Was gemeint ist
Die vormals angezeigte zentrale Zahl (z. B. `133` im eigenen Spiel) wird **vollständig entfernt**. An dieser Stelle stehen exakt **10 Standarddeck-Punkte** in zwei Reihen zu fünf, verbunden mit den real ausgerüsteten Basisdecks. Das ist **kein** Punktezähler, sondern zehn unabhängige Statuszellen für Gold/Perlen/Kristall.

Alle goldenen und knöchernen Ornamente auf den Referenzbildern sind **eigene separat freischalt-/ausrüstbare Erweiterungen**; sie dürfen nicht als ein statisches, immer sichtbares Emblem gebacken werden.

| Eigenständiger Slot | Artwork | Anordnung | Anzeige |
| --- | --- | --- | --- |
| `crown_left` | `left_crown.svg` | links außen oberhalb der zehn Deckpunkte | nur bei eigener Ausrüstung |
| `crest_right` | `upper_right_crest.svg` | oben rechts als separater goldener Dreizack/Emblem | nur bei eigener Ausrüstung |
| `skull_top_left` | `skull_top_left.svg` | oberhalb der Punkte, links von der Mitte | nur bei eigener Ausrüstung |
| `skull_top_right` | `skull_top_right.svg` | oberhalb der Punkte, rechts von der Mitte | nur bei eigener Ausrüstung |
| `skull_bottom` | `skull_bottom.svg` | mittig unter den zehn Punkten | nur bei eigener Ausrüstung |
| `mojo_frame` | `mojo_bone_frame.svg` | eigenständiger **Knochen-Rahmen** hinter den Punkten und Erweiterungen | nur bei ausgerüstetem Mojo-Deck |

## Verhalten und Daten
- **Kein Einzelbild-Skin** und kein gefälschtes Freischalten: Jeder der sechs SVG-Bausteine ist ein eigener Godot-Texture-Asset mit eigener Besitzerstatus-Flagge. Jedes Asset kann unabhängig entfernt oder später durch Upgrades/andere Ausprägungen ersetzt werden.
- Sie werden **nur angezeigt, wenn der zugehörige Schlüssel `deck_extensions[key]` tatsächlich `true` ist**. Der Rahmen kann allein erscheinen; er aktiviert die fünf anderen Erweiterungen **nicht** automatisch. Umgekehrt kann ein Schädel allein ohne den Mojo-Rahmen sichtbar sein.
- Freischaltkosten, Quellen, Stats und Ausrüstungsdialoge sind **nicht vorgegeben** und werden nicht erfunden. Die Save-Persistenz ist als optionaler Schlüssel im bisherigen `schema: 8` angelegt. Alt-Saves enthalten keine der Erweiterungen und behalten alle zehn normalen Deckplätze.
- Die bisher implementierten `tide_deck`, `storm_deck` und `salvage_deck` sind unabhängige **zeitlich begrenzte** Gameplay-Effekte. Sie dürfen nicht fälschlich die links/rechts/unten abgebildeten freien Erweiterungs-Slots steuern. Die Buff-Anzeige und der Kessel bleiben getrennt.
- Alle Module liegen auf derselben bildschirmfesten Playerplate unter dem Namen und den Balken, nicht an der 3D-Mesh-Geometrie. Das ist visuelles UI, kein Hitbox-/Kurswechsel.

## Tests
`tests/m383_modular_deck_extensions_test.gd` testet Asset-Import, jeden einzelnen Freischaltzustand, zehn unveränderte Deckpunkte, Alt-Save-Migration und unveränderte Buffs/Kanonen/Bewegung. Der Browser-Capture erstellt außerdem `852x393-modular-all.png` und `852x393-mojo-only.png`, sodass die Unabhängigkeit **in echten Screenshots** erkennbar ist.

**Nächster separater Inhaltsschritt:** Falls der Nutzer die Upgrade-Quellen und Werte festlegt, die sechs Statusflags an die tatsächliche Erwerbs-/Ausrüstungsmechanik anbinden. Keine Preise oder Werte erfinden.
