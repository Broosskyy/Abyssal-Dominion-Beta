# Abyssal Dominion · Master-Progressionskarte Schiffe

Erzeugt aus `rebuild/m3052/tools/ship_roster.py` (dort bearbeiten, dann neu erzeugen). Grundlage: *Schiffsprogression-Masterkonzept* (3 Starter → 100 Klassen → Prestige P1–P5, getrennte Design-Pools) und die vorhandenen Abyssal-Dominion-Konzeptbögen. Vom Genre übernommen ist nur die Struktur (kleine Starter, schrittweise Steigerung, separate Event-/Boss-Pools), keine fremden Schiffe, Namen oder Optik.

Umfang: 108 spielbare Klassen (davon 48 neu entworfen), 18 NPC-Typen, 20 Spezial-/Event-Designs. Werte sind Startwerte (1–10) für das Balancing.

## Generationen

| Gen. | Klassen | Optik | Grenze |
| --- | --- | --- | --- |
| Starter | S1–S3 | Normal, lesbar, charaktervoll; altes Holz, neutrale Segel, wenig Metall | Keine Elite-Optik, keine Fantasy-Motive |
| Generation I · Küstenflotte | 1–10 | Holz, Leinen, Messing; Kutter, Sloop, Kogge; 1–2 Masten; warme Naturtöne mit je einer Akzentfarbe | Bodenständig, keine Glow-Effekte |
| Generation II · Handelsrouten | 11–20 | Neue Rümpfe: Karavelle, Schoner, Brigg, Fleute; regionale Farbwelten (Mittelmeer-Terrakotta, Nordmeer-Klinkerblau, Tropen-Türkis) | Erste Themen über Bemalung und Segelzeichen, noch realistisch |
| Generation III · Kriegsmarine | 21–30 | Korvette, Fregatte, Galeasse; Kanonendecks, Ruderreihen, Metallbeschläge; Flaggen der Flotten | Spürbar mächtiger, aber noch keine Magie |
| Generation IV · Erste Elite | 31–40 | Dunkles Eisen, Stachelbug, schwere Kanonen, einzelne Leuchtakzente (Elite-Bogen 01–10) | Mehr Dominanz; Geistermotive nur dezent |
| Generation V · Ferne Kulturen | 41–50 | Dschunke, Dau, Katamaran, Polar- und Wüstenschiffe, Elfen- und Kristallkaravellen | Starke Identität über Kultur, nicht über Horror |
| Generation VI · Außergewöhnliche Bauweisen | 51–60 | Dampf, Panzerung, Zahnräder, Mischformen aus Tier und Schiff (Wal, Dünenläufer) | Fantasy-Anteil steigt |
| Generation VII · Legendäre Kriegsschiffe | 61–70 | Prunkvolle Linienschiffe, Sonnen-, Mond- und Sturmorden; Gold, Silber, Gewitter | Starke Formen und Materialien, noch keine Abyss-Motive |
| Generation VIII · Nebel und Tiefe | 71–80 | Geister, Nebel, Biolumineszenz, Knochen, erste Tentakel | Extreme Motive beginnen |
| Generation IX · Verfluchte Spitzenklasse | 81–90 | Käfige, Dämonen, Kraken, Höllenfeuer; starke Effekte und Silhouetten | Sehr starke Effekte, aber klar lesbare Silhouette |
| Generation X · Abyssale Endstufe | 91–100 | Lebende Schiffe, Leviathane, Leere und Sterne; ikonische Spitzenklassen | Maximale reguläre Eskalation |
| Prestige | P1–P5 | Eigenständige Statuskategorie, je ein einzigartiges Leitmotiv | Nicht Klasse 101–105 |

## Starter (S1–S3)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| S1 | **Küstenschaluppe** | Schaluppe (vorhanden, SHIP-STARTER-001) | 1 Mast, Gaffelsegel + Fock | altes Holz, Leinen · schlichte Bronzeakzente | Ausgewogen | 1 · 1 · 1 | vorhanden im Spiel |
| S2 | **Blauwasser-Kutter** | Kutter, länger und breiter | 2 Masten, Gaffel + Toppsegel | gedämpftes Dunkelblau, helles Leinen · Anker auf dem Großsegel | Schnell / Aufklärer | 1 · 1 · 3 | neu (Masterkonzept Starter 02) |
| S3 | **Grauer Wächter** | kleine Brigg mit schwerem Rumpf | 2 Masten, Rahsegel | Grau/Schwarz, dunkles Holz, Eisen · genietete Bugplatte | Defensiv / Tank | 3 · 1 · 1 | neu (Masterkonzept Starter 03) |

