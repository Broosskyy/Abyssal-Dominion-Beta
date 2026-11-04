#!/usr/bin/env python3
"""Single source for Abyssal Dominion's ship progression map.

Writes docs/design/SHIP_PROGRESSION_MAP.md (readable map) and
docs/design/ship_catalog.json (machine-readable catalog for the game and
for art production). Edit the data here, then run:
    python3 rebuild/m3052/tools/ship_roster.py

Source column: "Bogen D-xx" / "Bogen Elite xx" / "Variation xx" / "Pack"
refers to the team's existing Abyssal Dominion concept sheets; "neu" marks
designs added in this map. Stats are 1-10 bars (Rumpf, Schaden, Tempo).
"""
import json
from pathlib import Path

REPO = Path(__file__).resolve().parents[3]

# role keys -> label, stat bias (hull, damage, speed)
ROLES = {
    'schnell': ('Schnell / Aufklärer', (-1, -1, 2)),
    'ausgewogen': ('Ausgewogen', (0, 0, 0)),
    'tank': ('Defensiv / Tank', (2, -1, -1)),
    'angriff': ('Angriff', (-1, 2, 0)),
    'kanone': ('Kanonenspezialist', (0, 2, -1)),
    'entern': ('Entern / Nahkampf', (1, 1, -1)),
    'support': ('Taktik / Support', (1, -1, 0)),
    'feuer': ('Feuer / Schaden über Zeit', (-1, 2, 0)),
    'schwer': ('Schwer / Belagerung', (2, 1, -2)),
}

GENERATIONS = [
    dict(id='S', title='Starter', classes='S1–S3', look='Normal, lesbar, charaktervoll; altes Holz, neutrale Segel, wenig Metall',
         limit='Keine Elite-Optik, keine Fantasy-Motive'),
    dict(id='I', title='Generation I · Küstenflotte', classes='1–10', look='Holz, Leinen, Messing; Kutter, Sloop, Kogge; 1–2 Masten; warme Naturtöne mit je einer Akzentfarbe',
         limit='Bodenständig, keine Glow-Effekte'),
    dict(id='II', title='Generation II · Handelsrouten', classes='11–20', look='Neue Rümpfe: Karavelle, Schoner, Brigg, Fleute; regionale Farbwelten (Mittelmeer-Terrakotta, Nordmeer-Klinkerblau, Tropen-Türkis)',
         limit='Erste Themen über Bemalung und Segelzeichen, noch realistisch'),
    dict(id='III', title='Generation III · Kriegsmarine', classes='21–30', look='Korvette, Fregatte, Galeasse; Kanonendecks, Ruderreihen, Metallbeschläge; Flaggen der Flotten',
         limit='Spürbar mächtiger, aber noch keine Magie'),
    dict(id='IV', title='Generation IV · Erste Elite', classes='31–40', look='Dunkles Eisen, Stachelbug, schwere Kanonen, einzelne Leuchtakzente (Elite-Bogen 01–10)',
         limit='Mehr Dominanz; Geistermotive nur dezent'),
    dict(id='V', title='Generation V · Ferne Kulturen', classes='41–50', look='Dschunke, Dau, Katamaran, Polar- und Wüstenschiffe, Elfen- und Kristallkaravellen',
         limit='Starke Identität über Kultur, nicht über Horror'),
    dict(id='VI', title='Generation VI · Außergewöhnliche Bauweisen', classes='51–60', look='Dampf, Panzerung, Zahnräder, Mischformen aus Tier und Schiff (Wal, Dünenläufer)',
         limit='Fantasy-Anteil steigt'),
    dict(id='VII', title='Generation VII · Legendäre Kriegsschiffe', classes='61–70', look='Prunkvolle Linienschiffe, Sonnen-, Mond- und Sturmorden; Gold, Silber, Gewitter',
         limit='Starke Formen und Materialien, noch keine Abyss-Motive'),
    dict(id='VIII', title='Generation VIII · Nebel und Tiefe', classes='71–80', look='Geister, Nebel, Biolumineszenz, Knochen, erste Tentakel',
         limit='Extreme Motive beginnen'),
    dict(id='IX', title='Generation IX · Verfluchte Spitzenklasse', classes='81–90', look='Käfige, Dämonen, Kraken, Höllenfeuer; starke Effekte und Silhouetten',
         limit='Sehr starke Effekte, aber klar lesbare Silhouette'),
    dict(id='X', title='Generation X · Abyssale Endstufe', classes='91–100', look='Lebende Schiffe, Leviathane, Leere und Sterne; ikonische Spitzenklassen',
         limit='Maximale reguläre Eskalation'),
    dict(id='P', title='Prestige', classes='P1–P5', look='Eigenständige Statuskategorie, je ein einzigartiges Leitmotiv', limit='Nicht Klasse 101–105'),
]

