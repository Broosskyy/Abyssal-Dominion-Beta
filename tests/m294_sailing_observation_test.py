import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def src(path):
    return (ROOT / path).read_text()


def test_m294_contract_reuses_existing_route_and_complete_ship_model():
    data = json.loads(src('data/m294_sailing_observation_contract.json'))
    assert data['milestone'] == 'M294' and data['master_concept'] == 'V3.8'
    assert data['clean_room_references'] == ['Seafight', 'Battle of Sea']
    assert data['states'] == ['IDLE', 'INTENT_ONLY', 'MOTION_OBSERVED', 'ARRIVAL_OBSERVED', 'INTERRUPTED']
    assert data['initial_ship_model'] == 'ONE_COMPLETE_GLB_PER_SHIP'
    assert data['native_status'] == 'NOT_EVALUATED' and not data['release_approved']
    input_source = src('scripts/gameplay/player_input.gd')
    assert 'if to_target.length() < 1.35:' in input_source
    assert 'navigation_intent_created.emit(navigation_target, "water")' in input_source


def test_m294_observer_does_not_promote_intent_or_local_position_to_server_truth():
    route = src('scripts/ui/m294_sailing_observation_runtime.gd')
    assert 'class_name M294SailingObservationRuntime' in route
    assert 'environment == "LOCAL_DEVELOPMENT"' in route
    assert 'server_authority_verified' in route
    assert 'if intent != "water":' in route
    assert 'if bool(player.get_meta("m225_docked", false)): return' in route
    assert 'input.has_navigation_target' in route and 'input.navigation_target.distance_to(target) > 0.01' in route
    assert 'player.current_speed > 0.0' in route
    assert 'state == "MOTION_OBSERVED" and distance <= ARRIVAL_DISTANCE' in route
    assert 'const ARRIVAL_DISTANCE := 1.35' in route
    assert '"server_verified":false' in route and '"arrival_is_server_truth":false' in route
    for forbidden in ['can_set_route_or_move_ship() -> bool: return false', 'can_confirm_server_movement_or_arrival() -> bool: return false', 'can_mark_native_qa_pass() -> bool: return false']:
        assert forbidden in route


def test_m294_integrates_route_view_without_upgrading_existing_tap_stage():
    runtime = src('scripts/ui/m290_first_sortie_integration_runtime.gd')
    assert 'sailing_observer = M294SailingObservationRuntime.new()' in runtime
    assert 'sailing_observer.configure(player)' in runtime
    assert '"sailing":sailing_view' in runtime
    assert '"milestone":"M301"' in runtime
    intent = runtime.split('func _on_navigation_intent(', 1)[1].split('\nfunc ', 1)[0]
    assert '_observe_local("TAP_TO_SAIL"' in intent
    assert 'NAVIGATION_INTENT_ONLY' in intent
    assert 'M290FirstSortieCatalog.m294_sailing(first_sortie)' in src('scripts/ui/command_deck.gd')
    release = json.loads(src('data/release_identity.json'))
    assert (release['milestone'], release['client_version'], release['version'], release['build_number'], release['content_config_version']) == ('M301', '0.301.0', '0.301.0', 301, 'M301')
