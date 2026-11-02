# M206 — Decks, Harpunen & Schiffsausrüstung

M206 führt die M203–M205-Visual-Pipeline auf Decks, Spezialdecks, Harpunen und Schiffsausrüstung fort. Der Schwerpunkt ist die direkte Ablesbarkeit im Gameplay: normale Deckstufen bilden einen progressiven, visual-only Deckstapel **unter dem Schiff**. Das ausgerüstete Spezialdeck erhält darunter eine zusätzliche rollenabhängige Ebene; bestehende Spezialdeck-VFX bleiben erhalten.

Der neue UI-Pack umfasst 10 normale Deckstufen, 6 Spezialdeck-Familien, 5 Spezialdeck-Level-Badges, 4 Harpunen-Silhouetten und 6 Schiffsausrüstungs-Slots. Die Icons sind skalierbare SVG-Placeholder und verwenden eigenständige Formen statt reiner Recolors. Im Ausbauzentrum werden normale Decks, Spezialdecks und Harpunen über dieselben stabilen Visual-Slots dargestellt.

Keine Gameplay-Autorität wurde verschoben. Deckkapazität, Preise, Spezialdeck-Effekte, Harpunenschaden/-reichweite, Schiffskollision und Tap-to-Sail bleiben in ihren bestehenden Daten-/Runtime-Systemen. Die neuen Unter-Schiff-Geometrien tragen `visual_only`-Metadaten und besitzen keine Kollisionskörper.

Mobile, Web und Desktop verwenden dieselbe Deck-/Equipment-Darstellung. Responsive Unterschiede bleiben auf HUD-Skalierung, Schrift, Touchflächen, Abstände und Safe Areas begrenzt.