# (class, name, generation, hull/family, masts & sails, palette, motif, role, source)
C = [
    ('S1', 'Küstenschaluppe', 'S', 'Schaluppe (vorhanden, SHIP-STARTER-001)', '1 Mast, Gaffelsegel + Fock', 'altes Holz, Leinen', 'schlichte Bronzeakzente', 'ausgewogen', 'vorhanden im Spiel'),
    ('S2', 'Blauwasser-Kutter', 'S', 'Kutter, länger und breiter', '2 Masten, Gaffel + Toppsegel', 'gedämpftes Dunkelblau, helles Leinen', 'Anker auf dem Großsegel', 'schnell', 'neu (Masterkonzept Starter 02)'),
    ('S3', 'Grauer Wächter', 'S', 'kleine Brigg mit schwerem Rumpf', '2 Masten, Rahsegel', 'Grau/Schwarz, dunkles Holz, Eisen', 'genietete Bugplatte', 'tank', 'neu (Masterkonzept Starter 03)'),
    # Generation I
    (1, 'Möwenkutter', 'I', 'Kutter', '1 Mast, Gaffelsegel', 'Naturholz, Leinen, Weiß', 'Möwenwimpel', 'schnell', 'neu'),
    (2, 'Ankerlicht', 'I', 'Sloop', '1 Mast, Gaffel + Fock', 'Holz, Leinen, Messinglaterne', 'Laterne am Heck', 'ausgewogen', 'neu'),
    (3, 'Salzkogge', 'I', 'Kogge, hoher Freibord', '1 Mast, ein großes Rahsegel', 'Eiche, ungefärbtes Segel', 'Fässer an Deck', 'tank', 'neu'),
    (4, 'Brisenläufer', 'I', 'Sloop, schlank', '1 Mast, Gaffel + Toppsegel', 'helles Holz, Himmelblau', 'blauer Streifen am Rumpf', 'schnell', 'neu'),
    (5, 'Hafenkrähe', 'I', 'bewaffneter Kutter', '1 Mast, Gaffel', 'dunkles Holz, Schwarz', 'Krähenwimpel, 2 Drehbassen', 'angriff', 'neu'),
    (6, 'Leuchtturmsloop', 'I', 'Sloop', '1 Mast, Gaffel + 2 Vorsegel', 'Weiß/Rot geringelt', 'rot-weiße Bordwand', 'support', 'neu'),
    (7, 'Bernsteinkogge', 'I', 'Kogge mit Achterkastell', '1 Mast, Rahsegel + Besan', 'Honigholz, Bernsteingelb', 'gelbes Segel mit Sonnenring', 'ausgewogen', 'neu'),
    (8, 'Riffkutter', 'I', 'breiter Kutter', '2 Masten, Gaffel', 'Holz, Türkis', 'Korallenrot am Bug', 'entern', 'neu'),
    (9, 'Grünspan-Sloop', 'I', 'Sloop mit Kanonendeck', '2 Masten, Gaffel + Toppsegel', 'Holz, Kupfer/Grünspan', 'Kupferbeschlag am Bug', 'kanone', 'neu'),
    (10, 'Kapitänskogge', 'I', 'große Kogge, Vor- und Achterkastell', '2 Masten, Rahsegel', 'dunkles Holz, Weinrot, Messing', 'erstes Familienwappen', 'schwer', 'neu'),
    # Generation II
    (11, 'Terrakotta-Karavelle', 'II', 'Karavelle', '2 Masten, Lateinersegel', 'Terrakotta, Sand', 'Sonnenrad', 'schnell', 'neu'),
    (12, 'Nordklinker', 'II', 'Klinkerrumpf-Brigg', '2 Masten, Rahsegel', 'Klinkerblau, Weiß', 'Schneeflockenwimpel', 'tank', 'neu'),
    (13, 'Türkisschoner', 'II', 'Schoner', '2 Masten, Gaffel', 'Türkis, helles Holz', 'Muschelornament', 'schnell', 'neu'),
    (14, 'Gewürzfleute', 'II', 'Fleute, bauchiger Rumpf', '3 Masten, Rahsegel', 'Zimtbraun, Safrangelb', 'Gewürzsäcke an Deck', 'support', 'neu'),
    (15, 'Silbermöwe', 'II', 'Toppsegelschoner', '2 Masten', 'Silbergrau, Weiß', 'Möwenfigur am Bug', 'ausgewogen', 'neu'),
    (16, 'Lagunenbrigg', 'II', 'Brigg', '2 Masten, Rahsegel', 'Lagunengrün, Elfenbein', 'Wellenband', 'kanone', 'neu'),
    (17, 'Marktkaravelle', 'II', 'Karavelle mit Achterdeck', '3 Masten, Rah + Lateiner', 'Purpur, Gold', 'Gildenbanner der Handelsliga', 'support', 'neu'),
    (18, 'Frostfleute', 'II', 'Fleute, verstärkter Bug', '3 Masten', 'Eisblau, Grau', 'Eisbrecherkeil (dezent)', 'tank', 'neu'),
    (19, 'Korsarenschoner', 'II', 'schneller Schoner', '2 Masten, Gaffel + Rah', 'Schwarz/Rot', 'gekreuzte Säbel', 'angriff', 'neu'),
    (20, 'Seidenstraßen-Brigg', 'II', 'große Brigg', '2 Masten + Klüver', 'Jade, Rotlack', 'Laternenreihe', 'ausgewogen', 'neu'),
    # Generation III
    (21, 'Kanonenfalke', 'III', 'Korvette', '3 Masten', 'Marineblau, Weiß', 'Falkenwappen', 'kanone', 'neu'),
    (22, 'Remora-Galeasse', 'III', 'Galeasse mit Ruderreihe', '2 Masten, Lateiner', 'Rot, Bronze', 'Ramme am Bug', 'entern', 'neu (Idee aus NPC-Bogen Galeasse)'),
    (23, 'Eisenmöwe', 'III', 'leichte Fregatte', '3 Masten', 'Grau, Eisen', 'genietete Bordwand', 'tank', 'neu'),
    (24, 'Brandungsbrecher', 'III', 'Korvette, niedriger Rumpf', '2 Masten, Rah', 'Sturmgrau, Weiß', 'Wellenbug', 'schnell', 'neu'),
    (25, 'Kronenkorvette', 'III', 'Korvette mit Prunkheck', '3 Masten', 'Königsblau, Gold', 'Lilie/Krone (eigene Form)', 'ausgewogen', 'neu'),
    (26, 'Salvenbrigg', 'III', 'Kanonenbrigg, 2 Decks', '2 Masten', 'Ochsenblut, Schwarz', 'doppelte Kanonenreihe', 'kanone', 'neu (Idee aus NPC-Bogen Kanonen-Brig)'),
    (27, 'Riffjäger', 'III', 'Fregatte, schlank', '3 Masten', 'Seegrün, Messing', 'Haizahnreihe am Bug', 'angriff', 'neu'),
    (28, 'Mörserkogge', 'III', 'Bombardierkogge', '2 Masten', 'Ruß, Bronze', 'Mörser mittschiffs', 'schwer', 'neu'),
    (29, 'Wachfregatte', 'III', 'Fregatte', '3 Masten', 'Weiß, Ankerblau', 'Ankerwappen (Wache)', 'tank', 'neu'),
    (30, 'Admiralitätsfregatte', 'III', 'schwere Fregatte', '3 Masten + Klüver', 'Dunkelblau, Gold', 'Flaggenreihe, Galionsfigur', 'ausgewogen', 'neu'),
    # Generation IV: existing Elite sheet 01-10
    (31, 'Sturmwind', 'IV', 'schnelles Eliteschiff', '3 Masten', 'Schwarz, Messing', 'Kompassrose', 'schnell', 'Bogen Elite 01'),
    (32, 'Seelenreißer', 'IV', 'ausgewogenes Eliteschiff', '3 Masten', 'Nachtblau, Gold', 'Sternrad', 'ausgewogen', 'Bogen Elite 02'),
    (33, 'Eisenwächter', 'IV', 'Panzerschiff', '3 Masten', 'Eisengrau', 'Plattenpanzer', 'tank', 'Bogen Elite 03'),
    (34, 'Wilderzahn', 'IV', 'Angriffsschiff', '3 Masten', 'Schwarz, Blutrot', 'Zahnbug', 'angriff', 'Bogen Elite 04'),
    (35, 'Geisterkorsar', 'IV', 'listiges Eliteschiff', '3 Masten', 'Schwarz, Giftgrün', 'grüne Laternen (dezent)', 'support', 'Bogen Elite 05'),
    (36, 'Donnerklaue', 'IV', 'Kanonenschiff', '3 Masten', 'Bronze, Ocker', 'Kanonenbatterie', 'kanone', 'Bogen Elite 06'),
    (37, 'Tiefenfurie', 'IV', 'Spezialist für Entern', '3 Masten', 'Violett, Schwarz', 'Enterhaken', 'entern', 'Bogen Elite 07'),
    (38, 'Schattenwind', 'IV', 'Aufklärer', '3 Masten', 'Petrol, Schwarz', 'Sternenkarte', 'schnell', 'Bogen Elite 08'),
    (39, 'Flammenbanner', 'IV', 'Feuerschiff', '3 Masten', 'Glutorange, Schwarz', 'Feuerbanner', 'feuer', 'Bogen Elite 09'),
    (40, 'Sturmbasilisk', 'IV', 'schweres Eliteschiff', '3 Masten', 'Grau, Knochenweiß', 'Basiliskenkopf', 'schwer', 'Bogen Elite 10'),
    # Generation V
    (41, 'Jade-Dschunke', 'V', 'Dschunke, Lattensegel', '3 Masten', 'Jade, Gold', 'Drachenornamente', 'ausgewogen', 'Bogen D-41'),
    (42, 'Wüsten-Skimmer', 'V', 'Wüstennomaden-Schiff', '2 Masten, Lateiner', 'Sand, Ocker', 'Sonnenzeichen', 'schnell', 'Bogen D-42'),
    (43, 'Wüsten-Dahow', 'V', 'Dau', '2 Masten, Lateiner', 'Sandbeige, Rot', 'Sternsegel', 'support', 'Bogen D-12'),
    (44, 'Silberwind', 'V', 'Elfenschiff', '3 Masten, geschwungen', 'Silber, Nachtblau', 'Blattsegel', 'schnell', 'Bogen D-44'),
    (45, 'Luminara', 'V', 'Himmelspriester-Schiff mit Türmen', '2 Türme + Mast', 'Elfenbein, Himmelblau, Gold', 'Kuppeln', 'support', 'Bogen D-46'),
    (46, 'Kristallkaravelle', 'V', 'Gilden-Handelsschiff', '3 Masten', 'Rosé, Kristall, Gold', 'Kristallbesatz', 'tank', 'Bogen D-48'),
    (47, 'Monsunreiter', 'V', 'Auslegerboot (Proa) mit Krabbenscherensegel', '2 Masten', 'Tropenholz, Orange', 'Muschelketten', 'schnell', 'neu'),
    (48, 'Fjordwacht', 'V', 'nordisches Langschiff, Schildreihe', '1 Mast, Rahsegel + Ruder', 'Teer, Rot/Weiß gestreift', 'Schildreihe, Wolfskopf-Steven', 'entern', 'neu'),
    (49, 'Polarbrecher', 'V', 'Polarschiff der Nordstämme', '3 Masten', 'Eisblau, Weiß', 'Eiskeil', 'tank', 'Bogen D-51'),
    (50, 'Sonnenflamme', 'V', 'Phönix-Kult-Schiff', '3 Masten', 'Feuerrot, Gold', 'Phönix-Galionsfigur', 'feuer', 'Bogen D-50'),
    # Generation VI
    (51, 'Dampfsturm', 'VI', 'Dampfschiff (Imperiale Flotte)', 'Schlote statt Segel', 'Rost, Schwarz, Messing', 'drei Schornsteine', 'schwer', 'Bogen D-49'),
    (52, 'Blutkrallen-Katamaran', 'VI', 'Kriegskatamaran', '2 Rümpfe, 3 Masten', 'Schwarz, Rot', 'Krallenbug', 'angriff', 'Bogen D-45'),
    (53, 'Sturmwal', 'VI', 'Walrumpf-Mega-Schiff', '3 Masten', 'Nachtblau, Gewitterblau', 'Walkopf als Bug', 'tank', 'Pack 07'),
    (54, 'Dünenschreiter', 'VI', 'Wüstenkriegsschiff', '3 Masten', 'Sand, Bronze', 'Sandsturm-Effekt', 'ausgewogen', 'Pack 08'),
    (55, 'Mech-Panzerschiff', 'VI', 'gepanzertes Dampfschiff mit Rädern', 'Schlote', 'Bronze, Türkis-Lichter', 'Kanonenturm', 'schwer', 'Bogen D-15'),
    (56, 'Kupferkoloss', 'VI', 'Halbtaucher mit Kupferkuppel', '1 Hilfsmast', 'Kupfer, Grünspan', 'Bullaugen-Reihe', 'tank', 'neu'),
    (57, 'Windmühlenträger', 'VI', 'Rotorschiff', '2 Rotortürme', 'Holz, Ziegelrot', 'drehende Flügel', 'support', 'neu'),
    (58, 'Eisbrecher', 'VI', 'Fraktionsschiff', '3 Masten', 'Dunkelblau, Eis', 'Schneekristall-Segel', 'tank', 'Pack 09 / Bogen D-13'),
    (59, 'Raketenkogge', 'VI', 'Kogge mit Raketengestellen', '2 Masten', 'Schwarz, Signalgelb', 'Raketenbatterie', 'feuer', 'neu'),
    (60, 'Eisenhager', 'VI', 'Panzerschiff', '3 Masten', 'Eisen, Weiß', 'Plattenbug', 'schwer', 'Variation 14/15'),
    # Generation VII
    (61, 'Sonnenlanze', 'VII', 'Heiliger-Orden-Schiff', '3 Masten', 'Weiß, Gold', 'Sonnenrad', 'ausgewogen', 'Pack 04 / Bogen D-17'),
    (62, 'Sternenwind', 'VII', 'schnelles Spielerschiff', '2 Masten', 'Silber, Weiß, Blitzblau', 'Kompassstern', 'schnell', 'Pack 02'),
    (63, 'Sturmjäger', 'VII', 'Sturmschiff', '3 Masten', 'Schwarz, Blitzblau', 'Blitzadern', 'angriff', 'Variation 05'),
    (64, 'Mondlichtjäger', 'VII', 'Nachtjäger', '3 Masten', 'Mitternachtsblau, Silber', 'Mondsichel', 'schnell', 'Variation 21'),
    (65, 'Kapitänsflagge', 'VII', 'Admiralsschiff', '3 Masten', 'Schwarz, Gold', 'Kapitänswappen', 'support', 'Variation 10'),
    (66, 'Stahlpanzer', 'VII', 'Panzerlinienschiff', '3 Masten', 'Stahl, Schwarz', 'Panzerplatten', 'tank', 'Variation 23'),
    (67, 'Sonnenfluch', 'VII', 'Prunkgaleone', '2 Masten', 'Weiß, Gold, Bronze', 'Sonnensegel', 'kanone', 'Variation 20'),
    (68, 'Goldener Wächter', 'VII', 'Prunklinienschiff', '3 Masten', 'Gold, Elfenbein', 'Löwenbug', 'tank', 'neu'),
    (69, 'Gewitterkrone', 'VII', 'Linienschiff mit Blitzableitern', '3 Masten', 'Schiefer, Blitzweiß', 'Kupferspitzen auf den Masten', 'kanone', 'neu'),
    (70, 'Dunkelsegler', 'VII', 'schweres Kriegsschiff', '3 Masten', 'Schwarz, Grau', 'schwarzes Wappen', 'angriff', 'Variation 15'),
    # Generation VIII
    (71, 'Schattenklaue', 'VIII', 'kleines Geisterschiff', '1 Mast', 'Schwarz, Giftgrün', 'Totenkopf, grüner Nebel', 'schnell', 'Pack 01'),
    (72, 'Nebelreiter', 'VIII', 'Phantomschiff', '3 Masten', 'Grau, Geistertürkis', 'Nebelschleier', 'support', 'Pack 06 / Variation 09'),
    (73, 'Tiefenangler', 'VIII', 'Meereskreatur-Jäger', '2 Masten', 'Dunkelblau, Leuchtgrün', 'Angler-Laterne am Bug', 'angriff', 'Bogen D-43'),
    (74, 'Nebelwanderer', 'VIII', 'Nebelpiraten-Schiff', '3 Masten', 'Schwarz, Violett', 'Violette Laternen', 'schnell', 'Bogen D-47'),
    (75, 'Schattenwisp', 'VIII', 'Irrlicht-Schiff', '3 Masten', 'Nachtblau, Irrlichtblau', 'blaue Flammen', 'support', 'Bogen D-18'),
    (76, 'Geisterflamme', 'VIII', 'verfluchtes Schiff', '3 Masten', 'Schwarz, Geistergrün', 'grüne Flammen', 'feuer', 'Variation 04'),
    (77, 'Knochenkiel', 'VIII', 'Knochenschiff', '1–3 Masten', 'Knochenweiß, Schwarz', 'Rippenrumpf', 'tank', 'Variation 01/13'),
    (78, 'Sirenenzorn', 'VIII', 'Sirenen-Schiff', '3 Masten', 'Tiefblau, Perlmutt', 'Sirenen-Galionsfigur', 'support', 'Variation 08/18'),
    (79, 'Grabesstille', 'VIII', 'Gruftschiff', '3 Masten', 'Schwarz, Violett', 'Grabsteinreihe', 'tank', 'Variation 14/24'),
    (80, 'Tiefenzorn', 'VIII', 'Krakenschiff', '3 Masten', 'Schwarz, Violett', 'erste Tentakel', 'entern', 'Variation 03/07'),
    # Generation IX
    (81, 'Seelenkäfig', 'IX', 'Käfigschiff', '2 Masten + Käfig', 'Schwarz, Seelengrün', 'gefangene Seele', 'support', 'Bogen D-11 / Variation 06'),
    (82, 'Blutkrake', 'IX', 'Krakenschiff', '3 Masten', 'Schwarz, Blutrot', 'Krakensegel', 'entern', 'Variation 13'),
    (83, 'Fluchbringer', 'IX', 'Fluchschiff', '3 Masten', 'Schwarz, Giftgrün', 'Runenzeichen', 'feuer', 'Variation 17/20'),
    (84, 'Schemenkommandant', 'IX', 'Geister-Flaggschiff', '3 Masten', 'Schwarz, Violett', 'Geisterkapitän', 'ausgewogen', 'Variation 16/17 (dt. Name statt Wraith Commander)'),
    (85, 'Todeswind', 'IX', 'Sturmgeisterschiff', '3 Masten', 'Schwarz, Violettnebel', 'zerrissene Segel', 'schnell', 'Variation 12/22'),
    (86, 'Verdammnis', 'IX', 'Höllenschiff', '3 Masten', 'Schwarz, Glutrot', 'Rissmuster', 'angriff', 'Variation 09/11'),
    (87, 'Dämonenkiel', 'IX', 'Dämonenschiff', '3 Masten', 'Schwarz, Rot', 'Hörner am Bug', 'angriff', 'Variation 18/22'),
    (88, 'Dämonen-Katamaran', 'IX', 'Doppelrumpf-Dämon', '3 Masten', 'Schwarz, Violett', 'Stachelrümpfe', 'schnell', 'Bogen D-14'),
    (89, 'Krakenruf', 'IX', 'Event-/Krakenschiff', '3 Masten', 'Schwarz, Violettlicht', 'umschlingende Tentakel', 'tank', 'Pack 03'),
    (90, 'Höllenfeuer', 'IX', 'Boss-Optik als Klasse', '3 Masten', 'Schwarz, Lava', 'Drachenbug, Feuer', 'feuer', 'Pack 05'),
    # Generation X
    (91, 'Chaosbringer', 'X', 'Chaos-Galeone', '3 Masten', 'Schwarz, Rot', 'Chaosstern', 'angriff', 'Variation 16/25'),
    (92, 'Goldene Verderbnis', 'X', 'verfluchte Schatzgaleone', '3 Masten', 'Schwarzgold', 'Goldschädel', 'kanone', 'Variation 12/19'),
    (93, 'Abyssal Schattentiefe', 'X', 'Tiefseeschiff', '3 Masten', 'Schwarz, Tiefseetürkis', 'Leuchtorgane', 'ausgewogen', 'Variation 07/21'),
    (94, 'Leviathan', 'X', 'Schiff mit Maulsegel', '3 Masten', 'Schwarz, Knochen', 'Zahnmaul im Segel', 'schwer', 'Variation 08/24'),
    (95, 'Voidreiter', 'X', 'Sternenfahrer', 'geschwungene Klingensegel', 'Schwarzviolett, Leerenlicht', 'Leerenauge', 'schnell', 'Bogen D-52'),
    (96, 'Abyssal-Leviathan', 'X', 'lebendes Monsterschiff', '3 Masten auf Kreaturenrücken', 'Schwarz, Abyssgrün', 'Kreaturenkopf mit Tentakeln', 'schwer', 'Pack 10 / Bogen D-16'),
    (97, 'Abgrundkrone', 'X', 'Korallen-Abyss-Galeone', '3 Masten', 'Tiefschwarz, Perlweiß', 'Krone aus Korallenzacken', 'tank', 'neu'),
    (98, 'Weltenschlund', 'X', 'Strudelschiff', '2 Masten um Strudelkern', 'Nachtblau, Strudelweiß', 'rotierender Wirbel im Rumpf', 'support', 'neu'),
    (99, 'Sternenbrecher', 'X', 'Meteorgaleone', '3 Masten', 'Basalt, Glut, Sternenweiß', 'Meteoritenbug', 'kanone', 'neu'),
    (100, 'Abyssal Dominion', 'X', 'Flaggschiff der Tiefe', '4 Masten', 'Schwarz, Gold, Abyssgrün', 'Dominion-Wappen', 'schwer', 'neu'),
    # Prestige
    ('P1', 'Ozeanherz', 'P', 'Perlmutt-Galeone', '3 Masten', 'Perlmutt, Türkis', 'pulsierendes Herz im Heck', 'support', 'neu'),
    ('P2', 'Aschenphönix', 'P', 'brennende Galeone, die nie verbrennt', '3 Masten', 'Asche, Glut', 'Phönixflügel als Segel', 'feuer', 'neu'),
    ('P3', 'Sonnenfinsternis', 'P', 'Schwarzgold-Linienschiff', '3 Masten', 'Schwarz, Korona-Gold', 'verdeckte Sonne', 'angriff', 'neu'),
    ('P4', 'Ewige Flut', 'P', 'Wasser-Elementarschiff', 'Segel aus Wasser', 'Glasblau', 'fließender Rumpf', 'schnell', 'neu'),
    ('P5', 'Dominion-Thron', 'P', 'Thronschiff', '4 Masten', 'Obsidian, Gold, Abyssgrün', 'Thron am Achterdeck', 'schwer', 'neu'),
]

