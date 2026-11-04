from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
layout=(ROOT/'scripts/ui/nautical_layout.gd').read_text()
hud=(ROOT/'scripts/ui/nautical_hud.gd').read_text()
input_gd=(ROOT/'scripts/gameplay/player_input.gd').read_text()
assert '"nav_map"' in layout and '"world"' in layout and '"group"' in layout
assert 'var fire_radius := (50.0 if compact else 68.0) * sx' in layout
assert 'var wheel := Rect2' in layout
assert '"KARTE"' in hud and '"WERFT"' in hud and '"MENÜ"' in hud
assert 'for id in ["world", "group"]' in hud
assert '"group", "achievements", "events"' in input_gd and 'hud.open_menu(action)' in input_gd
print('M22 visual-master HUD contract: PASS')
