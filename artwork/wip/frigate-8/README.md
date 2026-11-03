# Acht Richtungen: Fregatten-Entwurf, nicht im Spiel eingebaut

Status: WIP / Sichtprüfung offen. Kein neues APK und keine Änderung an den Laufzeitgrafiken.

Der zuerst erzeugte Schattenklaue-Satz wurde nach Nutzerhinweis verworfen. Segelflächen waren zu unabhängig vom Rumpf zur Kamera ausgerichtet; Rumpf, Heckaufbau und Perspektive wechselten uneinheitlich. Die vorbereiteten lokalen Laufzeitänderungen wurden zurückgenommen. Dieser Satz wurde nicht ins Repository übernommen.

Der neue Entwurf frigate_8_draft.png orientiert sich an der intakten unteren Zeile von rebuild/m3052/assets/fleet/elite4.png. Er enthält N, NE, E, SE / S, SW, W, NW mit konventionellem Holzrumpf und drei Masten. Seitlich sind die Rahsegel stärker verkürzt statt frontal sichtbar. Bug und Heck sind unterscheidbar.

Auch dieser Satz ist keine geometrisch garantierte Drehung. Mastabstände, Segelgrößen, Takelage und Deckdetails müssen beim Übergang geprüft werden; beispielsweise wirken die Mast-/Segelstaffelungen zwischen Nordost und Südwest unterschiedlich. Deshalb bleibt er außerhalb von rebuild/m3052/assets und ist weder als fertige Vorlage noch als getesteter Runtime-Satz freigegeben. Automatische Bildgenerierung allein reicht nicht als Konsistenznachweis.

Die nächste fachliche Prüfung vergleicht die acht Ansichten paarweise auf feste Mastpositionen, Rumpfproportionen, Segelausrichtung und eine unveränderte Kameraneigung. Erst nach Bestehen folgt ein Turntest im echten Spielrenderer. Das 2D-Ziel bleibt bestehen; es wurde kein 3D-Modell erstellt.

## Erzeugung

Integrierte Bildgenerierung, transparenter Hintergrund. Prompt in prompt.txt. Die ursprüngliche Referenz und alle bestehenden Projektdateien bleiben erhalten.
