import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
def load(path): return json.loads((ROOT / path).read_text())
def read(path): return (ROOT / path).read_text()


def test_m285_contract_clean_room_and_authority():
    contract = load("data/m285_ship_damage_defeat_presentation_contract.json")
    assert contract["milestone"] == "M285"
    assert contract["genre_ux_references"] == ["Seafight", "Battle of Sea"]
    assert contract["damage_states"] == ["INTACT", "LIGHT", "MODERATE", "HEAVY", "CRITICAL", "DEFEATED"]
    assert contract["replication"]["deterministic_presentation_seed"]
    assert contract["replication"]["cleanup_requires_confirmation"]
    assert "confirm_defeat_from_animation" in contract["authority"]["client_never"]
    assert "sinking_duration" in contract["unset_until_measured"]


def test_m285_runtime_guards_and_reconnect_safety():
    runtime = read("scripts/ui/m285_ship_damage_defeat_presentation_runtime.gd")
    assert "class_name M285ShipDamageDefeatPresentationRuntime" in runtime
    for token in ["SHIELD_HIT", "HULL_HIT", "ARMOR_HIT", "CRITICAL_ENTER", "DEFEAT_CONFIRMED", "SINK_START", "SINK_COMPLETE", "CLEANUP_CONFIRMED"]: assert token in runtime
    for token in ["state_revision", "presentation_revision", "last_server_tick", "last_event_sequence", "seen_event_ids", "presentation_seed", "invalidate_from_world_resync"]: assert token in runtime
    assert "and not _defeat_is_server_confirmed(entity_id, defeat_sequence_id)" in runtime
    for token in ["can_client_apply_damage_from_reaction() -> bool: return false", "can_client_derive_damage_state_from_health_bar() -> bool: return false", "can_client_confirm_defeat_from_animation() -> bool: return false", "can_client_despawn_from_sinking_vfx() -> bool: return false", "can_client_grant_reward_or_drop_from_defeat() -> bool: return false"]: assert token in runtime


def test_m285_placeholder_visual_rig_and_asset_replacement_contract():
    rig = read("scripts/visual/m285_ship_damage_visual_rig.gd")
    factory = read("scripts/core/procedural_factory.gd")
    manifest = load("data/m285_ship_damage_placeholder_asset_manifest.json")
    assert "class_name M285ShipDamageVisualRig" in rig
    for socket in ["VFX_Damage_01", "VFX_Damage_02", "VFX_Shield", "VFX_Sink"]: assert socket in rig and socket in factory and socket in manifest["required_sockets"]
    for visual in ["ShieldImpactPlaceholder", "HullDamagePlaceholder", "FirePlaceholder", "SmokePlaceholder", "CriticalStatePlaceholder", "SinkingDebrisPlaceholder"]: assert visual in rig
    assert "LOCAL_DEVELOPMENT" in rig and "server_authority_verified" in rig
    assert "M285ShipDamageVisualRigScript.new()" in factory
    assert len(manifest["slots"]) == 6 and manifest["status"] == "PLACEHOLDER_REPLACEABLE"
    for token in ["func can_apply_damage() -> bool: return false", "func can_confirm_defeat() -> bool: return false", "func can_despawn_ship() -> bool: return false", "func can_grant_reward_or_drop() -> bool: return false"]: assert token in rig


def test_m285_hud_bootstrap_command_deck_admin_and_release():
    bootstrap = read("scripts/core/game_bootstrap.gd")
    hud = read("scripts/ui/game_hud.gd")
    nautical = read("scripts/ui/nautical_hud.gd")
    deck = read("scripts/ui/command_deck.gd")
    assert "M285ShipDamageDefeatPresentationRuntime.new()" in bootstrap and "ShipDamageDefeatPresentationReadiness" in bootstrap
    assert "m285_ship_damage_defeat_state" in hud and "_m285_sync_ship_damage_defeat_state()" in hud
    assert "_draw_m285_ship_damage_defeat_presentation" in nautical
    assert "SHIP DAMAGE · HULL / SHIELD · SINKING / DEFEAT" in deck and "M285ShipDamageDefeatPresentationCatalog.placeholders" in deck
    admin = load("data/admin_content_type_registry.json")
    assert admin["milestone"] in {"M285", "M286","M287","M288","M289","M291","M292","M293","M294","M295","M296","M297","M298","M299","M300","M301"}
    assert all(x in admin["content_types"] for x in ["ship_damage_presentation_policy_definition", "ship_hit_reaction_profile_definition", "ship_damage_state_visual_profile_definition", "ship_sinking_defeat_profile_definition"])
    matrix = load("data/m239_master_convergence_matrix.json")
    row = {x["domain"]: x for x in matrix["domains"]}["ship_hit_reactions_hull_shield_damage_states_sinking_defeat_presentation"]
    assert matrix["milestone"] in {"M285", "M286","M287","M288","M289","M291","M292","M293","M294","M295","M296","M297","M298","M299","M300","M301"} and row["status"] == "PARTIAL" and "m285_fix" in row
    release = load("data/release_identity.json")
    assert release["milestone"] in {"M285", "M286", "M287","M288","M289","M291","M292","M293","M294","M295","M296","M297","M298","M299","M300","M301"} and release["client_version"] in {"0.285.0", "0.286.0", "0.287.0","0.288.0","0.289.0","0.291.0","0.292.0","0.293.0","0.294.0","0.295.0","0.296.0","0.297.0","0.298.0","0.299.0","0.300.0","0.301.0"} and release["version"] in {"0.285.0", "0.286.0", "0.287.0","0.288.0","0.289.0","0.291.0","0.292.0","0.293.0","0.294.0","0.295.0","0.296.0","0.297.0","0.298.0","0.299.0","0.300.0","0.301.0"} and release["build_number"] in {285, 286, 287,288,289,290,291,292,293,294,295,296,297,298,299,300,301} and release["content_config_version"] in {"M285", "M286", "M287","M288","M289","M291","M292","M293","M294","M295","M296","M297","M298","M299","M300","M301"}
