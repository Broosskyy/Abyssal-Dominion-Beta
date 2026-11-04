# M34 — Mobile Navigation, HUD Comfort & Friendly Beginner NPCs

## Grundlage

Fortsetzung des M33-Source-Standes. Der Milestone setzt den aktuellen Mobile-/Seekarten-Feedback-Pass um, ohne spätere Guild-/Alliance-Systeme vorzutäuschen. Die Guild Bible bleibt Architekturvorgabe für spätere serverautoritative Systeme.

## Änderungen

- Kartenlevel 1–5: normale NPC-Schiffe sind neutral und patrouillieren. Nähe allein erzeugt keine Aggro.
- Wird ein neutraler NPC tatsächlich vom Spieler beschädigt, wird er provoziert, verfolgt den Angreifer und verwendet danach den vorhandenen Combat-AI-Pfad.
- Admiräle/Bosse bleiben von der Beginner-Neutralität ausgenommen.
- Mobile Tap-to-Sail bleibt Kernsteuerung. Zusätzlich kann der Finger über freies Wasser gezogen werden; der Navigationspunkt wird laufend aktualisiert. Dadurch sind unmittelbare Kurswechsel in jede Richtung möglich, ohne Combat/Reload abzuwarten.
- Der linke Steuerkreis bleibt gemäß Masterkonzept Kamera-Pan und bewegt nicht das Schiff.
- HUD-/Touch-Geometrie skaliert jetzt bounded mit hochauflösenden 1080p+-Canvasgrößen. Damit bleiben Feuer, Munition, Minimap, Navigation und obere Menüs auf modernen Handys physisch besser les- und treffbar.

## Grenzen

- Kein vollständiges Gilden-/Alliance-/Guild-Island-System in M34.
- Keine neuen finalen GLB-Assets.
- In dieser Build-Umgebung stand kein Godot-4.7.2-Binary für einen echten Engine-/APK-Lauf bereit; die Source wurde daher statisch geprüft und für den nächsten nativen Build vorbereitet.
