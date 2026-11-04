import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def source(path):
    return (ROOT / path).read_text()


def test_m291_stages_and_release_identity_preserve_master_and_single_model_lock():
    contract = json.loads(source("data/m291_sortie_causality_contract.json"))
    assert contract["milestone"] == "M291" and contract["master_concept"] == "V3.8"
    assert contract["clean_room_references"] == ["Seafight", "Battle of Sea"]
    assert len(contract["core_stages"]) == 10
    assert contract["core_stages"][-1] == "HARBOR_RETURN"
    assert contract["optional_native_qa_stages"] == ["SHIP_DEFEAT", "RESPAWN"]
    assert contract["ship_model_strategy"] == "ONE_COMPLETE_GLB_PER_SHIP"
    assert contract["native_status"] == "NOT_EVALUATED" and not contract["release_approved"]
    release = json.loads(source("data/release_identity.json"))
    assert (release["milestone"], release["version"], release["build_number"]) == ("M301", "0.301.0", 301)


def test_m291_navigation_intent_cannot_fabricate_undocking_or_sailing_from_loot():
    runtime = source("scripts/ui/m290_first_sortie_integration_runtime.gd")
    intent = runtime.split("func _on_navigation_intent(", 1)[1].split("\nfunc ", 1)[0]
    assert 'intent == "water"' in intent and 'get_meta("m225_docked", false)' in intent
    assert '_observe_local("TAP_TO_SAIL"' in intent
    assert '_observe_local("UNDOCK"' not in intent
    port = source("scripts/world/port_interaction.gd")
    assert 'signal harbor_proximity_changed(nearby: bool, ship: ShipMotor, port_name: String)' in port
    assert 'harbor_proximity_changed.emit(false, body, port_name)' in port


def test_m291_harbor_return_and_observation_gate_are_causal_and_non_authoritative():
    runtime = source("scripts/ui/m290_first_sortie_integration_runtime.gd")
    assert 'if port_name != "Haven\'s Reach": return' in runtime
    assert 'observations.has("UNDOCK") and observations.has("TAP_TO_SAIL")' in runtime
    assert 'observations.has("RESPAWN")' not in runtime.split('func _on_docking_state_changed(', 1)[1].split('\nfunc ', 1)[0]
    assert 'if readiness == null or not readiness.observe_local_slice_event(stage_id, payload): return false' in runtime
    assert runtime.index('if readiness == null or not readiness.observe_local_slice_event') < runtime.index('observations[stage_id] = observation')
    assert 'if group_id == "enemies" and is_monster != monster_only: continue' in runtime
    assert '"status":"CORE_OBSERVED_NATIVE_QA_PENDING"' in runtime
    assert '"release_approved":false' in runtime
    assert 'M290FirstSortieCatalog.m291_causality()' in source('scripts/ui/command_deck.gd')