NPC_FACTIONS = [
    ('Imperiale Flotte', 'Blau/Gold, Lilie', 'Patrouillen, Konvoischutz'),
    ('Freibeuter', 'Rot/Schwarz, Totenkopf', 'Raub, Überfälle'),
    ('Nordische Allianz', 'Türkis/Weiß, Dreizack', 'Eismeer, Eisbrecher'),
    ('Schattenbund', 'Violett/Schwarz, Steuerrad', 'Hinterhalte, Nebel'),
    ('Handelsliga', 'Grün/Gold, Waage', 'Handelsrouten, Konvois'),
]

NPC = [
    # level, name, type, faction, behaviour, source
    (1, 'Küstenkutter', 'Patrouillenboot', 'Handelsliga', 'passiv', 'NPC-Bogen 01'),
    (2, 'Seewacht-Sloop', 'Patrouillenschiff', 'Imperiale Flotte', 'passiv', 'NPC-Bogen 02'),
    (2, 'Seejäger-Sloop', 'Aufklärer', 'Freibeuter', 'passiv', 'NPC-Bogen B 02'),
    (3, 'Handelskogge', 'Händler', 'Handelsliga', 'passiv, flieht', 'NPC-Bogen B 03'),
    (3, 'Korsaren-Brig', 'leichtes Kriegsschiff', 'Freibeuter', 'neutral', 'NPC-Bogen 03'),
    (4, 'Freibeuter-Galeasse', 'Ruderkriegsschiff', 'Freibeuter', 'neutral', 'NPC-Bogen 04'),
    (5, 'Königliche Fregatte', 'schweres Kriegsschiff', 'Imperiale Flotte', 'neutral', 'NPC-Bogen 05'),
    (5, 'Brigantine', 'ausgewogen', 'Schattenbund', 'neutral', 'NPC-Bogen B 05'),
    (6, 'Schatten-Brigantine', 'schnelles Kriegsschiff', 'Schattenbund', 'aggressiv in Reichweite', 'NPC-Bogen 06'),
    (6, 'Schneller Raider', 'Überfallschiff', 'Freibeuter', 'aggressiv in Reichweite', 'NPC-Bogen B 06'),
    (7, 'Sturm-Kapitänschiff', 'Kriegsschiff', 'Nordische Allianz', 'aggressiv in Reichweite', 'NPC-Bogen 07'),
    (7, 'Kanonen-Brig', 'leichtes Kriegsschiff', 'Imperiale Flotte', 'aggressiv in Reichweite', 'NPC-Bogen B 07'),
    (8, 'Donner-Linienschiff', 'Linienschiff', 'Imperiale Flotte', 'aggressiv', 'NPC-Bogen 08'),
    (8, 'Panzer-Fregatte', 'schweres Kriegsschiff', 'Nordische Allianz', 'aggressiv', 'NPC-Bogen B 08'),
    (9, 'Verderbnis-Kriegsschiff', 'Elite-Kriegsschiff', 'Schattenbund', 'aggressiv, Spezialangriff', 'NPC-Bogen 09'),
    (9, 'Feuer-Schnabel', 'Flammenwerfer', 'Freibeuter', 'aggressiv, Spezialangriff', 'NPC-Bogen B 09'),
    (10, 'Admirals-Flaggschiff', 'Boss / Kommandoschiff', 'Imperiale Flotte', 'Boss', 'NPC-Bogen 10'),
    (10, 'Königs-Barkasse', 'Elite-Patrouille', 'Imperiale Flotte', 'aggressiv ab niedriger Distanz', 'NPC-Bogen B 10'),
]

