# 2D zuerst: Spielgrundlage und Referenzvergleich

Vorgabe vom 3. November 2026: Das Spiel bleibt zunächst vollständig 2D. Für diese Phase werden keine 3D-Modelle benötigt oder beauftragt. Ein verlässlicher spielbarer Kern hat Vorrang vor zusätzlichen Designs und Systemen.

## Referenzvergleich und Grenzen

Die vier verlinkten Videos wurden durch eine automatische Szenenanalyse ausgewertet. Die Zeitfenster sind Anhaltspunkte für eine anschließende Bild-für-Bild-Prüfung, keine Messung von Richtungsanzahl, Bildrate, Eingabelatenz oder Trefferpräzision. Die Rendertechnik der jeweiligen Spiele ist damit nicht bewiesen. Die fast 16 Minuten lange erste Analyse ist sehr allgemein und erhält geringeres Gewicht.

| Referenz | Abschnitte laut Szenenanalyse | Maßstab für unser Spiel |
| --- | --- | --- |
| [Video 1](https://youtu.be/agkQSCEul1s) | etwa 0:14–1:30 und 3:16–4:30: Schiffsgruppen, Geschosse und Inseln; Titel nicht sicher identifiziert | Eigener Rumpf, Ziel und Geschossursprung bleiben auch in Gruppen erkennbar |
| [Captain of Sea](https://youtu.be/pUrnvQRjhts) | 2:26–2:41: Angriffe/Belohnungen; 2:41–3:25: Fahrt, Karten und Kampf mit Lebensbalken | Verständliche Folge aus Fahren, Zielwahl, Schuss, Treffer und Belohnung |
| [Sea of Legend](https://youtu.be/TiXaVb90u8M) | 0:22–0:32: Schiffsgegner; 0:43–0:49: Monster; 0:54–1:06: große Schlacht | Unterscheidbare Gegner; Effekte verdecken weder Ziel noch Lebensbalken |
| [Video 4](https://youtu.be/NF1mf1ClBkU) | 0:00–0:25: Kampf/Schaden; 0:25–0:45: Fahrt/Kartenwechsel; Titel nicht sicher identifiziert | Lesbare Treffer und Orientierung; das Fenster „Gatus“ ist kein bestätigter Bestandteil des Spiel-HUDs |

Ein räumlicher Bildeindruck beweist keine Echtzeit-3D-Modelle. Richtungsabhängige 2D-Bilder und getrennte Effekte reichen für unsere feste Schrägansicht aus. Godot unterstützt Einzelbilder und Sprite-Sheets: [offizielle Dokumentation](https://docs.godotengine.org/en/stable/tutorials/2d/2d_sprite_animation.html).

## Nachgewiesener Projektstand

Der M3054-Quellgrafik-Audit erfasst 26 Schiffsgrafiken: 16 Atlanten mit je vier echten Richtungsansichten und zehn Konzeptgrafiken mit je einer Perspektive. Die 74 vermessenen intakten Frames sind keine vollständigen Acht-Richtungs-Sätze.

M3054 korrigiert Spiegelpunkt, Atlas-Spaltenzuordnung und Größenberechnung einschließlich transparenter Ränder. Der kontrollierte Fahrtest belegt die Ankerkorrektur; er beweist weder vollständige Perspektiven noch fehlerfreie Android-Bedienung. Siehe [Render-Audit](../m3054/SHIP_RENDER_AUDIT.md).

## Reihenfolge bis zu einer soliden Grundlage

1. Ein Referenzschiff mit den vorhandenen vier Richtungen prüfen: Rumpf, Auswahlpunkt, Schatten, Kielwasser und Geschossursprung bleiben beim Kurswechsel zusammen. Einbild-Konzepte dienen nicht als Referenz für korrekte Perspektivwechsel.
2. Den vollständigen Ablauf prüfen: um Inseln fahren, Ziel wählen/wechseln, Reichweite erreichen, schießen, Treffer erhalten, Gegner versenken, Beute einmal aufnehmen, Hafen erreichen und reparieren.
3. Den Ablauf auf Android prüfen: Wasserklick gegenüber Zielwahl, Ziehen/Zoomen, Menübedienung und Fortschritt nach einem Neustart. Automatisierte Tests ersetzen diese Geräteprüfung nicht.
4. Erst nach diesem Nachweis weitere Schiffsgrafiken und Richtungen ausbauen.

Acht intakte plus acht beschädigte Ansichten pro Schiff sind als reines 2D-Ziel möglich. Dafür müssen konsistente Richtungsbilder erstellt und geprüft werden; Spiegeln eines Bilds erzeugt keine echte Bug- oder Heckansicht. Vollständige Zerstörung ist zusätzlich ein Versenkungszustand mit deaktivierter Bewegung und Waffen. Zusätzliche Bilder sind keine Voraussetzung für die Stabilisierung der Spielmechanik.

## Abnahmekriterien

- Keine Positionssprünge beim Spiegeln oder Wechsel vorhandener Richtungsbilder.
- Angezeigtes Ziel, Trefferpunkt und Lebensbalken gehören zum gleichen Gegner.
- Schuss, Treffer, Tod und Beutefund lösen jeweils genau die vorgesehene Wirkung aus.
- Fahrziele bleiben außerhalb der Inselhindernisse; Menüklicks lösen keine Fahrt aus.
- Speichern und Neustart erhalten den vorgesehenen Fortschritt.
- Ein dokumentierter Android-Durchlauf bestätigt den Kernablauf zusätzlich zu CI-Tests und Renderaufnahmen.

Diese Änderung dokumentiert Vorgabe und Vergleich. Sie enthält keine neuen Laufzeitkorrekturen und keinen neuen APK-Build. Die Kriterien gelten nicht als vollständig auf einem Gerät bestanden.
