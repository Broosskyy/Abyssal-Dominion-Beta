# M388 – spielbare 20-Reviere-Welt (freiwilliger App-Test)

## Ziel und Sicherheitsgrenze

Die bisherigen **40 Seekarten (1/1–20/2)** bleiben mit ihren Original-IDs, Gildeninseln, registrierten Kapitänen, Leveln, alten Spielständen und Randwechseln erhalten. **20 zusätzliche Seekarten-Instanzen** (IDs 43–62) sind im Beta-Modus spielbar. Damit ersetzt die neue Welt die alte **nicht** automatisch. Der bisherige Spielstand ist stets wieder erreichbar.

Die neue Welt ist ausdrücklich ein **Gameplay-Prototyp**, kein fertiges Artwork-Remake: Sie nutzt die bestehenden Insel- und Schiffsmodelle und vereinigt pro Revier zwei bisherige Insel-Landschaften zu einer einzigen zusammenhängenden Seekarte. Individuelle Inselgrafiken, neue Monster-Assets, neue Schiffsdesigns und Munitionsanimationen folgen nach Gameplay-Abnahme.

## So wird getestet

1. Nach dem signierten App-Datenupdate **Seekarten → Weltkarte → 20 große Seekarten testen · Beta** öffnen.
2. Mit dem normalen Tap-to-Sail und dem identischen 2D-/3D-Kurs über eine **markierte Kartenkante** fahren. Es gibt weder Portale noch Bestätigungsdialoge.
3. Die vier Ecken haben je zwei Nachbarn, die übrigen zehn Rand-Reviere drei, und sechs innere Reviere vier.
4. Im Seekarten-Menü lässt sich der Testmodus über **Zur klassischen Welt zurück** verlassen. Das Schiff kehrt zum vorherigen normalen Kartenstand zurück; Gold, Fortschritt, Ausrüstung, Gildenstatus etc. werden nicht gelöscht.
5. Nach einem Neustart wird die zuletzt gespeicherte Welt wieder geöffnet. Beim freiwilligen Rückwechsel wird das letzte Beta-Revier für die nächste Testfahrt gespeichert.

Karten und Reviere sind levelgesperrt. Ein Treffer verhindert – wie im alten System – sechs Sekunden lang die Überfahrt. Eine Ankunft erfolgt innerhalb der gegenüberliegenden Kartengrenze, mit erhaltener Querkoordinate und kollisionsfreiem Start.

## Technische Eckdaten

- Historische Welt und Bonuskarten: **8800×6400** Weltkoordinaten pro physischer Seekarte.
- Neue Reviere: **17600×6400** pro physischer Seekarte, beide bisherige Insel-Lanes liegen auf einer einzigen zusammenhängenden Wasserfläche.
- Es gibt **20 zusätzliche ID-Räume** statt einer riskanten Umnummerierung alter 40 Seekarten.
- Serverseitiger Presence-/Multiplayer-Testcode validiert die zusätzlichen Räume und deren Weltgrenzen. **Der produktive Server muss separat aktualisiert werden**, bevor die neuen Reviere mit echten Online-Spielern auf dem neuen Server sichtbar sind. Dieses Feature darf vor einer solchen Freigabe nur für lokale Spieltests als gesichert gelten.
- Die gleiche 76-Weltpixel/s-M376-Steuerung, Kursberechnung und Render-Modi gelten in beiden Welten; Spielerbewegung ist nicht von 2D/3D abhängig.
- Das neue Weltlayout wird bei `configure_map` aus zwei ehemaligen Insel-Layouts mit gemeinsamen Kollisionen konstruiert; es entstehen keine Portale innerhalb des Reviers.
- Bonuskarten behalten ihre eigenen IDs und kehren bei ordnungsgemäßem Verlassen in die jeweilige Herkunftswelt zurück.
- Save-Schema 8 bleibt lesbar; neue Rückkehrfelder sind optional und ältere Saves wechseln niemals ohne Nutzeraktion automatisch zur Beta-Welt.

## Veröffentlichung / Nutzervorgaben

- **Android/App**: Jeder neue getestete Hauptstand wird weiterhin über die signierte GitHub-Datenrelease-Pipeline veröffentlicht; neue APK nur wenn wirklich native Änderungen erforderlich sind.
- **Vercel**: Automatische Deployments für Abyssal Dominion bleiben deaktiviert; GitHub soll Vercel weder benachrichtigen noch eigenmächtig ein neues Deployment anstoßen. Browser-GitHub-Testbuilds bleiben als separat herunterladbare Testpakete möglich.
- **Backend / neue Grafikassets**: keine stillschweigende Veröffentlichung und keine zusätzlichen API- oder Abo-Kosten.

## Prüfungen

M388-Godot-Test: Karten-ID-Zuordnung, 20 doppelt breite Reviere, 18 Inseln/Revier, vier-/drei-/zwei-seitige automatische Randübergänge, Level-Gates, Ankunftsposition, Speichern/Laden sowie reversible Weltumschaltung. M388-Mobil-Test: UI-Taster, tatsächlicher Wechsel in die Beta-Welt, Ruler-/Kamera-Abmessungen und Rückkehr ohne Ausrüstungsverlust. Dazu alte M376-/M385-/M386-Regressionen, WebGL-Test und vollständiger signierter Android-Build.