POOLS = {
    'Events (Saison)': [
        ('Kürbislaterne', 'Halloween', 'Kürbisgaleone mit Laternen, orange Glut', 'neu'),
        ('Blutmond', 'Halloween', 'Rote Mondsegel, Nachtfarben', 'Bogen D-64'),
        ('Eiskrone', 'Winter', 'Eiszackenrumpf, Frostlicht', 'Bogen D-58'),
        ('Lichtbringer', 'Sommer / Sonnenwende', 'Weiß-Gold, Sonnenrad', 'Bogen D-63'),
        ('Korallenschlinge', 'Frühling / Meeresfest', 'Korallenbesatz, Türkis/Rosa', 'Bogen D-61'),
        ('Karminkrake', 'Krakenjagd-Event', 'Rote Krakensegel', 'Bogen D-54'),
        ('Purpursegel', 'Jubiläum', 'Purpur, Gold', 'Bogen D-59'),
        ('Dämmerwisp', 'Geisternacht', 'Magenta-Irrlichter', 'Bogen D-67'),
        ('Donnerschmiede', 'Schmiede-Event', 'Zahnradsegel, Glutöfen', 'Bogen D-62'),
        ('Neujahrsfunke', 'Neujahr', 'Feuerwerksgestelle, Silber/Blau', 'neu'),
    ],
    'PvP / Ehre': [('Ehrenklinge', 'Ranglisten-Saison', 'Silberne Klingenbug, Wappenbanner', 'neu'),
                   ('Triumphbogen', 'Turniersieger', 'Lorbeer, Gold', 'neu')],
    'Gilden': [('Gildenbastion', 'Gildenfestung erobert', 'Turmaufbau mit Gildenbanner (färbbar)', 'neu'),
               ('Allianzbanner', 'Allianzkrieg', 'drei Flaggen, Wappenschilde', 'neu')],
    'Achievements / Exploration': [('Kartenzeichner', 'alle Regionen besucht', 'Sternkarten-Segel, Fernrohre', 'neu'),
                                   ('Wrackschatz', '1000 Beutekisten', 'geflickte Segel, Goldladung', 'neu')],
    'Bosse / Admiräle (nicht spielbar)': [('Admirals-Flaggschiff', 'Kartenboss', 'siehe NPC 10', 'NPC-Bogen 10'),
                                          ('Dominion-Erzräuber', 'Elite-Schlachtschiff', 'Gold/Schwarz, Kompassstern', 'NPC-&-Elite-Bogen 10'),
                                          ('Tiefenbeherrscher', 'Abyssal-Elite', 'Tentakel, Türkis', 'NPC-&-Elite-Bogen 09')],
    'Kosmetische Farbreihen': [('Glutrumpf-Reihe 1–10', 'Elite-Designvarianten', 'ein Rumpf, 10 Leuchtfarben', 'Farbbogen 1–10')],
}

