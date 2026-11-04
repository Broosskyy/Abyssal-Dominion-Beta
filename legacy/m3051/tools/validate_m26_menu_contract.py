from pathlib import Path

root = Path(__file__).resolve().parents[1]
hud = (root / "scripts/ui/game_hud.gd").read_text()
nav = (root / "scripts/gameplay/player_input.gd").read_text()
paint = (root / "scripts/ui/nautical_hud.gd").read_text()
project = (root / "project.godot").read_text()
checks = {
    "version": 'config/version="0.26.0"' in project,
    "menu state": 'var menu_open := false' in hud and 'func open_menu(page: String)' in hud,
    "movement guard": 'hud != null and hud.menu_open' in nav,
    "nav routes": '"group", "achievements", "events", "quests", "shop", "guild", "chat", "rankings", "bonus", "home"' in nav,
    "responsive tabs": 'Mobile bottom tabs' in hud and 'var tabs := [["EVENTS", "events"]' in paint,
    "offline safe": 'keine fingierten Live-Spieler' in paint,
    "overlay paint": '_menu_overlay(hud, layout, player)' in paint,
}
failed = [name for name, ok in checks.items() if not ok]
for name, ok in checks.items():
    print(("PASS" if ok else "FAIL") + " — " + name)
if failed:
    raise SystemExit(1)
print(f"M26 contract: {len(checks)}/{len(checks)} PASS")
