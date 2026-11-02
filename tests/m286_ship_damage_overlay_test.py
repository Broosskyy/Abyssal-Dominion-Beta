import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def load(path): return json.loads((ROOT / path).read_text())
def read(path): return (ROOT / path).read_text()


def test_m286_contract_is_clean_room_server_confirmed_and_untuned():
    contract = load("data/m286_ship_damage_overlay_contract.json")
    assert contract["milestone"] == "M286" and contract["master_concept"] == "V3.8"
    assert contract["genre_ux_references"] == ["Seafight", "Battle of Sea"]
    assert contract["segments"] == ["BOW", "PORT_HULL", "STARBOARD_HULL", "DECK", "MAST", "SAILS", "STERN"]
    assert contract["defeat_phases"] == ["NONE", "STAGGER", "FLOODING", "BREAKUP", "SUBMERGED", "CLEANUP_PENDING"]
    assert contract["ship_model_strategy"]["initial_production"] == "ONE_COMPLETE_3D_MODEL_PER_SHIP"
    assert contract["ship_model_strategy"]["modular_ship_system_required"] is False
    assert contract["ship_model_strategy"]["overlay_never_hides_detaches_or_replaces_model_parts"]
    assert contract["replication"]["defeat_events_require_m285_confirmation"]
    assert "modify ship transform from sinking visuals" in contract["authority"]["client_never"]
    assert "sinking_curve" in contract["unset_until_native_qa"]


def test_m286_runtime_has_replica_guards_and_no_client_authority():
    runtime = read("scripts/ui/m286_ship_damage_escalation_runtime.gd")
    assert "class_name M286ShipDamageEscalationRuntime" in runtime
    for token in ["escalation_revision", "transition_revision", "last_server_tick", "last_event_sequence", "seen_event_ids", "presentation_seed", "invalidate_from_world_resync"]: assert token in runtime
    for token in ["DECK_BREACH", "MAST_BREAK", "SAIL_TEAR", "FLOODING_START", "BREAKUP_START", "SUBMERGED", "WRECK_REVEAL", "VISUAL_CLEANUP_CONFIRMED"]: assert token in runtime
    assert "and not _has_confirmed_defeat(entity_id, defeat_sequence_id)" in runtime
    for token in ["can_client_derive_segment_damage() -> bool: return false", "can_client_break_mast_or_sails() -> bool: return false", "can_client_choose_sinking_profile() -> bool: return false", "can_client_advance_defeat_phase() -> bool: return false", "can_client_spawn_wreck_or_loot() -> bool: return false", "can_client_cleanup_world_entity() -> bool: return false"]: assert token in runtime


def test_m286_single_model_overlay_sockets_profiles_and_factory_attachment():
    rig = read("scripts/visual/m286_ship_damage_overlay_rig.gd")
    factory = read("scripts/core/procedural_factory.gd")
    manifest = load("data/m286_ship_destruction_placeholder_manifest.json")
    profiles = load("data/m286_ship_destruction_presentation_profiles.json")
    assert "class_name M286ShipDamageOverlayRig" in rig
    for visual in ["DeckBreachPlaceholder", "MastDamageOverlayPlaceholder", "SailDamageOverlayPlaceholder", "FloodingWaterlinePlaceholder", "SinkingBubblesPlaceholder", "WreckSilhouettePlaceholder"]: assert visual in rig
    for socket in manifest["required_sockets"]: assert socket in rig and socket in factory
    assert len(manifest["slots"]) == 8 and manifest["status"] == "PLACEHOLDER_REPLACEABLE"
    assert len(profiles["profiles"]) == 5 and profiles["rules"]["profile_does_not_change_damage"]
    assert "M286ShipDamageOverlayRigScript.new()" in factory
    for token in ["func can_change_ship_transform() -> bool: return false", "func can_require_modular_ship_mesh() -> bool: return false", "func can_hide_detach_or_replace_ship_parts() -> bool: return false", "func can_apply_segment_damage() -> bool: return false", "func can_break_equipment() -> bool: return false", "func can_confirm_sinking() -> bool: return false", "func can_spawn_loot_or_wreck_entity() -> bool: return false"]: assert token in rig


def test_m286_bootstrap_hud_command_deck_admin_matrix_and_release():
    bootstrap = read("scripts/core/game_bootstrap.gd")
    hud = read("scripts/ui/game_hud.gd")
    nautical = read("scripts/ui/nautical_hud.gd")
    deck = read("scripts/ui/command_deck.gd")
    assert "M286ShipDamageEscalationRuntime.new()" in bootstrap and "ShipDamageEscalationReadiness" in bootstrap
    assert "m286_ship_damage_escalation_state" in hud and "_m286_sync_ship_damage_escalation_state()" in hud
    assert "_draw_m286_ship_damage_escalation" in nautical
    assert "SHIP DAMAGE OVERLAYS · SEGMENTS · FLOODING · WRECK" in deck and "M286ShipDamageEscalationCatalog.placeholders" in deck
    admin = load("data/admin_content_type_registry.json")
    assert admin["milestone"] in {"M286", "M287","M288","M289","M291","M292","M293","M294","M295","M296","M297","M298","M299","M300","M301"}
    assert all(x in admin["content_types"] for x in ["ship_damage_segment_profile_definition", "ship_damage_overlay_profile_definition", "sinking_presentation_profile_definition", "wreck_visual_profile_definition"])
    matrix = load("data/m239_master_convergence_matrix.json")
    row = {x["domain"]: x for x in matrix["domains"]}["single_model_ship_damage_overlay_staged_sinking_wreck_presentation"]
    assert matrix["milestone"] in {"M286", "M287","M288","M289","M291","M292","M293","M294","M295","M296","M297","M298","M299","M300","M301"} and row["status"] == "PARTIAL" and "m286_fix" in row
    release = load("data/release_identity.json")
    assert release["milestone"] in {"M286", "M287","M288","M289","M291","M292","M293","M294","M295","M296","M297","M298","M299","M300","M301"} and release["client_version"] in {"0.286.0", "0.287.0","0.288.0","0.289.0","0.291.0","0.292.0","0.293.0","0.294.0","0.295.0","0.296.0","0.297.0","0.298.0","0.299.0","0.300.0","0.301.0"} and release["version"] in {"0.286.0", "0.287.0","0.288.0","0.289.0","0.291.0","0.292.0","0.293.0","0.294.0","0.295.0","0.296.0","0.297.0","0.298.0","0.299.0","0.300.0","0.301.0"} and release["build_number"] in {286, 287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and release["content_config_version"] in {"M286", "M287","M288","M289","M291","M292","M293","M294","M295","M296","M297","M298","M299","M300","M301"}
