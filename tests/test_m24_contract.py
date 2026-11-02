from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def read(rel): return (ROOT/rel).read_text(encoding='utf-8')

def test_catalog_has_modern_combat_profiles():
    s=read('scripts/combat/combat_catalog.gd')
    for token in ['"range"', '"crit"', '"role"', 'recommended_ammo']:
        assert token in s

def test_weapons_range_and_summary():
    s=read('scripts/gameplay/ship_weapons.gd')
    assert 'float(cannon.range)' in s and 'float(ammo.range)' in s
    assert 'combat_summary()' in s and 'target_distance_ratio()' in s
    assert 'critical_chance' in s

def test_enemy_ai_uses_tactical_range_and_ammo():
    s=read('scripts/gameplay/enemy_ship_ai.gd')
    assert '_tactical_loadout()' in s
    assert 'recommended_ammo' in s
    assert 'weapons.effective_range()' in s

def test_targeting_and_hud_range_feedback():
    t=read('scripts/combat/targeting_system.gd')
    h=read('scripts/ui/nautical_hud.gd')
    assert 'target_range_state' in t and 'nearest_hostile_in_range' in t
    assert 'OPTIMAL' in t and 'EDGE' in t and 'OUT' in t
    assert 'range_state' in h and 'weapons.ammo_name()' in h