UNCLEAR = ['Pumpkin Reaper, Celestial Jade Dragon, Snow Queen\'s Wrath, Swamp King, Thunder Serpent, Verdant Spirit, Bone Collector, Dreamweaver, Solar Invictus, Ironclad Enforcer, Kraken\'s Fury (Bogen „ALL 10 GAME READY“): Herkunft und Rechte klären, erst dann einplanen.']

SPRITE_SPEC = """Pro Schiff ein freigestelltes PNG-Atlasblatt (transparenter Hintergrund, keine Glows/Schatten über die Silhouette hinaus):
- feste erhöhte Spielkamera (ca. 50° von oben, schräg), dieselbe für alle Schiffe
- 8 Fahrtrichtungen: N, NE, E, SE, S, SW, W, NW (Bug zeigt jeweils in diese Richtung)
- 2 Zustände: intakt + beschädigt (zerrissene Segel); Versinken/Feuer/Rauch bleiben separate Effekte
- gleiche Vergrößerung und gleicher Wasserlinien-Ankerpunkt in allen Richtungen, ausreichend Abstand zwischen den Ansichten
- Glüh-/Effektebene (Nebel, Flammen, Blitze) als separates PNG, damit die Sprite-Kante sauber bleibt"""

PROMPT = ("2D game sprite sheet of an original ship '{name}' for the pirate MMO Abyssal Dominion: {hull}, {masts}, colours {palette}, motif: {motif}. "
          "Fixed elevated three-quarter top-down game camera, 8 headings (N, NE, E, SE, S, SW, W, NW) in one row, second row identical with torn sails, "
          "transparent background, consistent scale and waterline, clean edges, no text, no glow outside the silhouette.")