## Generation I · Küstenflotte (1–10)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | **Möwenkutter** | Kutter | 1 Mast, Gaffelsegel | Naturholz, Leinen, Weiß · Möwenwimpel | Schnell / Aufklärer | 1 · 1 · 4 | neu |
| 2 | **Ankerlicht** | Sloop | 1 Mast, Gaffel + Fock | Holz, Leinen, Messinglaterne · Laterne am Heck | Ausgewogen | 2 · 2 · 2 | neu |
| 3 | **Salzkogge** | Kogge, hoher Freibord | 1 Mast, ein großes Rahsegel | Eiche, ungefärbtes Segel · Fässer an Deck | Defensiv / Tank | 4 · 1 · 1 | neu |
| 4 | **Brisenläufer** | Sloop, schlank | 1 Mast, Gaffel + Toppsegel | helles Holz, Himmelblau · blauer Streifen am Rumpf | Schnell / Aufklärer | 1 · 1 · 4 | neu |
| 5 | **Hafenkrähe** | bewaffneter Kutter | 1 Mast, Gaffel | dunkles Holz, Schwarz · Krähenwimpel, 2 Drehbassen | Angriff | 1 · 4 · 2 | neu |
| 6 | **Leuchtturmsloop** | Sloop | 1 Mast, Gaffel + 2 Vorsegel | Weiß/Rot geringelt · rot-weiße Bordwand | Taktik / Support | 3 · 1 · 2 | neu |
| 7 | **Bernsteinkogge** | Kogge mit Achterkastell | 1 Mast, Rahsegel + Besan | Honigholz, Bernsteingelb · gelbes Segel mit Sonnenring | Ausgewogen | 2 · 2 · 2 | neu |
| 8 | **Riffkutter** | breiter Kutter | 2 Masten, Gaffel | Holz, Türkis · Korallenrot am Bug | Entern / Nahkampf | 3 · 3 · 1 | neu |
| 9 | **Grünspan-Sloop** | Sloop mit Kanonendeck | 2 Masten, Gaffel + Toppsegel | Holz, Kupfer/Grünspan · Kupferbeschlag am Bug | Kanonenspezialist | 2 · 4 · 1 | neu |
| 10 | **Kapitänskogge** | große Kogge, Vor- und Achterkastell | 2 Masten, Rahsegel | dunkles Holz, Weinrot, Messing · erstes Familienwappen | Schwer / Belagerung | 4 · 3 · 1 | neu |

## Generation II · Handelsrouten (11–20)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 11 | **Terrakotta-Karavelle** | Karavelle | 2 Masten, Lateinersegel | Terrakotta, Sand · Sonnenrad | Schnell / Aufklärer | 2 · 2 · 5 | neu |
| 12 | **Nordklinker** | Klinkerrumpf-Brigg | 2 Masten, Rahsegel | Klinkerblau, Weiß · Schneeflockenwimpel | Defensiv / Tank | 5 · 2 · 2 | neu |
| 13 | **Türkisschoner** | Schoner | 2 Masten, Gaffel | Türkis, helles Holz · Muschelornament | Schnell / Aufklärer | 2 · 2 · 5 | neu |
| 14 | **Gewürzfleute** | Fleute, bauchiger Rumpf | 3 Masten, Rahsegel | Zimtbraun, Safrangelb · Gewürzsäcke an Deck | Taktik / Support | 4 · 2 · 3 | neu |
| 15 | **Silbermöwe** | Toppsegelschoner | 2 Masten | Silbergrau, Weiß · Möwenfigur am Bug | Ausgewogen | 3 · 3 · 3 | neu |
| 16 | **Lagunenbrigg** | Brigg | 2 Masten, Rahsegel | Lagunengrün, Elfenbein · Wellenband | Kanonenspezialist | 3 · 5 · 2 | neu |
| 17 | **Marktkaravelle** | Karavelle mit Achterdeck | 3 Masten, Rah + Lateiner | Purpur, Gold · Gildenbanner der Handelsliga | Taktik / Support | 4 · 2 · 3 | neu |
| 18 | **Frostfleute** | Fleute, verstärkter Bug | 3 Masten | Eisblau, Grau · Eisbrecherkeil (dezent) | Defensiv / Tank | 5 · 2 · 2 | neu |
| 19 | **Korsarenschoner** | schneller Schoner | 2 Masten, Gaffel + Rah | Schwarz/Rot · gekreuzte Säbel | Angriff | 2 · 5 · 3 | neu |
| 20 | **Seidenstraßen-Brigg** | große Brigg | 2 Masten + Klüver | Jade, Rotlack · Laternenreihe | Ausgewogen | 3 · 3 · 3 | neu |

