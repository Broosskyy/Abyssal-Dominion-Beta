from pathlib import Path
R=Path(__file__).resolve().parents[1]
def read(p): return (R/p).read_text()
def test_m23_encounter_identity():
 s=read('scripts/world/encounter_director.gd'); assert 'NPC_TITLES' in s and 'combat_level' in s and 'rarity' in s
def test_m23_admiral_loot():
 s=read('scripts/world/encounter_director.gd'); assert 'admiral_chest' in s
 v=read('scripts/visual/loot_visual.gd'); assert 'admiral: bool = false' in v and 'scale_factor' in v
def test_m23_nameplates():
 s=read('scripts/ui/game_hud.gd'); assert 'Lv.%d' in s and '★ ' in s and '◆ ' in s
