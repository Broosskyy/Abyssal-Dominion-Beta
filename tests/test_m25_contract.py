from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
def text(path): return (ROOT/path).read_text(encoding='utf-8')
def test_m25_version_and_direction_lock():
    rel=json.loads(text('data/release_identity.json')); assert rel['build_number']>=25 and rel['master_concept']=='V3.8'
    assert 'renderer/rendering_method="gl_compatibility"' in text('project.godot')
def test_encounter_state_machine_and_leash():
    ai=text('scripts/gameplay/enemy_ship_ai.gd'); assert all(f'"{s}"' in ai for s in ['PATROL','PURSUE','ENGAGE','RETURN']); assert 'leash_range' in ai and 'spawn_anchor' in ai and '_drop_aggro' in ai and 'boss_phase' in ai
def test_elite_boss_monster_and_loot_tiers():
    data=json.loads(text('data/encounters.json')); assert 'leviathan' in data['archetypes'] and data['biomes']['tropical']['boss_kind']=='monster' and data['biomes']['tropical']['boss_archetype']=='leviathan' and set(data['loot_tiers'])=={'common','uncommon','rare','epic','legendary'}
    director=text('scripts/world/encounter_director.gd'); assert 'apply_sea_monster_visual' in director and '_roll_loot_tier' in director and 'legendary' in director and 'admiral_ship' in director
def test_monster_visual_and_tiered_loot_visuals():
    factory=text('scripts/core/procedural_factory.gd'); loot=text('scripts/visual/loot_visual.gd'); pickup=text('scripts/gameplay/loot_pickup.gd'); assert 'apply_sea_monster_visual' in factory and 'LeviathanBody' in factory and 'Tentacle' in factory and all(f'"{t}"' in loot for t in ['uncommon','rare','epic','legendary']) and 'loot_tier' in pickup
def test_m24_combat_depth_retained():
    assert 'effective_range' in text('scripts/gameplay/ship_weapons.gd') and 'target_range_state' in text('scripts/combat/targeting_system.gd') and 'recommended_ammo' in text('scripts/combat/combat_catalog.gd')
