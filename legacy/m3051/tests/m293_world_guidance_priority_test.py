import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def src(path):
    return (ROOT / path).read_text()


def test_m293_port_proximity_is_player_ship_only():
    port = src('scripts/world/port_interaction.gd')
    block = port.split('func _on_body_entered(body: Node3D) -> void:\n', 1)[1].split('\nfunc ', 1)[0]
    lines = block.splitlines()
    assert lines[0] == '\tif not (body is ShipMotor and body.is_in_group("player")):'
    assert lines[1] == '\t\treturn'
    assert '\tbody.set_meta("nearby_port_name", port_name)' in block
    assert '\tharbor_proximity_changed.emit(true, body, port_name)' in block
    assert block.index('\t\treturn') < block.index('harbor_proximity_changed.emit(true')
    assert 'if body != nearby_player:\n\t\treturn' in port


def test_m293_home_beacon_selection_and_hostile_lifecycle_guard():
    runtime = src('scripts/ui/m290_first_sortie_integration_runtime.gd')
    assert 'world_map.current_stable_sector_id() == "SECTOR-001" and _home_port() != null' in runtime
    assert 'if kind == "HARBOR": return _home_port()' in runtime
    assert 'interaction.port_name == "Haven\'s Reach"' in runtime
    assert 'candidate.is_queued_for_deletion()' in runtime
    assert 'if enemy_health == null or enemy_health.is_sunk: continue' in runtime
    assert '"milestone":"M301"' in runtime


def test_m293_player_chosen_quest_target_and_single_model_take_priority():
    runtime = src('scripts/ui/m290_first_sortie_integration_runtime.gd')
    assert 'if tracking != null and not tracking.objective().is_empty(): return true' in runtime
    assert 'hud.menu_open or hud.global_map_open' in runtime
    assert 'kind in ["SHIP", "MONSTER"] and targeting != null and targeting.valid_hostile(targeting.target)' in runtime
    assert 'if health != null and health.is_sunk: return true' in runtime
    assert 'visual_rig.bind_target(null, "NONE")' in runtime
    contract = json.loads(src('data/m293_world_guidance_priority_contract.json'))
    assert contract['max_world_beacons'] == 1
    assert contract['ship_model_strategy'] == 'ONE_COMPLETE_GLB_PER_SHIP'
    assert not contract['changes_navigation_or_target_selection']
    assert not contract['changes_combat_damage_loot_or_quest_truth']
    assert contract['native_status'] == 'NOT_EVALUATED' and not contract['release_approved']
    release = json.loads(src('data/release_identity.json'))
    assert (release['milestone'], release['version'], release['build_number']) == ('M301', '0.301.0', 301)
    assert 'M290FirstSortieCatalog.m293_world_priority()' in src('scripts/ui/command_deck.gd')