## Generation III · Kriegsmarine (21–30)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 21 | **Kanonenfalke** | Korvette | 3 Masten | Marineblau, Weiß · Falkenwappen | Kanonenspezialist | 3 · 5 · 2 | neu |
| 22 | **Remora-Galeasse** | Galeasse mit Ruderreihe | 2 Masten, Lateiner | Rot, Bronze · Ramme am Bug | Entern / Nahkampf | 4 · 4 · 2 | neu (Idee aus NPC-Bogen Galeasse) |
| 23 | **Eisenmöwe** | leichte Fregatte | 3 Masten | Grau, Eisen · genietete Bordwand | Defensiv / Tank | 5 · 2 · 2 | neu |
| 24 | **Brandungsbrecher** | Korvette, niedriger Rumpf | 2 Masten, Rah | Sturmgrau, Weiß · Wellenbug | Schnell / Aufklärer | 2 · 2 · 5 | neu |
| 25 | **Kronenkorvette** | Korvette mit Prunkheck | 3 Masten | Königsblau, Gold · Lilie/Krone (eigene Form) | Ausgewogen | 3 · 3 · 3 | neu |
| 26 | **Salvenbrigg** | Kanonenbrigg, 2 Decks | 2 Masten | Ochsenblut, Schwarz · doppelte Kanonenreihe | Kanonenspezialist | 3 · 5 · 2 | neu (Idee aus NPC-Bogen Kanonen-Brig) |
| 27 | **Riffjäger** | Fregatte, schlank | 3 Masten | Seegrün, Messing · Haizahnreihe am Bug | Angriff | 2 · 5 · 3 | neu |
| 28 | **Mörserkogge** | Bombardierkogge | 2 Masten | Ruß, Bronze · Mörser mittschiffs | Schwer / Belagerung | 5 · 4 · 1 | neu |
| 29 | **Wachfregatte** | Fregatte | 3 Masten | Weiß, Ankerblau · Ankerwappen (Wache) | Defensiv / Tank | 5 · 2 · 2 | neu |
| 30 | **Admiralitätsfregatte** | schwere Fregatte | 3 Masten + Klüver | Dunkelblau, Gold · Flaggenreihe, Galionsfigur | Ausgewogen | 3 · 3 · 3 | neu |

## Generation IV · Erste Elite (31–40)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 31 | **Sturmwind** | schnelles Eliteschiff | 3 Masten | Schwarz, Messing · Kompassrose | Schnell / Aufklärer | 3 · 3 · 6 | Bogen Elite 01 |
| 32 | **Seelenreißer** | ausgewogenes Eliteschiff | 3 Masten | Nachtblau, Gold · Sternrad | Ausgewogen | 4 · 4 · 4 | Bogen Elite 02 |
| 33 | **Eisenwächter** | Panzerschiff | 3 Masten | Eisengrau · Plattenpanzer | Defensiv / Tank | 6 · 3 · 3 | Bogen Elite 03 |
| 34 | **Wilderzahn** | Angriffsschiff | 3 Masten | Schwarz, Blutrot · Zahnbug | Angriff | 3 · 6 · 4 | Bogen Elite 04 |
| 35 | **Geisterkorsar** | listiges Eliteschiff | 3 Masten | Schwarz, Giftgrün · grüne Laternen (dezent) | Taktik / Support | 5 · 3 · 4 | Bogen Elite 05 |
| 36 | **Donnerklaue** | Kanonenschiff | 3 Masten | Bronze, Ocker · Kanonenbatterie | Kanonenspezialist | 4 · 6 · 3 | Bogen Elite 06 |
| 37 | **Tiefenfurie** | Spezialist für Entern | 3 Masten | Violett, Schwarz · Enterhaken | Entern / Nahkampf | 5 · 5 · 3 | Bogen Elite 07 |
| 38 | **Schattenwind** | Aufklärer | 3 Masten | Petrol, Schwarz · Sternenkarte | Schnell / Aufklärer | 3 · 3 · 6 | Bogen Elite 08 |
| 39 | **Flammenbanner** | Feuerschiff | 3 Masten | Glutorange, Schwarz · Feuerbanner | Feuer / Schaden über Zeit | 3 · 6 · 4 | Bogen Elite 09 |
| 40 | **Sturmbasilisk** | schweres Eliteschiff | 3 Masten | Grau, Knochenweiß · Basiliskenkopf | Schwer / Belagerung | 6 · 5 · 2 | Bogen Elite 10 |

