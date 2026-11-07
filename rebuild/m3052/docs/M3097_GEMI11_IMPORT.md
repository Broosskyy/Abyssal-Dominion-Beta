# M3097 — Gemi11 UV als separates zweites Testschiff

- Neue Skin-ID **30**: `TEST 2 · Gemi11 UV korrigiert` (Werft).
- Originales vom Nutzer bereitgestelltes GLB: `assets/player/test_ships/gemi11_uv.glb`.
- Original-SHA256: `e7b25db9b5db8573564441c8d942ceca166ab0b8aaa1f27796a75f882e78ac4b`.
- 3 Meshes, 1 eingebettetes Bild, 9.324 Dreiecke; Originalgeometrie und UVs bleiben unverändert.
- 8 Richtungsbilder im Atlas `gemi11_uv_eight.png` (2560 × 320) für Classic/2D.
- Einzelvorschau `gemi11_uv_preview.png` (640 × 640) für die Werft.
- 2,5D Hybrid / 3D: Vollständige GLB-Szene mit Größe 154, +Z-Bug und wasserlinienkompensierter Skalierung.
- Bisherige Skin-IDs 0–29 und die A/B/C-Varianten für Skin 29 bleiben erhalten.
- `tests/ui_test.gd` prüft Werft, importiertes GLB, 8er-Atlas, Speicherstände, Richtungen und Moduswechsel.

Das Modell ist ein Testschiff. Der endgültige optische Abgleich muss zusätzlich auf einem realen Android-Gerät erfolgen. Diese Änderung benötigt keinen neuen Android-Bootstrap, nur ein signiertes Datenupdate.

## Regressionscheck

Der anfänglich fehlgeschlagene M3097-Build prüfte noch einen fest codierten Werftkartenwert von 30. Die Werftkartenprüfung wurde auf die tatsächliche Anzahl der Designs umgestellt; der anschließende vollständige Godot-Datenbuild validiert die Änderung.
