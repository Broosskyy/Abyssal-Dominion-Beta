import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text()


def load(path):
    return json.loads(read(path))


def test_m300_guild_tower_preview_does_not_mint_combat_truth():
    contract = load('data/m300_guild_halloween_closure_contract.json')
    guild = read('scripts/guild/guild_island_composer.gd')
    depth = read('scripts/guild/m159_guild_island_depth.gd')
    visuals = read('scripts/guild/guild_island_visual_state.gd')
    assert contract['guild_island']['tower_roles'] == ['cannon', 'chain', 'mortar', 'ward', 'hunter']
    assert contract['guild_island']['live_tower_damage'] is False
    assert 'GuildIslandVisualState.apply(root)' in guild
    assert 'root.set_meta("relation","neutral_preview")' in guild
    assert 'socket.set_meta("live_damage",false)' in guild and 'n.set_meta("live_damage",false)' in depth
    assert '_add_hostile_preview(layer,node as Node3D' in visuals
    assert 'relation not in ["enemy","war"]' in visuals
    assert 'beacon.set_meta("hostility_preview_only",true)' in visuals
    assert 'beacon.set_meta("combat_authority",false)' in visuals


def test_m300_repeated_guild_visual_apply_and_admin_rebuild_keep_single_preview():
    visual = read('scripts/guild/guild_island_visual_state.gd')
    admin = read('scripts/admin/admin_mode_runtime.gd')
    assert 'root.remove_child(old)' in visual and 'node.remove_child(previous)' in visual
    assert 'tower.remove_child(old)' in visual
    assert 'set_range_preview(root,bool(root.get_meta("range_preview_visible",false)))' in visual
    assert 'w._build_sector()\n\t\t_apply_guild_preview_relation()' in admin
    assert 'w._build_sector();_apply_guild_preview_relation()' in admin
    assert 'island.set_meta("relation_authoritative",false)' in admin


def test_m300_halloween_scope_and_inactive_cleanup():
    script = read('scripts/events/halloween_event_world.gd')
    contract = load('data/m300_guild_halloween_closure_contract.json')
    assert contract['halloween']['sector_scoped_decoration']
    assert contract['halloween']['deactivation_clears_decoration']
    assert 'root.remove_child(old)' in script
    assert script.index('_clear_guild_layer(root)') < script.index('if runtime==null or not runtime.is_active()')
    assert 'island.remove_child(old)' in script
    assert 'root.is_ancestor_of(island)' in script
    assert 'island.is_queued_for_deletion()' in script
    assert '_apply_guild_layer(root)' in script


def test_m300_release_master_and_native_truth():
    release = load('data/release_identity.json')
    admin = load('data/admin_content_type_registry.json')
    matrix = load('data/m239_master_convergence_matrix.json')
    contract = load('data/m300_guild_halloween_closure_contract.json')
    assert (release['milestone'], release['client_version'], release['build_number']) == ('M301', '0.301.0', 301)
    assert admin['milestone'] == matrix['milestone'] == 'M301'
    assert 'M300' in release['visual_master_lock']
    assert matrix['domains'][-1]['status'] == 'PARTIAL' and 'm300_fix' in matrix['domains'][-1]
    assert contract['ship_rule'].startswith('one complete 3D model per ship')
    assert contract['native_qa'] == 'NOT_EVALUATED' and not contract['release_approved']
