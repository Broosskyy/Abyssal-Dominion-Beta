# M30 — austauschbare Grafikbasis

## Herkunft und Umfang

Basis: vollständiges, CRC-geprüftes M29-Archiv. Aus dem unvollständigen M31-Archiv
wurden ausschließlich vollständig lesbare und CRC-geprüfte Dateien unter
`assets/placeholder_pack/` übernommen. Kein M31-Laufzeitcode wurde übernommen.
Die GLBs/SVGs sind eigenständige Platzhalter; Unity-Referenzdateien sind separat erhalten.

| Kategorie | Katalog-IDs | M30-Anbindung |
| --- | --- | --- |
| Spielerschiffe | ship_small, ship_medium, ship_large | barco_low, clipper, chalupa |
| Gegner | npc_corsair, npc_admiral | Gegnerprofil; npc_shadow nur vorbereitet |
| Inseln | island_tropical, island_rock, island_snow | Tropen-, Wüsten-/Fels-, Schneeprofil |
| Hafen | harbor | Hafen-Adapter, bestehende Interaktion/Kollision bleibt |
| Beute | loot_chest, repair_crate | Bestehende Belohnung + Pickup-Halo |
| Monster | monster_kraken | Bestehendes Monsterprofil, Schiffsvisual ausgeblendet |
| Projektil | cannonball | Sichtbares Kanonenprojektil; Trefferlogik unverändert |
| Vorrat für spätere Inhalte | wreck, cannon, harpoon, buoy, npc_shadow | Importierbar, noch keine neuen Gameplay-Systeme |

## GLB-Vertrag

1. Meter, +Y oben, +Z Bug/Vorwärtsrichtung. Ursprung an Wasserlinie; Transformationen anwenden.
2. Komplette Modelle exportieren, Materialien/Texturen im GLB einbetten. Keine Skripte,
   Collider, UI oder Spielmechanik in den Grafikdateien.
3. Datei am bestehenden Katalogpfad ersetzen oder `path` im Manifest ändern.
   Den Modellumfang zuerst am vorhandenen Platzhalter messen; Inseldateien sind normalisierte
   Radiusmodelle und werden vom Wrapper auf dessen Radius/Aspekt skaliert.
4. Godot neu importieren/starten. Szenen werden zur Laufzeit gecacht; kein Hot-Reload-Versprechen.
5. Nach bewussten Assetänderungen `bytes`, `sha256`, `triangles` und `surfaces` im Manifest
   aktualisieren. Die Integritätsprüfung soll unbeabsichtigte Änderungen erkennen, nicht kaschieren.
6. Silhouette, Wasserlinie, Auswahlring, HUD-Bounds, Kollisionsabstand und Kamerafit visuell prüfen.
   Deutlich größere/kleinere Modelle erfordern bewusstes Anpassen des Gameplay-Wrappers.

`AssetVisualLibrary.install(parent, id)` ersetzt nur `AssetVisual`. Gameplay-Knoten bleiben
erhalten. `hud_visual_bounds` werden neu aus den Meshes berechnet. Auswahlring und
Pickup-Halo bleiben getrennte Elemente. Keine automatische LOD-Erzeugung oder finale Textur-Pipeline.

## UI-Vertrag

`assets/placeholder_pack/ui/harbor_backdrop.svg`: skalierbarer Einstiegshintergrund.
`captain_crest.svg`: Wappen auf dem Splashscreen, kein echtes Kapitänsporträt.
`button_normal/hover/pressed/disabled.svg`: Nine-Patch-Grafiken mit 12-Pixel-Rand.
`NauticalTheme` bindet diese Zustände in Einstieg und Command Deck ein.
Primäre Einstiegsschaltflächen bleiben bewusst goldfarben; Arsenal/Journal behalten ihre
bestehenden UI-Stile. Nicht das gesamte HUD ist bereits in Grafikdateien ausgelagert.

Für spätere PNGs/Texturen Loaderpfade in `NauticalTheme` ändern und Nine-Patch-Ränder
anpassen. Wasser, Wake, Schaum und Treffer sind Shader-/Mesh-/FX-Systeme, keine GLBs.

## Abnahme bleibt offen

Headless-Tests beweisen Laden, Grenzen und Zustandswechsel, nicht gutes Aussehen.
Die Platzhalter sind stilisiert und detailarm. Das Mockup ist eine Zielreferenz,
kein Screenshot des aktuellen Projekts. Geräte-FPS, GPU-Speicher und Lesbarkeit
bei Sonne/kleinen Displays sind erst auf echter Hardware belastbar.