## Generation V · Ferne Kulturen (41–50)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 41 | **Jade-Dschunke** | Dschunke, Lattensegel | 3 Masten | Jade, Gold · Drachenornamente | Ausgewogen | 5 · 5 · 5 | Bogen D-41 |
| 42 | **Wüsten-Skimmer** | Wüstennomaden-Schiff | 2 Masten, Lateiner | Sand, Ocker · Sonnenzeichen | Schnell / Aufklärer | 4 · 4 · 7 | Bogen D-42 |
| 43 | **Wüsten-Dahow** | Dau | 2 Masten, Lateiner | Sandbeige, Rot · Sternsegel | Taktik / Support | 6 · 4 · 5 | Bogen D-12 |
| 44 | **Silberwind** | Elfenschiff | 3 Masten, geschwungen | Silber, Nachtblau · Blattsegel | Schnell / Aufklärer | 4 · 4 · 7 | Bogen D-44 |
| 45 | **Luminara** | Himmelspriester-Schiff mit Türmen | 2 Türme + Mast | Elfenbein, Himmelblau, Gold · Kuppeln | Taktik / Support | 6 · 4 · 5 | Bogen D-46 |
| 46 | **Kristallkaravelle** | Gilden-Handelsschiff | 3 Masten | Rosé, Kristall, Gold · Kristallbesatz | Defensiv / Tank | 7 · 4 · 4 | Bogen D-48 |
| 47 | **Monsunreiter** | Auslegerboot (Proa) mit Krabbenscherensegel | 2 Masten | Tropenholz, Orange · Muschelketten | Schnell / Aufklärer | 4 · 4 · 7 | neu |
| 48 | **Fjordwacht** | nordisches Langschiff, Schildreihe | 1 Mast, Rahsegel + Ruder | Teer, Rot/Weiß gestreift · Schildreihe, Wolfskopf-Steven | Entern / Nahkampf | 6 · 6 · 4 | neu |
| 49 | **Polarbrecher** | Polarschiff der Nordstämme | 3 Masten | Eisblau, Weiß · Eiskeil | Defensiv / Tank | 7 · 4 · 4 | Bogen D-51 |
| 50 | **Sonnenflamme** | Phönix-Kult-Schiff | 3 Masten | Feuerrot, Gold · Phönix-Galionsfigur | Feuer / Schaden über Zeit | 4 · 7 · 5 | Bogen D-50 |

## Generation VI · Außergewöhnliche Bauweisen (51–60)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 51 | **Dampfsturm** | Dampfschiff (Imperiale Flotte) | Schlote statt Segel | Rost, Schwarz, Messing · drei Schornsteine | Schwer / Belagerung | 8 · 7 · 4 | Bogen D-49 |
| 52 | **Blutkrallen-Katamaran** | Kriegskatamaran | 2 Rümpfe, 3 Masten | Schwarz, Rot · Krallenbug | Angriff | 5 · 8 · 6 | Bogen D-45 |
| 53 | **Sturmwal** | Walrumpf-Mega-Schiff | 3 Masten | Nachtblau, Gewitterblau · Walkopf als Bug | Defensiv / Tank | 8 · 5 · 5 | Pack 07 |
| 54 | **Dünenschreiter** | Wüstenkriegsschiff | 3 Masten | Sand, Bronze · Sandsturm-Effekt | Ausgewogen | 6 · 6 · 6 | Pack 08 |
| 55 | **Mech-Panzerschiff** | gepanzertes Dampfschiff mit Rädern | Schlote | Bronze, Türkis-Lichter · Kanonenturm | Schwer / Belagerung | 8 · 7 · 4 | Bogen D-15 |
| 56 | **Kupferkoloss** | Halbtaucher mit Kupferkuppel | 1 Hilfsmast | Kupfer, Grünspan · Bullaugen-Reihe | Defensiv / Tank | 8 · 5 · 5 | neu |
| 57 | **Windmühlenträger** | Rotorschiff | 2 Rotortürme | Holz, Ziegelrot · drehende Flügel | Taktik / Support | 7 · 5 · 6 | neu |
| 58 | **Eisbrecher** | Fraktionsschiff | 3 Masten | Dunkelblau, Eis · Schneekristall-Segel | Defensiv / Tank | 8 · 5 · 5 | Pack 09 / Bogen D-13 |
| 59 | **Raketenkogge** | Kogge mit Raketengestellen | 2 Masten | Schwarz, Signalgelb · Raketenbatterie | Feuer / Schaden über Zeit | 5 · 8 · 6 | neu |
| 60 | **Eisenhager** | Panzerschiff | 3 Masten | Eisen, Weiß · Plattenbug | Schwer / Belagerung | 8 · 7 · 4 | Variation 14/15 |

