# M208 — Interface + Asset Production Readiness

M208 bereitet den Übergang von optimierten Platzhaltern zu authored Production Art vor, ohne dafür die inzwischen stabile Gameplay-/Slot-Architektur erneut umzubauen.

## Interface-Konvergenz
Das Command Deck verwendet nun dieselbe Icon-Sprache für Schnellzugriff und Zielseiten. Das Arsenal wird nach sichtbaren Kategorien geordnet statt als lange Mischliste dargestellt. Die Kategorien bleiben dieselben Daten/Items; M208 verändert keine Economy- oder Combatwerte. Quickslots behalten ihren kompakten World-first-Platz und zeigen zusätzlich eine kurze Typkennung, ohne daraus eine permanente untere Command-Bar zu machen.

## Produktionsübergabe für 2D
Für die erste echte 2D-Welle sollten große transparente Master erstellt und anschließend auf 96/64/48 px geprüft werden. Silhouette und Materialidentität haben Vorrang vor Mikrodetails. Kanonen, Munition, Harpunen, Items, Decks und Upgrade-Stufen dürfen nicht nur durch Recolor unterschieden werden. Der genaue Handoff steht in `data/m208_authored_asset_replacement_manifest.json`.

## Produktionsübergabe für Schiffe/Inseln/Loot
Die bestehenden Placeholder-Slots werden ersetzt, nicht neu erfunden. Schiffe bleiben ohne eingebautes Wasser/Rauch/VFX; Inseln ohne eingebautes Wasser und mit sauberem Unterbau; Loot mit klar unterschiedlichen Formen. Collision, Navigation, Muzzle-/Hardpoint-, Nameplate-, Selection- und Damage/VFX-Verträge bleiben technisch kontrolliert.

## Offener Pflichtschritt
Native Godot-/Android-/Desktop-QA bleibt erforderlich. M208 ist statisch verifiziert, aber keine Behauptung finaler visueller Abnahme.
