# M33 — Modelle und Grafiken austauschen

## Grundprinzip

Ein stabiler Slot verbindet Gameplay mit der Grafik. Eigene Dateien nicht in das
Originalmanifest überschreiben: stattdessen data/visual_overrides.json verwenden.
Die Originaldateien bleiben als geprüfter Rückfall erhalten. Alle Pfade beginnen
mit res://assets/. Keine absoluten Laufwerkspfade, keine URLs, keine ../-Segmente.

## Beispiel

```json
{
  "schema": 1,
  "models": {
    "ship_small": {
      "path": "res://assets/custom/my_small_ship.glb",
      "fit_reference": true,
      "scale": [1, 1, 1],
      "offset": [0, 0, 0],
      "rotation_degrees": [0, 0, 0]
    }
  },
  "ui": {
    "captain_portrait": {
      "path": "res://assets/custom/my_captain.png"
    },
    "button_normal": {
      "path": "res://assets/custom/my_button.png",
      "slice_margin": 24
    }
  }
}
```

Die Beispieldateien sind keine mitgelieferten Modelle. Erst eigene Dateien ablegen.
In den Systemeinstellungen muss „3D-Grafiken → Austauschbare GLB-Platzhalter“ aktiv
sein. Dieser Modus verwendet auch eigene GLB-Ersatzdateien; der separate Modus
„Rekonstruierte Unity-Referenzen“ nutzt weiterhin den Legacy-Adapter.
Nicht aufgeführte Slots nutzen unverändert ihre Platzhalter. Korrekte Godot-Importierung
und Neustart sind erforderlich; kein beliebiges Hot-Reload während einer Spielsitzung.

## 3D-Vertrag

- Vollständige GLB mit eingebetteten Materialien/Texturen. Meter, +Y oben, +Z nach vorn.
- Schiffe/Inseln mit bewusstem Wasserlinien-Pivot. Keine Collider, Kameras, Navigation
  oder Scripts in den Visual-Dateien. Importierte Collider werden vom Visual-Check abgewiesen.
- fit_reference=true (Standard bei Ersatzdateien) passt die X/Z-Grundfläche gleichmäßig
  an den ursprünglichen Platzhalter an. Keine automatische Erkennung der Wasserlinie.
  Hohe Segel verkleinern den Rumpf dabei nicht über die Y-Ausdehnung.
- scale ist eine zusätzliche positive Skalierung; rotation_degrees korrigiert die Ausrichtung.
  offset ist der lokale Versatz, z. B. [0, -0.2, 0] für eine niedrigere Wasserlinie.
- Inselmodelle sind normalisiert: Der bestehende Insel-Wrapper skaliert Radius/Aspekt zusätzlich.
  Daher Inseln auch in der tatsächlichen Welt, nicht nur in der Einzelvorschau prüfen.
- Kollisionen, Trefferwerte, Kanonen-Sockets, Auswahlringe und Interaktionen bleiben am Wrapper.
  Ein Grafiktausch ändert sie NICHT. Absichtlich andere Gameplaygrößen sind ein eigener Schritt.
- Große Formunterschiede können trotz gleicher Grundfläche nicht automatisch zu einer bestehenden
  Trefferfläche passen. Der Tauschtest beweist Systemtrennung, nicht die visuelle Eignung jedes Modells.
- USER_REPLACEMENT bezeichnet nur eine selbst zugeordnete Datei, keine bestätigte Herkunft/Lizenz.

Bei fehlender/ungültiger Ersatzdatei wird der Platzhalter verwendet. Hinweise liegen in
VisualAssetCatalog.diagnostics. Das ist kein Sicherheits-Sandbox für beliebige Fremddateien.

## UI-Vertrag

SVG, PNG, WebP oder JPEG über dieselben Slot-IDs austauschbar. Transparente quadratische
Icons empfohlen; Porträt 1:1. Layout/Tippflächen stammen weiter aus den vorhandenen Controls.
Icons werden unter Beibehaltung ihres Seitenverhältnisses eingepasst.

Buttonzustände normal / hover / pressed / disabled / focus sind getrennte Slots.
slice_margin ist die Nine-Slice-Randbreite in Pixeln der Grafik; Standard 12.
Damit können z. B. hochauflösende PNGs eingebunden werden, ohne GDScript anzupassen.
Inhaltspolster und Touch-Flächen werden dadurch nicht geändert.

card gestaltet die Arsenal-Artikelkarten. captain_portrait ist auf der nicht kompakten
Startseite und im Desktop-HUD angebunden. Kleine Querformate erhalten keinen zusätzlichen
Porträtblock, damit Play und die See nicht unnötig verdrängt werden.
settings ist zunächst nur in der Vorschau sichtbar. Soziale Icons sind keine Onlinedienste.

## Prüfen

scenes/asset_preview.tscn → aktuelle Szene starten. Modell wählen, drehen, Grundfläche,
Bugrichtung, Y=0, Materialien, Namen/Status und Quellpfad prüfen.
Danach im Spiel Hafen, Beute, Schüsse, Auswahlring, HP-Labels und mobile Bedienung testen.
docs/m33_asset_audit.json enthält Bounds, Dreiecke, Oberflächen und Normalen-Vorhandensein.
Vorhandene Normalen beweisen nicht, dass sie visuell korrekt ausgerichtet sind.

M33 verändert keine M32-Freischaltungen oder Spielstände. Geräte-/GPU-Abnahme bleibt offen.
