import json, pathlib
root=pathlib.Path(__file__).resolve().parents[1]
rel=json.loads((root/'data/release_identity.json').read_text())
assert rel['build_number']>=170 and rel['master_concept']=='V3.8'
data=json.loads((root/'data/m170_mobile_runtime_interaction.json').read_text())
assert len(data['runtime_catalog_audit'])>=5 and len(data['mobile_screen_audit'])>=4 and len(data['interaction_guards'])>=4
hud=(root/'scripts/ui/game_hud.gd').read_text()
assert 'ids = CombatCatalog.ammo_ids()' in hud
assert 'combat_detail_id.is_empty()' in hud and 'event.is_action_pressed("ui_cancel")' in hud
nh=(root/'scripts/ui/nautical_hud.gd').read_text()
assert 'CombatCatalog.ammo_index_by_id(id) >= 0' in nh
icons=(root/'scripts/ui/combat_ui_icon_catalog.gd').read_text()
assert 'CombatCatalog.ammo_count()' in icons and 'CombatCatalog.ammo_id(index)' in icons
admin=(root/'scripts/admin/admin_mode_runtime.gd').read_text()
assert 'var kit_ids:Array[String] = CombatCatalog.ammo_ids()' in admin
inv=(root/'scripts/progression/player_inventory.gd').read_text()
assert 'func runtime_harpoon_profiles()' in inv and 'modern.harpoons()' in inv
hub=(root/'scripts/ui/m160_progression_hub.gd').read_text()
assert 'inv.runtime_harpoon_profiles()' in hub and 'AUSRÜSTUNG & AUSBAU' in hub
meta=(root/'scripts/ui/meta_systems_panel.gd').read_text()
assert 'ScrollContainer.new()' in meta and 'func _safe_rect()->Rect2:' in meta and 'ui_cancel' in meta
journal=(root/'scripts/ui/captain_journal.gd').read_text()
assert '52 * NauticalTheme.density_scale()' in journal
bootstrap=(root/'scripts/core/game_bootstrap.gd').read_text()
assert 'M170MobileRuntimeCatalog.new()' in bootstrap
reg=json.loads((root/'data/admin_content_type_registry.json').read_text())['content_types']
for k in ['overlay_priority_profile','runtime_catalog_binding','mobile_screen_audit','interaction_guard_profile']:
    assert k in reg
# Active runtime UI/admin paths must no longer depend on the legacy fixed ammo constant.
for path in [root/'scripts/ui/game_hud.gd',root/'scripts/ui/nautical_hud.gd',root/'scripts/ui/combat_ui_icon_catalog.gd',root/'scripts/admin/admin_mode_runtime.gd']:
    assert 'PlayerInventory.AMMO_IDS' not in path.read_text(), path
print('M170 MOBILE/RUNTIME/INTERACTION TEST PASS')
