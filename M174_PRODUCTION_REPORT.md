# M174 Production Report

Status: `M174_MENU_PANEL_SELECTION_TRANSACTION_HARDENING_VERIFIED`

## Scope
- Masterkonzept V3.8 beibehalten; keine Änderung an Seekarte/Kamera.
- Hafenmarkt zeigt vor Soft-Currency-Käufen konkrete Voraussetzungen und deaktiviert unmögliche Aktionen.
- Reparatur und Versorgung besitzen gemeinsame Runtime-Statusresolver statt UI-Sonderlogik.
- Schiffswerft markiert die aktuelle Auswahl explizit und behält Ownership/Preview/Statvergleich.
- M174 Panel-/Selection-/Transaction-Verträge + Admin-Contenttypen ergänzt.

## Security
Payment/Entitlements sowie kritische Guild/Admin-Mutationen bleiben serverautoritativ.

## QA
Siehe `tests/m174_menu_panel_hardening_test.py`. Kein Godot-/Android-Device-Playtest in dieser Umgebung.