## Generation VII · Legendäre Kriegsschiffe (61–70)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 61 | **Sonnenlanze** | Heiliger-Orden-Schiff | 3 Masten | Weiß, Gold · Sonnenrad | Ausgewogen | 7 · 7 · 7 | Pack 04 / Bogen D-17 |
| 62 | **Sternenwind** | schnelles Spielerschiff | 2 Masten | Silber, Weiß, Blitzblau · Kompassstern | Schnell / Aufklärer | 6 · 6 · 9 | Pack 02 |
| 63 | **Sturmjäger** | Sturmschiff | 3 Masten | Schwarz, Blitzblau · Blitzadern | Angriff | 6 · 9 · 7 | Variation 05 |
| 64 | **Mondlichtjäger** | Nachtjäger | 3 Masten | Mitternachtsblau, Silber · Mondsichel | Schnell / Aufklärer | 6 · 6 · 9 | Variation 21 |
| 65 | **Kapitänsflagge** | Admiralsschiff | 3 Masten | Schwarz, Gold · Kapitänswappen | Taktik / Support | 8 · 6 · 7 | Variation 10 |
| 66 | **Stahlpanzer** | Panzerlinienschiff | 3 Masten | Stahl, Schwarz · Panzerplatten | Defensiv / Tank | 9 · 6 · 6 | Variation 23 |
| 67 | **Sonnenfluch** | Prunkgaleone | 2 Masten | Weiß, Gold, Bronze · Sonnensegel | Kanonenspezialist | 7 · 9 · 6 | Variation 20 |
| 68 | **Goldener Wächter** | Prunklinienschiff | 3 Masten | Gold, Elfenbein · Löwenbug | Defensiv / Tank | 9 · 6 · 6 | neu |
| 69 | **Gewitterkrone** | Linienschiff mit Blitzableitern | 3 Masten | Schiefer, Blitzweiß · Kupferspitzen auf den Masten | Kanonenspezialist | 7 · 9 · 6 | neu |
| 70 | **Dunkelsegler** | schweres Kriegsschiff | 3 Masten | Schwarz, Grau · schwarzes Wappen | Angriff | 6 · 9 · 7 | Variation 15 |

## Generation VIII · Nebel und Tiefe (71–80)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 71 | **Schattenklaue** | kleines Geisterschiff | 1 Mast | Schwarz, Giftgrün · Totenkopf, grüner Nebel | Schnell / Aufklärer | 6 · 6 · 9 | Pack 01 |
| 72 | **Nebelreiter** | Phantomschiff | 3 Masten | Grau, Geistertürkis · Nebelschleier | Taktik / Support | 8 · 6 · 7 | Pack 06 / Variation 09 |
| 73 | **Tiefenangler** | Meereskreatur-Jäger | 2 Masten | Dunkelblau, Leuchtgrün · Angler-Laterne am Bug | Angriff | 6 · 9 · 7 | Bogen D-43 |
| 74 | **Nebelwanderer** | Nebelpiraten-Schiff | 3 Masten | Schwarz, Violett · Violette Laternen | Schnell / Aufklärer | 6 · 6 · 9 | Bogen D-47 |
| 75 | **Schattenwisp** | Irrlicht-Schiff | 3 Masten | Nachtblau, Irrlichtblau · blaue Flammen | Taktik / Support | 8 · 6 · 7 | Bogen D-18 |
| 76 | **Geisterflamme** | verfluchtes Schiff | 3 Masten | Schwarz, Geistergrün · grüne Flammen | Feuer / Schaden über Zeit | 6 · 9 · 7 | Variation 04 |
| 77 | **Knochenkiel** | Knochenschiff | 1–3 Masten | Knochenweiß, Schwarz · Rippenrumpf | Defensiv / Tank | 9 · 6 · 6 | Variation 01/13 |
| 78 | **Sirenenzorn** | Sirenen-Schiff | 3 Masten | Tiefblau, Perlmutt · Sirenen-Galionsfigur | Taktik / Support | 8 · 6 · 7 | Variation 08/18 |
| 79 | **Grabesstille** | Gruftschiff | 3 Masten | Schwarz, Violett · Grabsteinreihe | Defensiv / Tank | 9 · 6 · 6 | Variation 14/24 |
| 80 | **Tiefenzorn** | Krakenschiff | 3 Masten | Schwarz, Violett · erste Tentakel | Entern / Nahkampf | 8 · 8 · 6 | Variation 03/07 |

