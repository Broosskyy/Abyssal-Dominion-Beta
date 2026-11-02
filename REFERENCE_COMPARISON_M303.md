# Abyssal Dominion M303 — Referenzvergleich für Classic-Seafight-Aufbau
Datum: 2026-10-28. Status: Architekturentscheidung für den nächsten Gameplay-Vertical-Slice, **keine** bestätigte Funktionsimplementierung.

## Befund zur nutzerseitig gelieferten SeaBattles 1.24.0 APK
Nur statische Bestandsaufnahme, kein laufender Spieltest:
- APK/XAPK enthält Unity-6-/IL2CPP-Client, Grafik-/Texturressourcen und ausführbare Android-Bibliotheken; die ursprünglichen Grafiken sind urheberrechtlich geschützt und **nicht** für den eigenen Build freigegeben.
- Im zugänglichen `global-metadata.dat` finden sich UI-/Typzeichenketten: `expertSkillMenu`, `Skills`, `ShipEquipmentWindow`, `ShipUpgradeWindow`, `ShipDepotPanel`, `GuildIslandRowView`, `ClanBastions`, `BastionTemplate`.
- Eine Suche nach den exakten Metadatenbegriffen `castle`, `talent`, `skilltree`, `abilitytree` ergab keine Treffer. **Das beweist nicht die Abwesenheit** von Fähigkeiten oder Talenten, nur dass kein direkt nach so benannter klassischer Seafight-Kastell-/Talentbaum in den durchsuchten Typnamen sichtbar wurde.
- Insbesondere `ClanBastions` bezieht sich vermutlich auf Gilden-/Inselbefestigungen, **nicht** das Seafight-Kastellsystem für Schiffsmodule. Kontext müsste im laufenden Spiel verifiziert werden.
- Aufgrund möglicher Server-/Remote-Konfigurationen, Code-Obfuscation oder dynamischer UI ist die Menge der im Client angelegten Funktionen nicht mit dem vollen spielbaren Content gleichzusetzen.

## Vergleichsreferenzen
| Spiel | Belegte nutzbare Eigenschaft | Grenzen |
|---|---|---|
| SeaBattles: Pirate War (RoyaleGamesStudio) | Klassische Seekarte mit Schiffs-/NPC-Dichte, Zielwahl, Unity-Texturen und mobilem UI; Nutzer-APK zur statischen Technikrecherche vorhanden | Unklare Vollständigkeit von Kastellen, tiefen Talenten; andere Rechtsperson, keine Wiederverwendungsrechte |
| Son Korsan (Consala) | Offiziell beworbene Schiffsausbauten, Quests, Gilden, Angriffe auf Inseln, PvP-Arenen, verschiedene Ziele; zeigt klassisches See-MMO in öffentlicher Gameplay-Werbung | Keine bestätigte Seafight-1:1-Kastell-/Talentimplementierung, Contentmenge/Onlinezustand separat live prüfen. https://store.steampowered.com/app/645830/Son_Korsan/ |
| Battle of Sea: Pirate Fight (Gamepatron) | Android-Referenz mit Schiff-Upgrades, Gildenkampf, PvP-Karten, saisonalen Ranglisten, Events (Google Play aktualisiert 05.07.2026) | Keine durch offizielle Beschreibung bestätigten Seafight-Kastelle/Talentbäume. https://play.google.com/store/apps/details?id=com.gamepatron.battleofsea |
| Sea Bandits | Retro-Seafight-Entwicklungsreferenz; öffentlich beschriebene isometrische Seekarte + A*-Pathfinding, Karteneditor, Client-Server, Kartenwechsel, Gildeninseln und Event-/Questengine | Selbstangaben und Entwicklungsstand, keine Garantie veröffentlichter Quellcode, vollständiger Client oder überprüfbarer Features. https://www.elitepvpers.com/forum/seafight/4799648-sea-bandits-retro-seafight.html |
| Original Seafight | Verlässlicher Produkt-/Systembeleg für schiffsbezogene Kastelle, Module, Slots und Talentbaum mit mehreren Fähigkeitsseiten | Nachbildung als **eigene** Implementierung, keine Originalgrafiken, Originalcode oder geschützte Inhalte in Release aufnehmen. https://board-de.seafight.com/threads/die-kastelle.76533/ und https://board-de.seafight.com/threads/talente-faq.81860/ |

## Entscheidungsvorschlag
**Hybrid statt blindes Kopieren einer APK:** SeaBattles als technische/visuelle Referenz, Son Korsan und Battle of Sea für Feature-/Flow-Vergleich, Seafight-Fachsystematik für die eigene Progression, Sea Bandits als Engineering-Referenz. Nicht fortlaufend das Framework wechseln oder annehmen, die fremde APK enthalte Quellcode und Backend.

## Reihenfolge der eigenen Implementierung
1. Seekarte und 8-/16-Richtungs-Schiffsrendering: Look/Screen-Pixelgrößen, Tap-to-Sail, Island-Avoidance, Kamera.
2. Kampf und Loot: Ziel/Aggro/Auto-Fire/Munition/Harpune/Respawn/Quest.
3. Erste wirklich bedienbare **Kastell-Alternative**: 3 Schiffsteile als ausrüstbare Modulgruppen, echte Werte und Slotupgrades, datengesteuerte Module. Später auf 6 Gruppen ausbauen (eigenständige Namen/Balance).
4. Talente: eigene Offensiv-/Defensiv-/Wirtschaftsbäume; Punkte, Voraussetzungen, Respec, persistente Wirkungen.
5. Gilde/Turm/PvP/Ranglisten/Map-Portale/Events/Account; erst bei echten Server-Integrationen als live bewerten.
6. Neue Grafiken schrittweise in stabilen Sprite/Atlas-Slots ersetzen.

## QA
Keine Behauptung einer fertig spielbaren Kastell-/Talentfunktion durch bloße Typnamen. Jede Funktion muss UI bedienen, Spielwerte ändern, persistent gespeichert werden und ggf. serverautoritativ bestätigt sein. Native Web/Android Godot QA aktuell **nicht evaluiert**.
