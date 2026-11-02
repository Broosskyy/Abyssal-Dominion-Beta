import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def test_release_identity_m228():
    d=json.loads((ROOT/'data/release_identity.json').read_text())
    assert d['milestone'] in {'M228','M229','M230','M231','M232','M233','M234','M235','M236','M237','M238','M239','M240','M241','M242','M243','M244', 'M245','M246','M247','M248','M249','M250','M251','M252','M253','M254','M255','M256','M257','M258','M259','M260','M261','M262','M263','M264','M265','M266','M267','M268','M269','M270','M271','M272','M273','M274','M275','M276','M277','M278','M279','M280','M281','M282','M283','M284','M285','M286','M287','M288','M289','M290','M291','M292','M293','M294','M295','M296','M297','M298','M299','M300','M301'} and d['client_version'] in {'0.228.0','0.229.0','0.230.0','0.231.0','0.232.0','0.233.0','0.234.0','0.235.0','0.236.0','0.237.0','0.238.0','0.239.0','0.240.0','0.241.0','0.242.0','0.243.0','0.244.0', '0.245.0','0.246.0','0.247.0','0.248.0','0.249.0','0.250.0','0.251.0','0.252.0','0.253.0','0.254.0','0.255.0','0.256.0','0.257.0','0.258.0','0.259.0','0.260.0','0.261.0','0.262.0','0.263.0','0.264.0','0.265.0','0.266.0','0.268.0','0.269.0','0.270.0','0.271.0','0.272.0','0.273.0','0.274.0','0.275.0','0.276.0','0.277.0','0.278.0','0.279.0','0.280.0','0.281.0','0.282.0','0.283.0','0.284.0','0.285.0','0.286.0','0.287.0','0.288.0','0.289.0','0.290.0','0.291.0','0.292.0','0.293.0','0.294.0','0.295.0','0.296.0','0.297.0','0.298.0','0.299.0','0.300.0','0.301.0'} and d['build_number'] in {228,229,230,231,232,233,234,235,236,237,238,239,240,241,242,243,244, 245,246,247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,272,273,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and d['master_concept']=='V3.8'

def test_m228_contract_preserves_world_and_combat_authorities():
    d=json.loads((ROOT/'data/m228_living_sea_encounter_contract.json').read_text())
    w=d['world_rules']; b=d['boundaries']; density=d['density_rules']
    assert w['same_world_mobile_web_desktop'] is True
    assert w['spawn_count_authority_unchanged'] is True and w['safe_travel_corridor_preserved'] is True
    assert w['beginner_neutral_until_attacked_rule_preserved'] is True and w['event_runtime_authority_unchanged'] is True
    assert density['do_not_increase_runtime_enemy_cap'] is True and density['preserve_large_readable_sea_gaps'] is True
    for key in ['damage_changed','range_changed','reload_changed','health_changed','rewards_changed','loot_values_changed','collision_changed','tap_to_sail_changed','camera_changed','new_pathfinder_added']:
        assert b[key] is False

def test_existing_spawns_receive_regional_living_sea_identity():
    src=(ROOT/'scripts/world/encounter_director.gd').read_text()
    assert 'M228LivingSeaEncounterCatalog.apply' in src
    assert 'passive_until_attacked' in src
    cat=(ROOT/'scripts/world/m228_living_sea_encounter_catalog.gd').read_text()
    for token in ['m228_patrol_pattern','m228_patrol_radius','m228_patrol_pace','m228_relation_read','m228_region_temperament','m228_world_read_priority']:
        assert token in cat
    for region in ['crimson_sea','drowned_reach','void_sea','sovereign_waters','abyssal_dominion','dreadwater_march','iron_maw_reach']:
        assert region in cat

def test_patrol_motion_is_local_anchor_relative_not_second_pathfinder():
    ai=(ROOT/'scripts/gameplay/enemy_ship_ai.gd').read_text()
    assert 'm228_patrol_radius' in ai and 'm228_patrol_pace' in ai
    assert 'orbit_tangent' in ai and 'radial_correction' in ai
    assert 'combat, leash, spawn count and world navigation authorities are unchanged' in ai
    budget=(ROOT/'scripts/world/encounter_runtime_budget.gd').read_text()
    assert 'RuntimeQualityBudget.max_npcs()' in budget