## Generation IX · Verfluchte Spitzenklasse (81–90)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 81 | **Seelenkäfig** | Käfigschiff | 2 Masten + Käfig | Schwarz, Seelengrün · gefangene Seele | Taktik / Support | 9 · 7 · 8 | Bogen D-11 / Variation 06 |
| 82 | **Blutkrake** | Krakenschiff | 3 Masten | Schwarz, Blutrot · Krakensegel | Entern / Nahkampf | 9 · 9 · 7 | Variation 13 |
| 83 | **Fluchbringer** | Fluchschiff | 3 Masten | Schwarz, Giftgrün · Runenzeichen | Feuer / Schaden über Zeit | 7 · 10 · 8 | Variation 17/20 |
| 84 | **Schemenkommandant** | Geister-Flaggschiff | 3 Masten | Schwarz, Violett · Geisterkapitän | Ausgewogen | 8 · 8 · 8 | Variation 16/17 (dt. Name statt Wraith Commander) |
| 85 | **Todeswind** | Sturmgeisterschiff | 3 Masten | Schwarz, Violettnebel · zerrissene Segel | Schnell / Aufklärer | 7 · 7 · 10 | Variation 12/22 |
| 86 | **Verdammnis** | Höllenschiff | 3 Masten | Schwarz, Glutrot · Rissmuster | Angriff | 7 · 10 · 8 | Variation 09/11 |
| 87 | **Dämonenkiel** | Dämonenschiff | 3 Masten | Schwarz, Rot · Hörner am Bug | Angriff | 7 · 10 · 8 | Variation 18/22 |
| 88 | **Dämonen-Katamaran** | Doppelrumpf-Dämon | 3 Masten | Schwarz, Violett · Stachelrümpfe | Schnell / Aufklärer | 7 · 7 · 10 | Bogen D-14 |
| 89 | **Krakenruf** | Event-/Krakenschiff | 3 Masten | Schwarz, Violettlicht · umschlingende Tentakel | Defensiv / Tank | 10 · 7 · 7 | Pack 03 |
| 90 | **Höllenfeuer** | Boss-Optik als Klasse | 3 Masten | Schwarz, Lava · Drachenbug, Feuer | Feuer / Schaden über Zeit | 7 · 10 · 8 | Pack 05 |

## Generation X · Abyssale Endstufe (91–100)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 91 | **Chaosbringer** | Chaos-Galeone | 3 Masten | Schwarz, Rot · Chaosstern | Angriff | 8 · 10 · 9 | Variation 16/25 |
| 92 | **Goldene Verderbnis** | verfluchte Schatzgaleone | 3 Masten | Schwarzgold · Goldschädel | Kanonenspezialist | 9 · 10 · 8 | Variation 12/19 |
| 93 | **Abyssal Schattentiefe** | Tiefseeschiff | 3 Masten | Schwarz, Tiefseetürkis · Leuchtorgane | Ausgewogen | 9 · 9 · 9 | Variation 07/21 |
| 94 | **Leviathan** | Schiff mit Maulsegel | 3 Masten | Schwarz, Knochen · Zahnmaul im Segel | Schwer / Belagerung | 10 · 10 · 7 | Variation 08/24 |
| 95 | **Voidreiter** | Sternenfahrer | geschwungene Klingensegel | Schwarzviolett, Leerenlicht · Leerenauge | Schnell / Aufklärer | 8 · 8 · 10 | Bogen D-52 |
| 96 | **Abyssal-Leviathan** | lebendes Monsterschiff | 3 Masten auf Kreaturenrücken | Schwarz, Abyssgrün · Kreaturenkopf mit Tentakeln | Schwer / Belagerung | 10 · 10 · 7 | Pack 10 / Bogen D-16 |
| 97 | **Abgrundkrone** | Korallen-Abyss-Galeone | 3 Masten | Tiefschwarz, Perlweiß · Krone aus Korallenzacken | Defensiv / Tank | 10 · 8 · 8 | neu |
| 98 | **Weltenschlund** | Strudelschiff | 2 Masten um Strudelkern | Nachtblau, Strudelweiß · rotierender Wirbel im Rumpf | Taktik / Support | 10 · 8 · 9 | neu |
| 99 | **Sternenbrecher** | Meteorgaleone | 3 Masten | Basalt, Glut, Sternenweiß · Meteoritenbug | Kanonenspezialist | 9 · 10 · 8 | neu |
| 100 | **Abyssal Dominion** | Flaggschiff der Tiefe | 4 Masten | Schwarz, Gold, Abyssgrün · Dominion-Wappen | Schwer / Belagerung | 10 · 10 · 7 | neu |

## Prestige (P1–P5)

| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P1 | **Ozeanherz** | Perlmutt-Galeone | 3 Masten | Perlmutt, Türkis · pulsierendes Herz im Heck | Taktik / Support | 10 · 9 · 10 | neu |
| P2 | **Aschenphönix** | brennende Galeone, die nie verbrennt | 3 Masten | Asche, Glut · Phönixflügel als Segel | Feuer / Schaden über Zeit | 9 · 10 · 10 | neu |
| P3 | **Sonnenfinsternis** | Schwarzgold-Linienschiff | 3 Masten | Schwarz, Korona-Gold · verdeckte Sonne | Angriff | 9 · 10 · 10 | neu |
| P4 | **Ewige Flut** | Wasser-Elementarschiff | Segel aus Wasser | Glasblau · fließender Rumpf | Schnell / Aufklärer | 9 · 9 · 10 | neu |
| P5 | **Dominion-Thron** | Thronschiff | 4 Masten | Obsidian, Gold, Abyssgrün · Thron am Achterdeck | Schwer / Belagerung | 10 · 10 · 8 | neu |

