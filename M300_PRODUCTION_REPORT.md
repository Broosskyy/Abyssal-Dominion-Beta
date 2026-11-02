# M300 – vorläufiger Abschlussstand

V3.8 bleibt die Grundlage. Die Gildeninsel wird im lokalen Weltprototyp ab Seekartenlevel 2 mit fünf eigenständigen Turmrollen aufgebaut. Die Admin-Vorschau kann eigene, verbündete, feindliche und Kriegsbeziehungen zeigen. M300 ergänzt bei feindlich/Krieg pro Turm einen nur visuellen Warnpunkt, entfernt duplizierte Fokus-/Visualschichten bei wiederholter Vorschau und bewahrt die ausgewählte lokale Beziehung beim Neuaufbau und Teleport. Turmreichweiten und -Reload sind Beschreibungsprofile: weder Zielwahl noch Schuss, Schaden, Upgrades, Belagerung oder Inselbesitz sind dadurch live implementiert.

Halloween „Night of the Drowned“ besitzt einen lokal aktiven Prototyp mit Portal, Wrack, Flottenphasen, Boss und pro Insel einer austauschbaren Dekoration. M300 entfernt Event- und Inseldeko vor erneutem Aufbau und auch bei deaktiviertem Event; ausschließlich Gildeninseln im aktuellen Sektor werden dekoriert. Die lokalen Gegner-/Währungs-/Quest-Hooks sind ausdrücklich kein Produktions-Event, keine serverseitigen Rewards und kein geprüfter Saisondienst.

Anfangs bleibt jedes Schiff ein einzelnes vollständiges GLB/3D-Modell, keine modulare Schiffskonstruktion. Turm, Insel und Eventdekoration sind getrennte Weltobjekte. Seafight und Battle of Sea sind ausschließlich Clean-Room-Referenzen für Seekartenlesbarkeit und Atmosphäre; keine fremden Assets, Timings oder Regeln. Bestehende mobile Steuerungs-, Kamera- und Combat-Authority-Grenzen bleiben unangetastet.

Offen für einen späteren Produktionspfad: native Godot-Parser-/Spiel-/Mobiltests, echte Guild-/Krieg-/Turm-Serverlogik und Eventplanung/-abrechnung, gestaltete finale Assets sowie reale Qualitäts- und Performance-Messungen. Static source checks ersetzen keinen Godot-Lauf und keine Freigabe.

Validierung dieser Quelle: 458/458 statische Regression-/Contract-Funktionen, 17/17 Unittest-Fälle und 575/575 JSON-Dateien erfolgreich geprüft. Native Godot-Qualität bleibt NOT_EVALUATED.
