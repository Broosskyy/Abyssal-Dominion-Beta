from pathlib import Path
import json,re
ROOT=Path(__file__).resolve().parents[1]

def test_m192_contract_release_and_size():
    d=json.loads((ROOT/'data/m192_navigation_world_scale.json').read_text())
    rel=json.loads((ROOT/'data/release_identity.json').read_text())
    world=(ROOT/'scripts/world/world_map_system.gd').read_text()
    assert d['milestone']=='M192' and rel['build_number']>=192
    assert 'const SECTOR_SIZE := 360.0' in world
    assert 'func display_coordinates()' in world and 'func sector_spawn_extent()' in world

def test_visible_map_names_are_named_not_number_grid():
    registry=json.loads((ROOT/'data/world_sector_registry.json').read_text())
    assert len(registry['sectors'])>=50
    assert all(not re.match(r'^\d+[-/]\d+\b', str(r.get('display_name',''))) for r in registry['sectors'])
    assert all(str(r.get('id','')).startswith('SECTOR-') for r in registry['sectors'])

def test_land_blocks_units_do_not_block_each_other():
    src=(ROOT/'scripts/core/procedural_factory.gd').read_text()
    assert 'ship.collision_layer = 1' in src and 'ship.collision_mask = 4' in src
    assert 'island.collision_layer = 4' in src and 'island.collision_mask = 0' in src

def test_tap_navigation_uses_land_detour_without_unit_avoidance():
    src=(ROOT/'scripts/gameplay/player_input.gd').read_text()
    assert '_navigation_steering_point' in src and '_segment_circle_hit' in src
    assert 'get_nodes_in_group("islands")' in src
    helper=src[src.index('func _navigation_steering_point'):src.index('func _touch_hits_hud')]
    assert 'ships' not in helper and 'enemies' not in helper and 'monsters' not in helper
    assert 'stop_ship()' not in helper
    assert '0.72,1.0' in src

def test_hud_uses_positive_xy_chart_coordinates():
    hud=(ROOT/'scripts/ui/game_hud.gd').read_text()
    assert 'world.display_coordinates()' in hud
    assert 'X %03d / Y %03d' in hud
    assert 'X %.1f / Z %.1f' not in hud
