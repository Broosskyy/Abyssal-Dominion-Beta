# Small Starter mit acht intakten und acht beschädigten Ansichten

M3056 / 0.305.6-test.1 / Android 305601. Asset-ID SHIP-STARTER-001, Auswahl Küstenschaluppe, gespeicherter Index 26.

## Verhalten

Der vorhandene intakte Satz bleibt unverändert. Ein daraus bearbeiteter zweiter Satz zeigt beschädigte Segel in derselben Richtungsreihenfolge N, NE, E, SE, S, SW, W, NW. Bei mehr als 35 Prozent HP erscheint intakte Besegelung, bei höchstens 35 Prozent und positiven HP die beschädigte Besegelung. Reparatur kann diese Schwelle in beide Richtungen überqueren; die Auswahl wird aus aktuellen HP ermittelt und nicht als separater veralteter Zustand gespeichert. Die 35-Prozent-Grenze ist ein lokaler Testwert, keine endgültige Balancingfestlegung.

Bei HP <= 0 wird der schwimmende Akteur nicht mehr gezeichnet; der vorhandene Versenkungseffekt bleibt zuständig. Beschädigung, vollständige Zerstörung und Reparatur werden also getrennt behandelt. Es wurden keine acht vollständigen Wrack- oder Sinkanimationen erstellt.

## Grafiken und Ausrichtung

- Intakt: assets/generated/ships/starter_small_8_intact.png, unveränderte SHA-256 b2a7ca2a680b4fa9949743c1080295da7e9d9ac1251ba45349252ee41077230c.
- Beschädigt: assets/generated/ships/starter_small_8_damaged.png, SHA-256 c09a1c0680620e74e68f4484a5fc1d3c044be8dca6492e72940f3c31085a099e.
- Beide Dateien: 1774 × 887, RGBA mit echter Transparenz.
- Erstellung durch integrierte Bildbearbeitung aus dem bereits verwendeten intakten Satz.
- Beide verwenden dieselbe Vergrößerung. Ausschnitte des beschädigten Satzes sind geringfügig erweitert, ohne die Wasserlinienposition zu verschieben.
- Rumpfregistrierung vergleicht deckende Pixel im unteren Bereich der intakten Ausschnitte über Verschiebungen von +/-7 Quellpixeln. Der beste Treffer liegt bei sechs Richtungen bei 0/0, bei NE und SE bei -1/0. Diese Verschiebung wird über den jeweiligen beschädigten Anker kompensiert. Bei aktueller Darstellungsgröße entspricht ein Quellpixel etwa 0,38 Weltpixeln.
- Details der Messung stehen in hull_alignment.json. Die Methode schätzt Translation; sie beweist keine vollständige geometrische oder pixelgenaue Identität. Geringe Textur- und Detailabweichungen der generierten Bearbeitung bleiben möglich.

## Prüfung

Geometrie-/Richtungstests prüfen alle 16 Frames, feste Vergrößerung, Quellgrenzen und gepaarte Anker. Zustandsregressionen prüfen volle HP, die 35-Prozent-Grenze, 1 HP, 0/negative HP, ausgebauten Maximalrumpf und ungültiges Maximum. Der UI-Test prüft die tatsächlich verwendeten Texture2D-Ressourcen bei intakt → beschädigt → repariert.

Die CI erfasst Galerie 3 intakt und Galerie 4 beschädigt mit dem echten sea_map-Renderer. Der zusätzliche damage-Aufnahmelauf zeichnet wiederholt 100% → 25% → 100% → 25% HP bei derselben Position und Ausrichtung auf. Er wird als health_state_change.mp4 gespeichert. Automatische Checks und Aufnahmen ersetzen keinen physischen Android-Gerätetest. Das aktive Spiel bleibt lokales Gastspiel.

## Prompt

```text
Use case: precise-object-edit / damaged game sprite state.
EDIT THE PROVIDED EXACT SPRITE ATLAS. This is the existing intact Small Starter SHIP-STARTER-001 in eight headings. Produce its MATCHING DAMAGED SAIL STATE. This is not a new ship and not a redesign.
Keep the exact same canvas 1774 x 887 pixels, same eight sprite positions, same scale, same waterline anchors, same camera, and same reading order N NE E SE / S SW W NW. Preserve the wood hulls, bow, bowsprit, stern, deck, locker, ropes, mast positions, boom and gaff geometry IDENTICALLY. Do not move, stretch, rotate, repaint or resize the ship silhouettes.
CHANGE ONLY THE CREAM SAIL FABRIC and the little pennant to look battle-damaged. Remove roughly a quarter of the mainsail fabric in a few clear irregular tears and ragged lower edges, add two moderate holes in the central mainsail, and one smaller tear in the jib. Slight dark scorching/dirt around the tears, but keep the remaining canvas recognizable and readable. Rigging and all structural spars remain intact and in precisely the same places. The damage is the same physical damage seen from the eight existing viewpoints, not randomly different ship constructions. When sails are edge-on, respect their foreshortening instead of twisting them toward the camera.
The vessel is STILL AFLOAT AND FUNCTIONAL, with all masts upright and the entire wooden hull unchanged. No sinking or wreckage. No flames, smoke, explosions, water, foam, shadows, extra objects, new weapons, labels, borders, UI or background. Real transparent alpha outside the ships, preserve transparency. No checkerboard pattern painted into the image.
Most important invariant: switching between original and edited frame in game must NOT make the hull or mast jump, change length, or change shape. This is a conservative sail-damage edit of the same eight images, not eight newly generated boats.
```

## Verifizierter Stand

CI-Lauf https://github.com/Broosskyy/Abyssal-Dominion-Beta/actions/runs/41634960002 erfolgreich. Source-Commit a24c7f8dce6375b9368f6bf2da3c5e7a4de55e21. APK 39250536 Bytes, SHA-256 de090d506da3d31d9964b09626baac5bc4d9322446ca9b6a46d85995c8376e08, Version 0.305.6-test.1 / 305601. Signatur, ARM64 und 16-KB-Ausrichtung geprüft.

1035 automatische Prüfungen bestanden: Simulation 22, Progression 63, Schiffsgeometrie/Zustände 767, UI 183. 62 PNGs sind per SHA-256 auditiert; die Messdaten enthalten 28 Quellgrafiken und 90 Frames einschließlich der bestehenden Originale.

Die Laufzeitgalerie mit allen acht beschädigten Richtungen wurde angesehen. Aus der tatsächlichen Zustandswechsel-Aufnahme wurden Frames bei 100%, 25% und erneut 100% HP geprüft: beschädigte Segel erscheinen nur im niedrigen positiven HP-Zustand und verschwinden nach Wiederherstellung; der Rumpf bleibt am gemeinsamen Bezugspunkt. Der Aufnahmelauf setzt HP für den kontrollierten Vergleich direkt und ist kein physischer Android-Reparaturbutton-Test.

Quellcode, zusätzliche Grafik, APK und Aufnahmen sind im Repository gesichert. Physischer Android-Test weiterhin nicht durchgeführt. Der Satz betrifft die Küstenschaluppe; andere Schiffsdesigns erhalten dadurch keine zusätzlichen beschädigten Ansichten.