## NPC-Schiffe (Stufen 1–10)

Fraktionen: **Imperiale Flotte** (Blau/Gold, Lilie, Patrouillen, Konvoischutz); **Freibeuter** (Rot/Schwarz, Totenkopf, Raub, Überfälle); **Nordische Allianz** (Türkis/Weiß, Dreizack, Eismeer, Eisbrecher); **Schattenbund** (Violett/Schwarz, Steuerrad, Hinterhalte, Nebel); **Handelsliga** (Grün/Gold, Waage, Handelsrouten, Konvois).

| Stufe | Name | Typ | Fraktion | Verhalten | Quelle |
| --- | --- | --- | --- | --- | --- |
| 1 | Küstenkutter | Patrouillenboot | Handelsliga | passiv | NPC-Bogen 01 |
| 2 | Seewacht-Sloop | Patrouillenschiff | Imperiale Flotte | passiv | NPC-Bogen 02 |
| 2 | Seejäger-Sloop | Aufklärer | Freibeuter | passiv | NPC-Bogen B 02 |
| 3 | Handelskogge | Händler | Handelsliga | passiv, flieht | NPC-Bogen B 03 |
| 3 | Korsaren-Brig | leichtes Kriegsschiff | Freibeuter | neutral | NPC-Bogen 03 |
| 4 | Freibeuter-Galeasse | Ruderkriegsschiff | Freibeuter | neutral | NPC-Bogen 04 |
| 5 | Königliche Fregatte | schweres Kriegsschiff | Imperiale Flotte | neutral | NPC-Bogen 05 |
| 5 | Brigantine | ausgewogen | Schattenbund | neutral | NPC-Bogen B 05 |
| 6 | Schatten-Brigantine | schnelles Kriegsschiff | Schattenbund | aggressiv in Reichweite | NPC-Bogen 06 |
| 6 | Schneller Raider | Überfallschiff | Freibeuter | aggressiv in Reichweite | NPC-Bogen B 06 |
| 7 | Sturm-Kapitänschiff | Kriegsschiff | Nordische Allianz | aggressiv in Reichweite | NPC-Bogen 07 |
| 7 | Kanonen-Brig | leichtes Kriegsschiff | Imperiale Flotte | aggressiv in Reichweite | NPC-Bogen B 07 |
| 8 | Donner-Linienschiff | Linienschiff | Imperiale Flotte | aggressiv | NPC-Bogen 08 |
| 8 | Panzer-Fregatte | schweres Kriegsschiff | Nordische Allianz | aggressiv | NPC-Bogen B 08 |
| 9 | Verderbnis-Kriegsschiff | Elite-Kriegsschiff | Schattenbund | aggressiv, Spezialangriff | NPC-Bogen 09 |
| 9 | Feuer-Schnabel | Flammenwerfer | Freibeuter | aggressiv, Spezialangriff | NPC-Bogen B 09 |
| 10 | Admirals-Flaggschiff | Boss / Kommandoschiff | Imperiale Flotte | Boss | NPC-Bogen 10 |
| 10 | Königs-Barkasse | Elite-Patrouille | Imperiale Flotte | aggressiv ab niedriger Distanz | NPC-Bogen B 10 |

Stufe 1–3 greifen nicht an, 4–6 verteidigen sich, ab 7 aggressiv in Reichweite, Stufe 10 sind Bosse/Elite-Patrouillen.

## Events (Saison)

| Name | Anlass | Optik | Quelle |
| --- | --- | --- | --- |
| Kürbislaterne | Halloween | Kürbisgaleone mit Laternen, orange Glut | neu |
| Blutmond | Halloween | Rote Mondsegel, Nachtfarben | Bogen D-64 |
| Eiskrone | Winter | Eiszackenrumpf, Frostlicht | Bogen D-58 |
| Lichtbringer | Sommer / Sonnenwende | Weiß-Gold, Sonnenrad | Bogen D-63 |
| Korallenschlinge | Frühling / Meeresfest | Korallenbesatz, Türkis/Rosa | Bogen D-61 |
| Karminkrake | Krakenjagd-Event | Rote Krakensegel | Bogen D-54 |
| Purpursegel | Jubiläum | Purpur, Gold | Bogen D-59 |
| Dämmerwisp | Geisternacht | Magenta-Irrlichter | Bogen D-67 |
| Donnerschmiede | Schmiede-Event | Zahnradsegel, Glutöfen | Bogen D-62 |
| Neujahrsfunke | Neujahr | Feuerwerksgestelle, Silber/Blau | neu |