def stats(gen_index, role):
    base = 1 + round(gen_index * 0.8)
    bias = ROLES[role][1]
    clamp = lambda v: max(1, min(10, v))
    return {'rumpf': clamp(base + bias[0]), 'schaden': clamp(base + bias[1]), 'tempo': clamp(base + bias[2])}


def main():
    gen_order = [g['id'] for g in GENERATIONS]
    ships = []
    for cls, name, gen, hull, masts, palette, motif, role, source in C:
        gi = gen_order.index(gen)
        ships.append(dict(klasse=str(cls), name=name, generation=gen, rumpf=hull, takelage=masts, farben=palette, motiv=motif,
                          rolle=ROLES[role][0], werte=stats(gi, role), quelle=source,
                          bildvorgabe=PROMPT.format(name=name, hull=hull, masts=masts, palette=palette, motif=motif)))
    catalog = dict(version=1, generationen=GENERATIONS, klassen=ships,
                   npc=[dict(stufe=l, name=n, typ=t, fraktion=f, verhalten=b, quelle=s) for l, n, t, f, b, s in NPC],
                   fraktionen=[dict(name=n, farben=c, rolle=r) for n, c, r in NPC_FACTIONS],
                   pools={k: [dict(name=n, anlass=a, optik=o, quelle=s) for n, a, o, s in v] for k, v in POOLS.items()},
                   zu_klaeren=UNCLEAR, sprite_vorgabe=SPRITE_SPEC)
    (REPO / 'docs/design/ship_catalog.json').write_text(json.dumps(catalog, indent=2, ensure_ascii=False) + '\n')

    bar = lambda v: '▮' * v + '▯' * (10 - v)
    md = ['# Abyssal Dominion · Master-Progressionskarte Schiffe', '',
          'Erzeugt aus `rebuild/m3052/tools/ship_roster.py` (dort bearbeiten, dann neu erzeugen). Grundlage: *Schiffsprogression-Masterkonzept* '
          '(3 Starter → 100 Klassen → Prestige P1–P5, getrennte Design-Pools) und die vorhandenen Abyssal-Dominion-Konzeptbögen. '
          'Vom Genre übernommen ist nur die Struktur (kleine Starter, schrittweise Steigerung, separate Event-/Boss-Pools), keine fremden Schiffe, Namen oder Optik.', '',
          f'Umfang: {len(C)} spielbare Klassen (davon {sum(1 for x in C if x[8].startswith("neu"))} neu entworfen), {len(NPC)} NPC-Typen, '
          f'{sum(len(v) for v in POOLS.values())} Spezial-/Event-Designs. Werte sind Startwerte (1–10) für das Balancing.', '',
          '## Generationen', '', '| Gen. | Klassen | Optik | Grenze |', '| --- | --- | --- | --- |']
    md += [f"| {g['title']} | {g['classes']} | {g['look']} | {g['limit']} |" for g in GENERATIONS]
    for g in GENERATIONS:
        md += ['', f"## {g['title']} ({g['classes']})", '', '| Kl. | Name | Rumpf | Takelage | Farben / Motiv | Rolle | Rumpf · Schaden · Tempo | Quelle |',
               '| --- | --- | --- | --- | --- | --- | --- | --- |']
        for s in ships:
            if s['generation'] != g['id']: continue
            w = s['werte']
            md.append(f"| {s['klasse']} | **{s['name']}** | {s['rumpf']} | {s['takelage']} | {s['farben']} · {s['motiv']} | {s['rolle']} | {w['rumpf']} · {w['schaden']} · {w['tempo']} | {s['quelle']} |")
    md += ['', '## NPC-Schiffe (Stufen 1–10)', '', 'Fraktionen: ' + '; '.join(f'**{n}** ({c}, {r})' for n, c, r in NPC_FACTIONS) + '.', '',
           '| Stufe | Name | Typ | Fraktion | Verhalten | Quelle |', '| --- | --- | --- | --- | --- | --- |']
    md += [f'| {l} | {n} | {t} | {f} | {b} | {s} |' for l, n, t, f, b, s in NPC]
    md += ['', 'Stufe 1–3 greifen nicht an, 4–6 verteidigen sich, ab 7 aggressiv in Reichweite, Stufe 10 sind Bosse/Elite-Patrouillen.']
    for k, v in POOLS.items():
        md += ['', f'## {k}', '', '| Name | Anlass | Optik | Quelle |', '| --- | --- | --- | --- |']
        md += [f'| {n} | {a} | {o} | {s} |' for n, a, o, s in v]
    md += ['', '## Hinweise zur Einordnung', '',
           '- Der Elite-Bogen 01–10 ist als **Generation IV (31–40)** eingeordnet: Laut Masterkonzept bleiben die Klassen 1–10 bodenständig, die dunkle Stachel-/Geisteroptik würde die Eskalation zu früh verbrauchen. Wenn ihr die Elite-Schiffe trotzdem als Klassen 1–10 wollt, nur die Generationen I und IV tauschen.',
           '- Die gotischen Variationsbögen (1–25) sind auf VIII–X verteilt; doppelte Motive (z. B. Knochenkiel 01/13) sind als eine Klasse mit Farbvarianten geführt.',
           '- „Wraith Commander“ heißt hier **Schemenkommandant**, damit alle Namen deutsch sind.',
           '- Zu klären: ' + ' '.join(UNCLEAR), '',
           '## Sprite-Vorgabe für die Bildproduktion', '', SPRITE_SPEC, '',
           'Pro Klasse steht in `ship_catalog.json` unter `bildvorgabe` eine fertige Bildanweisung (englisch, weil Bildwerkzeuge damit zuverlässiger arbeiten).',
           '', '## Produktionsreihenfolge', '',
           '1. Starter S2, S3 und Generation I (Klassen 1–10) – bodenständig, normale Themen',
           '2. NPC Stufen 1–10 (aus den vorhandenen NPC-Bögen freistellen bzw. in 8 Richtungen erzeugen)',
           '3. Generation II–III (Mid), dann IV–VI',
           '4. Generation VII–X (High/End), Prestige',
           '5. Event-, PvP-, Gilden- und Achievement-Pools parallel nach Kalender']
    (REPO / 'docs/design/SHIP_PROGRESSION_MAP.md').write_text('\n'.join(md) + '\n')
    print(json.dumps({'klassen': len(C), 'neu': sum(1 for x in C if x[8].startswith('neu')), 'npc': len(NPC), 'pools': sum(len(v) for v in POOLS.values())}))


if __name__ == '__main__':
    main()
