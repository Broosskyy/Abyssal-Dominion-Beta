# M3050 – Prüfbericht

Engine tatsächlich ausgeführt: **4.7.2.stable.official.ed1daf0bf**.
Basis: M304.9 / 958dd7ea0f30a3ce972171e8c6375246401fe0ee.

## Neu

- Startmenü mit lokaler Karte und separater verbundener Testkarte.
- Godot-Zonenserver mit WebSocket, 20-Hz-Simulation, 10-Hz-Zustandsübertragung.
- Seekarten-Client verwendet bestätigte Serverpositionen, HP, Ammo und Wallet; lokale Kampf-/Beuteberechnung wird im Onlinezweig nicht aufgerufen.
- Server prüft Kurs, Inseln, Reichweite, Waffenklasse, Bestand, Cooldowns, Einkauf und einmalige Drop-Abholung.
- Zweiter Spieler wird als tatsächlicher Netzwerkspieler dargestellt; keine erfundene Onlinezahl.
- Alte lokale Werft-/Questmutationen im Onlinezweig deaktiviert.
- Verbindungsanzeige, Rückkehr zum Startmenü, Paket-/Befehlsgrenzen und Cleanup bei Trennung.
- Exportvorgaben aktualisiert und private APK-Ressourcen ausdrücklich von öffentlichen Exports ausgeschlossen.
- Manuell platzierte HUD-Controls erhalten passende feste Anker, damit Godot ihre Größen nicht durch frühere Streckanker überschreibt.
- Vorhandener Importtest brauchte eine explizite int-Deklaration für eine Actor-ID, damit Godot 4.7.2 ihn parsen kann.

## Prüfung

Die Maschinenresultate und Engine-Logs stehen neben dieser Datei in `test_results.json` und den sechs `.log`-Dateien.

1. Server-Simulation: Routen, Geschwindigkeit, ungültige Ziele, Replay, Ammo, Reichweite, Kill, Eigentümerbeute, einmalige Auszahlung und Kauf.
2. Echter WebSocket-End-to-End-Test: produktive Godot-Seekarte plus zweiter Socket-Client, gemeinsamer NPC-/Spielerzustand, Fahren, Feuer, Ammo und Loot. Keine Browser-/Android-/iOS-Exportabnahme.
3. Bestehende HUD-/Schiffszustandsprüfung.
4. Bestehende Munitions-/Werftprüfung mit mehreren Bildschirmgrößen.
5. Bestehende direkte Tap-to-Sail-/Routenprüfung.
6. Bestehende ZIP-Importprüfung einschließlich Pfadvalidierung und Erhalt von Spielwerten.

Jeder Test läuft mit einem frischen temporären Benutzerverzeichnis: Ein Grafikimport-Test darf keine künstlichen Testtexturen in die nächste Prüfung einschleusen. Beim neuen Spawnabstand wurde der Netzwerktest so angepasst, dass Fahrzeit plus Zustandsübertragung und visuelle Interpolation vollständig abgewartet werden.

Zusätzlich wurden reale Godot-OpenGL-Bilder mit den ausgewählten lokalen SeaBattles-Texturen in 1280×720 und 844×390 gerendert und angesehen. Ein überlappender Zurück-Button wurde danach korrigiert und erneut gerendert. Diese Bilder sind Linux-Desktopaufnahmen, keine Handy-Screenshots und kein FPS-Nachweis.

## Nicht abgenommen

Physische Android-/iOS-Bedienung, Browser-WASM-Export, Signierung, Internet-WSS-Betrieb, Login/Datenbank, Wiederverbindung, PvP, persistente Werft/Quests, NPC-Patrouillen, Kettenverlangsamung und MMO-Last.

Die Einschränkungen und der Ausbauplan stehen vollständig in `BAUPLAN_SEEKARTEN_MMO.md`. Der Server ist eine lokale Gast-Testzone, kein öffentlich betriebsbereiter MMO-Backenddienst.
