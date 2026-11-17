# M390 – Maritime Landmark Details & Monster Water VFX

## Ziel
Die 20 großen M388/M389-Reviere erhalten endlich sichtbare, geografisch passende Details und lebendigere Monster-Effekte, **ohne** den Classic-2D-/3D-Fahrtweg, World Coordinates, NPC-Kampfdaten, Gilden, Shop oder Speicherstände zu ändern.

## Implementierte Grafikschicht
Neue Datei: `rebuild/m3052/realm_visuals.gd`. Original, in Godot unmittelbar gezeichnete kleine maritime Wahrzeichen als dekorative Overlays **auf dem bestehenden Inselartwork**:

| Region | Details |
|---|---|
| Küstenbuchten (Revier 1–4) | Palmenwachen, Kalkstein, warme Küstenlichter |
| Handelsmeer (5–8) | Leuchtfeuer, Lotsentürme, hölzerne Stege und Navigationslaternen |
| Nordmeer (9–12) | Eisnadeln, Frostwarte, Kantenlichter |
| Kriegsgewässer (13–16) | ruinierte Bastionen, alte Zinnen, Windzeichen |
| Tiefenmeer (17–20) | verwitterte Steinbögen, Kalkrippen, versunkene Strukturen |

Pro Seekarte **sechs** vordefinierte größere Landmarken (drei auf jeder Kartenhälfte) mit leicht veränderten Motiven. Die übrigen zwölf Inseln behalten ihre sauber lesbare Grundform und das reale Kollisionsprofil. Die gezeichneten Details nutzen die vorhandenen Inseltopografien, werden in Weltkoordinaten mitgezählt, aber besitzen **keine eigene Kollisionsgeometrie**. Keine ungewollten Hindernisse, keine neuen Hafen-/Kartenrandblockaden.

Die aktuelle Original-Inselgrafik darunter wird **nicht ersetzt**. Das ist bewusst eine erste sichtbare Art- und Ambient-Verbesserung, kein irreführend behauptetes komplettes Grafik-Remake. Hochwertige einzelne Insel-/Monsterbilder werden später als austauschbare Art-Slots ergänzt. Die M389-Landmarks und Originaltexturen können dann für finale Designs weiterverwendet oder abgeschaltet werden.

## Monster- und Kampfeffekte
Für Monster in den 20 neuen Seekarten:
- Regionale Wasser-Ringe unter jedem lebenden Monster; Hauptwächter mit subtil größerer Präsenz.
- Zusätzliche Meeresschaum- und Blasenreaktionen bei **35 % Rest-HP**.
- Visuell unterschiedliche Harpunen-Treffer: kurze Wasserwelle und Spritzer, farblich abgestimmt auf das maritime Revier.
- Eigene Versink-Wasserwelle, Blasen und Schaum für Monster neben den bisherigen Sink-Effekten.

Diese Effekte hören nach dem Versinken auf, zählen keine Treffer dazu und verändern **weder Schaden noch Nachladezeit oder NPC-Bewegung**. Ein VFX-Marker wird nur an bestehende `impact`/`sunk`-Events geschrieben; kein neuer Kampf- oder Shop-Mechanismus.

## Mobile & Browser Performance
- Nur sichtbare Inseln im bestehenden kameragefilterten Draw-Pass; sechs Landmarken pro Revier, nicht 18.
- Keine zusätzlichen Shader-Texture-Samples, keine SubViewports, keine neuen GLBs, keine Shader-Animationen.
- Im Web-Fast-Modus weniger Polygone und Blasen; bisherige VFX-Schalter (Wasser/Einschlag/Animation) werden respektiert.
- Die Modell-/Grafikwechselschalter und M376 identische Navigation für beide Renderer bleiben unverändert.

## Qualität
- M390-Godot-Test: 20 Reviere, fünf Regionen, 6 Landmarken pro Revier, unveränderte Classic-Szenen, Szenen-Draw, Monster-VFX-Metadaten und unveränderte Spielerposition.
- M389-Gebiete, M388-Kanten und Save-Logik, M385-Decks sowie M376-Bewegung und Multiplayer-Server als Regression.
- Browser WebGL-Export und signiertes Android-Datenupdate verwenden den identischen Quellcode.
- **Vercel nie automatisch deployen.** Für das öffentliche Browser-Projekt ist Build-Skip/Preview-Off aktiviert und der GitHub-Workflow enthält keinen Vercel-Notify-Schritt. GitHub-Testbuilds bleiben erlaubt.
- Android-App-Daten-Updates nach geprüfter Freigabe immer automatisch veröffentlichen; native APK nur wenn nötig.

## Spätere visuelle Wellen
1. Fünf vollständige austauschbare Insel-Landmass-Assetsets (individuelle Küstenlinien, Hafendetails, Kollisions-Syncronisierung).
2. Vier Monster-Grundmodelle plus abweichende regionale Wächter und Animationsphasen, ohne die hier eingesetzten 20 Monsterarten nur umzubenennen.
3. Eigene Geschoss-/Einschlag-Spriteatlanten und deutlich unterscheidbare Zustände bei niedrigen HP/Versinken.
4. Mobile VFX-Profilwahl und visuelle Szene-Editor-Vorschau, in der dieselben regionalen Motive vor dem Spieltest zusammengestellt werden können.