## PvP / Ehre

| Name | Anlass | Optik | Quelle |
| --- | --- | --- | --- |
| Ehrenklinge | Ranglisten-Saison | Silberne Klingenbug, Wappenbanner | neu |
| Triumphbogen | Turniersieger | Lorbeer, Gold | neu |

## Gilden

| Name | Anlass | Optik | Quelle |
| --- | --- | --- | --- |
| Gildenbastion | Gildenfestung erobert | Turmaufbau mit Gildenbanner (färbbar) | neu |
| Allianzbanner | Allianzkrieg | drei Flaggen, Wappenschilde | neu |

## Achievements / Exploration

| Name | Anlass | Optik | Quelle |
| --- | --- | --- | --- |
| Kartenzeichner | alle Regionen besucht | Sternkarten-Segel, Fernrohre | neu |
| Wrackschatz | 1000 Beutekisten | geflickte Segel, Goldladung | neu |

## Bosse / Admiräle (nicht spielbar)

| Name | Anlass | Optik | Quelle |
| --- | --- | --- | --- |
| Admirals-Flaggschiff | Kartenboss | siehe NPC 10 | NPC-Bogen 10 |
| Dominion-Erzräuber | Elite-Schlachtschiff | Gold/Schwarz, Kompassstern | NPC-&-Elite-Bogen 10 |
| Tiefenbeherrscher | Abyssal-Elite | Tentakel, Türkis | NPC-&-Elite-Bogen 09 |

## Kosmetische Farbreihen

| Name | Anlass | Optik | Quelle |
| --- | --- | --- | --- |
| Glutrumpf-Reihe 1–10 | Elite-Designvarianten | ein Rumpf, 10 Leuchtfarben | Farbbogen 1–10 |

## Hinweise zur Einordnung

- Der Elite-Bogen 01–10 ist als **Generation IV (31–40)** eingeordnet: Laut Masterkonzept bleiben die Klassen 1–10 bodenständig, die dunkle Stachel-/Geisteroptik würde die Eskalation zu früh verbrauchen. Wenn ihr die Elite-Schiffe trotzdem als Klassen 1–10 wollt, nur die Generationen I und IV tauschen.
- Die gotischen Variationsbögen (1–25) sind auf VIII–X verteilt; doppelte Motive (z. B. Knochenkiel 01/13) sind als eine Klasse mit Farbvarianten geführt.
- „Wraith Commander“ heißt hier **Schemenkommandant**, damit alle Namen deutsch sind.
- Zu klären: Pumpkin Reaper, Celestial Jade Dragon, Snow Queen's Wrath, Swamp King, Thunder Serpent, Verdant Spirit, Bone Collector, Dreamweaver, Solar Invictus, Ironclad Enforcer, Kraken's Fury (Bogen „ALL 10 GAME READY“): Herkunft und Rechte klären, erst dann einplanen.

## Sprite-Vorgabe für die Bildproduktion

Pro Schiff ein freigestelltes PNG-Atlasblatt (transparenter Hintergrund, keine Glows/Schatten über die Silhouette hinaus):
- feste erhöhte Spielkamera (ca. 50° von oben, schräg), dieselbe für alle Schiffe
- 8 Fahrtrichtungen: N, NE, E, SE, S, SW, W, NW (Bug zeigt jeweils in diese Richtung)
- 2 Zustände: intakt + beschädigt (zerrissene Segel); Versinken/Feuer/Rauch bleiben separate Effekte
- gleiche Vergrößerung und gleicher Wasserlinien-Ankerpunkt in allen Richtungen, ausreichend Abstand zwischen den Ansichten
- Glüh-/Effektebene (Nebel, Flammen, Blitze) als separates PNG, damit die Sprite-Kante sauber bleibt

Pro Klasse steht in `ship_catalog.json` unter `bildvorgabe` eine fertige Bildanweisung (englisch, weil Bildwerkzeuge damit zuverlässiger arbeiten).

## Produktionsreihenfolge

1. Starter S2, S3 und Generation I (Klassen 1–10) – bodenständig, normale Themen
2. NPC Stufen 1–10 (aus den vorhandenen NPC-Bögen freistellen bzw. in 8 Richtungen erzeugen)
3. Generation II–III (Mid), dann IV–VI
4. Generation VII–X (High/End), Prestige
5. Event-, PvP-, Gilden- und Achievement-Pools parallel nach Kalender
